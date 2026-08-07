import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getDb } from '../core/admin';
import { scorePredictionEntries } from './scoring';
import type { Game } from '@bluegrass/shared-models';

/**
 * Firestore trigger: when a game document is updated,
 * check if it just went to 'final' status and auto-score open predictions.
 *
 * retry: true is set explicitly — v2 Firestore triggers default to NO retry,
 * so without it the rethrow below would only produce an error log and leave
 * picks permanently unscored. Scoring is idempotent, so retries are safe.
 */
export const onGameUpdated = onDocumentUpdated(
  { document: 'games/{gameId}', retry: true },
  async (event) => {
    const before = event.data?.before.data() as Game | undefined;
    const after = event.data?.after.data() as Game | undefined;

    if (!after) return;

    // Only trigger when status transitions to 'final'
    if (before?.status === after.status || after.status !== 'final') {
      return;
    }

    const gameId = event.params.gameId;
    console.log(`Game ${gameId} went final — checking for predictions to score.`);

    const db = getDb();

    // Find predictions for this game that have a correctOptionId set but status = 'closed'
    const predsSnap = await db
      .collection('predictions')
      .where('gameId', '==', gameId)
      .where('status', '==', 'closed')
      .get();

    if (predsSnap.empty) {
      console.log(`No closed predictions found for game ${gameId}.`);
      return;
    }

    // Attempt every prediction, then rethrow so the trigger re-fires (retry is
    // explicitly enabled above) — scorePredictionEntries is idempotent, so
    // retries are safe and a swallowed error would leave picks silently unscored.
    const failures: string[] = [];
    for (const predDoc of predsSnap.docs) {
      const pred = predDoc.data();
      if (pred.correctOptionId) {
        try {
          const count = await scorePredictionEntries(predDoc.id);
          console.log(`Scored ${count} entries for prediction ${predDoc.id}.`);
        } catch (err) {
          console.error(`Error scoring prediction ${predDoc.id}:`, err);
          failures.push(predDoc.id);
        }
      }
    }

    if (failures.length > 0) {
      throw new Error(
        `Failed to score prediction(s) ${failures.join(', ')} for game ${gameId} — retrying.`,
      );
    }
  },
);
