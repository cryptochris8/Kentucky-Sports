import { onCall } from 'firebase-functions/v2/https';
import { assertRole } from '../core/auth';
import { requireString } from '../core/validate';
import { throwError } from '../core/errors';
import { getDb } from '../core/admin';
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
  const predSnap = await predRef.get();

  if (!predSnap.exists) {
    throwError('not-found', 'Prediction not found.');
  }

  // Write the correctOptionId — scoring engine reads this
  await predRef.update({ correctOptionId, status: 'closed' });

  const processed = await scorePredictionEntries(predictionId);

  return { message: `Scored ${processed} entries.`, processed };
});
