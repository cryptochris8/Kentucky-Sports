import { onCall } from 'firebase-functions/v2/https';
import { assertRole } from '../core/auth';
import { requireString, requireEnum } from '../core/validate';
import { throwError } from '../core/errors';
import { getDb } from '../core/admin';
import type { Prediction } from '@bluegrass/shared-models';
import { scorePredictionEntries } from './scoring';

interface AdminScorePredictionPayload {
  predictionId: string;
  correctOptionId: string;
}

export const adminScorePrediction = onCall<AdminScorePredictionPayload>(async (request) => {
  assertRole(request, ['editor', 'admin']);

  const predictionId = requireString(request.data?.predictionId, 'predictionId');
  const correctOptionId = requireString(request.data?.correctOptionId, 'correctOptionId');

  const db = getDb();
  const predRef = db.collection('predictions').doc(predictionId);

  // Guard + answer write happen in ONE transaction: two concurrent admin calls
  // could otherwise both pass the status read and grade entries against two
  // different correct answers — and entries lock as they score, so the mixed
  // grading would be permanent.
  await db.runTransaction(async (tx) => {
    const predSnap = await tx.get(predRef);

    if (!predSnap.exists) {
      throwError('not-found', 'Prediction not found.');
    }

    const prediction = predSnap.data() as Prediction;

    // Scoring is one-way: entries lock as they score, so a typo'd re-run could
    // never fix them. Refuse to touch an already-scored prediction.
    if (prediction.status === 'scored') {
      throwError('failed-precondition', 'This prediction has already been scored.');
    }

    // The correct option must be one of the prediction's actual options —
    // a typo here would mark every entrant wrong, irreversibly.
    const optionIds = (prediction.options ?? []).map((o) => o.id);
    requireEnum(correctOptionId, 'correctOptionId', optionIds);

    // Write the correctOptionId — scoring engine reads this. Scoring flips the
    // status to 'scored' only after it succeeds.
    tx.update(predRef, { correctOptionId, status: 'closed' });
  });

  const processed = await scorePredictionEntries(predictionId);

  return { message: `Scored ${processed} entries.`, processed };
});
