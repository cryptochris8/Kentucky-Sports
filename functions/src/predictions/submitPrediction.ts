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

  // Idempotency: query catches legacy auto-ID entries; the deterministic
  // doc ID + create() below closes the race two concurrent submits would
  // otherwise win together (both seeing an empty query result).
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

  // One entry per (prediction, user) enforced at the datastore level.
  const entryRef = entriesRef.doc(`${predictionId}_${uid}`);
  try {
    await entryRef.create({
      ...entry,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (err) {
    // gRPC code 6 = ALREADY_EXISTS (a concurrent submit won the race)
    if ((err as { code?: number }).code === 6) {
      throwError('already-exists', 'You have already submitted a pick for this prediction.');
    }
    throw err;
  }

  return { entryId: entryRef.id, message: 'Pick submitted successfully.' };
});
