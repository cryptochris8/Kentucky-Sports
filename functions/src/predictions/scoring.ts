// Prediction scoring engine — Firestore writer layer.
// Pure logic lives in scoringLogic.ts so unit tests can import it without Firebase.

import { getDb, FieldValue, Timestamp } from '../core/admin';
import type { Prediction, PredictionEntry } from '@bluegrass/shared-models';
import { computePoints, isEntryCorrect } from './scoringLogic';

// Re-export pure functions + table so callers of this module still find them here.
export { BASE_POINTS, computePoints, isEntryCorrect } from './scoringLogic';

/**
 * Scores all entries for a prediction that has a correctOptionId set.
 * Idempotent: only scores entries where isCorrect is null (not yet scored).
 * Returns the number of entries processed.
 */
export async function scorePredictionEntries(predictionId: string): Promise<number> {
  const db = getDb();
  const predRef = db.collection('predictions').doc(predictionId);
  const predSnap = await predRef.get();

  if (!predSnap.exists) {
    throw new Error(`Prediction ${predictionId} not found`);
  }

  const prediction = predSnap.data() as Prediction;

  if (!prediction.correctOptionId) {
    throw new Error(`Prediction ${predictionId} has no correctOptionId set`);
  }

  // Fetch unscored entries only (idempotency: skip already-scored)
  const entriesSnap = await db
    .collection('prediction_entries')
    .where('predictionId', '==', predictionId)
    .where('isCorrect', '==', null)
    .get();

  if (entriesSnap.empty) return 0;

  const batch = db.batch();
  const scoredAt = Timestamp.now();

  let processed = 0;
  for (const doc of entriesSnap.docs) {
    const entry = doc.data() as PredictionEntry;
    const correct = isEntryCorrect(entry, prediction);
    const points = computePoints(prediction.type, correct);

    batch.update(doc.ref, {
      isCorrect: correct,
      pointsAwarded: points,
      locked: true,
      scoredAt,
    });

    // Update user's XP and prediction record in the same batch (best-effort merge)
    const userRef = db.collection('users').doc(entry.userId);
    batch.update(userRef, {
      xp: FieldValue.increment(correct ? 20 : 0),
      'predictionRecord.total': FieldValue.increment(1),
      'predictionRecord.correct': FieldValue.increment(correct ? 1 : 0),
      'predictionRecord.streak': correct ? FieldValue.increment(1) : 0,
      updatedAt: FieldValue.serverTimestamp(),
    });

    processed++;
  }

  // Mark prediction as scored
  batch.update(predRef, { status: 'scored' });

  await batch.commit();
  return processed;
}
