// Prediction scoring engine — Firestore writer layer.
// Pure logic lives in scoringLogic.ts so unit tests can import it without Firebase.

import { getDb, FieldValue, Timestamp } from '../core/admin';
import type {
  Prediction,
  PredictionEntry,
  PredictionRecord,
  User,
  XpEvent,
} from '@bluegrass/shared-models';
import { computePoints, isEntryCorrect, xpEventsForEntry } from './scoringLogic';
import { computeXpAward, dailyCapKey, levelForXp } from '../rewards/xpLogic';
import { evaluateBadges } from '../rewards/badges';

// Re-export pure functions + table so callers of this module still find them here.
export { BASE_POINTS, computePoints, isEntryCorrect, xpEventsForEntry } from './scoringLogic';

/** Result of scoring one entry inside its transaction. */
interface EntryOutcome {
  userId: string;
  correct: boolean;
  /** The user's prediction record AFTER this entry, or null if the user doc is gone. */
  record: PredictionRecord | null;
  /** True when the entry was scored on an earlier run — no writes were made. */
  alreadyScored: boolean;
}

/**
 * Scores all entries for a prediction that has a correctOptionId set.
 *
 * Each entry is scored in its own transaction covering the entry doc, the user
 * doc, and the user's daily-cap doc, so re-fired triggers (Cloud Functions are
 * at-least-once) or a concurrent adminScorePrediction call cannot double-award:
 * the transaction re-reads isCorrect and, when the entry is already scored,
 * makes NO writes — it only returns the stored outcome so badge evaluation
 * still re-runs (evaluateBadges is create()-idempotent).
 *
 * XP comes exclusively from XP_TABLE via computeXpAward (correct_prediction,
 * plus exact_score_bonus for correct exact-score picks) and the level is
 * recomputed with the unified levelForXp curve. A missing user doc (deleted
 * account) still scores the entry — it just skips the user write, so one
 * deleted account cannot block scoring for everyone else.
 *
 * Badge failures must not vanish: they are collected per entry and rethrown
 * AFTER every entry has been attempted, and the prediction is marked 'scored'
 * only when the run had no errors — so the caller's retry (onGameUpdated has
 * retry: true) re-runs this function and only the missing badges land.
 *
 * Returns the number of entries newly scored on this run.
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

  // Fetch ALL entries for the prediction — not just unscored ones — so a retry
  // after a badge failure still reaches entries whose scoring already committed;
  // each transaction re-checks isCorrect before writing.
  const entriesSnap = await db
    .collection('prediction_entries')
    .where('predictionId', '==', predictionId)
    .get();

  const scoredAt = Timestamp.now();
  let processed = 0;
  const badgeFailures: string[] = [];

  for (const entryDoc of entriesSnap.docs) {
    const outcome = await db.runTransaction<EntryOutcome | null>(async (tx) => {
      const entrySnap = await tx.get(entryDoc.ref);
      if (!entrySnap.exists) return null;

      const entry = entrySnap.data() as PredictionEntry;
      if (entry.isCorrect !== null) {
        // Already scored (e.g. a retry after a badge failure) — award nothing,
        // but surface the stored outcome so evaluateBadges re-runs below.
        const userSnap = await tx.get(db.collection('users').doc(entry.userId));
        return {
          userId: entry.userId,
          correct: entry.isCorrect,
          record: userSnap.exists
            ? ((userSnap.data() as User).predictionRecord ?? null)
            : null,
          alreadyScored: true,
        };
      }

      const correct = isEntryCorrect(entry, prediction);
      const points = computePoints(prediction.type, correct);
      const events: XpEvent[] = xpEventsForEntry(prediction.type, correct);

      const userRef = db.collection('users').doc(entry.userId);
      const userSnap = await tx.get(userRef);

      let record: PredictionRecord | null = null;
      if (userSnap.exists) {
        const capRef = userRef.collection('xp_daily_caps').doc(dailyCapKey());
        const capSnap = events.length > 0 ? await tx.get(capRef) : null;
        const usedToday = (capSnap?.data() ?? {}) as Partial<Record<XpEvent, number>>;
        const award = computeXpAward(events, usedToday);

        const user = userSnap.data() as User;
        const prev = user.predictionRecord ?? { total: 0, correct: 0, streak: 0 };
        record = {
          total: prev.total + 1,
          correct: prev.correct + (correct ? 1 : 0),
          streak: correct ? prev.streak + 1 : 0,
        };

        const newXp = (user.xp ?? 0) + award.xpAwarded;
        tx.update(userRef, {
          xp: newXp,
          level: levelForXp(newXp),
          predictionRecord: record,
          updatedAt: FieldValue.serverTimestamp(),
        });

        if (Object.keys(award.capUsage).length > 0) {
          const capIncrements: Record<string, unknown> = {
            updatedAt: FieldValue.serverTimestamp(),
          };
          for (const [capEvent, amount] of Object.entries(award.capUsage)) {
            capIncrements[capEvent] = FieldValue.increment(amount);
          }
          tx.set(capRef, capIncrements, { merge: true });
        }
      } else {
        console.warn(
          `[scorePredictionEntries] User ${entry.userId} not found — scoring entry ${entryDoc.id} without a user update.`,
        );
      }

      tx.update(entryDoc.ref, {
        isCorrect: correct,
        pointsAwarded: points,
        locked: true,
        scoredAt,
      });

      return { userId: entry.userId, correct, record, alreadyScored: false };
    });

    if (!outcome) continue;
    if (!outcome.alreadyScored) processed++;

    // Badge evaluation runs after the transaction and is idempotent
    // (create-if-absent); a badge failure must not block scoring others, but
    // it must not vanish either — collect it and rethrow after the loop.
    if (outcome.record) {
      try {
        await evaluateBadges(outcome.userId, {
          predictionCount: outcome.record.total,
          correctPredictions: outcome.record.correct,
          predictionStreak: outcome.record.streak,
          hasExactScore: outcome.correct && prediction.type === 'exact_score',
          hasUpsetCorrect: outcome.correct && prediction.type === 'upset_pick',
        });
      } catch (err) {
        console.error(`[scorePredictionEntries] Badge evaluation failed for ${outcome.userId}:`, err);
        badgeFailures.push(outcome.userId);
      }
    }
  }

  // Rethrow badge failures now that every entry has been attempted: the status
  // stays un-scored, so the caller's retry re-runs this function — scored
  // entries are idempotent-safe and evaluateBadges is create()-idempotent.
  if (badgeFailures.length > 0) {
    throw new Error(
      `Badge evaluation failed for user(s) ${badgeFailures.join(', ')} on prediction ${predictionId} — leaving status un-scored for retry.`,
    );
  }

  // Mark prediction as scored only when the run had no errors (idempotent — safe on re-runs).
  await predRef.update({ status: 'scored' });
  return processed;
}
