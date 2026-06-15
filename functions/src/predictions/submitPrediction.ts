import { onCall } from 'firebase-functions/v2/https';
import { getDb, FieldValue } from '../core/admin';
import { assertAuth } from '../core/auth';
import { throwError } from '../core/errors';
import { requireString } from '../core/validate';
import type { Prediction, PredictionEntry } from '@bluegrass/shared-models';

interface SubmitPredictionPayload {
  predictionId: string;
  selectedOptionId: string;
  numericValue?: number | null;
}

export const submitPrediction = onCall<SubmitPredictionPayload>(async (request) => {
  const uid = assertAuth(request);
  const { data } = request;

  const predictionId = requireString(data?.predictionId, 'predictionId');
  const selectedOptionId = requireString(data?.selectedOptionId, 'selectedOptionId');
  const numericValue = data?.numericValue ?? null;

  const db = getDb();
  const predRef = db.collection('predictions').doc(predictionId);
  const predSnap = await predRef.get();

  if (!predSnap.exists) {
    throwError('not-found', 'Prediction not found.');
  }

  const prediction = predSnap.data() as Prediction;

  if (prediction.status !== 'open') {
    throwError('failed-precondition', 'This prediction is no longer open.');
  }

  const now = new Date();
  // Firestore Timestamp objects have a toMillis() method; string ISO dates also work
  const closesAtRaw = prediction.closesAt as unknown;
  let closesAt: Date;
  if (
    typeof closesAtRaw === 'object' &&
    closesAtRaw !== null &&
    typeof (closesAtRaw as Record<string, unknown>)['toMillis'] === 'function'
  ) {
    closesAt = new Date((closesAtRaw as { toMillis: () => number }).toMillis());
  } else if (
    typeof closesAtRaw === 'object' &&
    closesAtRaw !== null &&
    'seconds' in closesAtRaw
  ) {
    closesAt = new Date((closesAtRaw as { seconds: number }).seconds * 1000);
  } else {
    closesAt = new Date(closesAtRaw as string);
  }

  if (now >= closesAt) {
    throwError('failed-precondition', 'This prediction has closed.');
  }

  // Validate selectedOptionId is a valid option
  const validOption = prediction.options.find((o) => o.id === selectedOptionId);
  if (!validOption) {
    throwError('invalid-argument', 'selectedOptionId is not a valid option for this prediction.');
  }

  // Idempotency: check for existing entry
  const entriesRef = db.collection('prediction_entries');
  const existingQuery = await entriesRef
    .where('predictionId', '==', predictionId)
    .where('userId', '==', uid)
    .limit(1)
    .get();

  if (!existingQuery.empty) {
    throwError('already-exists', 'You have already submitted a pick for this prediction.');
  }

  const entry: Omit<PredictionEntry, 'id'> = {
    predictionId,
    gameId: prediction.gameId,
    userId: uid,
    selectedOptionId,
    numericValue: numericValue ?? null,
    locked: false,
    isCorrect: null,
    pointsAwarded: 0,
    createdAt: new Date().toISOString(),
  };

  const entryRef = entriesRef.doc();
  await entryRef.set({
    ...entry,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { entryId: entryRef.id, message: 'Pick submitted successfully.' };
});
