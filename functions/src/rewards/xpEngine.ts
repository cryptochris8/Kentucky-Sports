// XP engine — Firestore writer layer.
// Pure logic (XP_TABLE, DAILY_CAPS, xpForLevel, levelForXp, computeXpAward)
// lives in xpLogic.ts so unit tests can import it without Firebase.

import { getDb, FieldValue } from '../core/admin';
import type { User, XpEvent } from '@bluegrass/shared-models';
import { computeXpAward, dailyCapKey, levelForXp } from './xpLogic';

// Re-export so callers of this module still find everything here.
export { XP_TABLE, DAILY_CAPS, xpForLevel, levelForXp, computeXpAward, dailyCapKey } from './xpLogic';

export interface AwardXpResult {
  xpAwarded: number;
  newXp: number;
  newLevel: number;
  leveledUp: boolean;
  cappedByDailyLimit: boolean;
}

/**
 * Awards XP to a user for an event.
 * Enforces daily caps by reading a sub-document with today's usage
 * (keyed in America/New_York — see dailyCapKey).
 * Returns the amount awarded (may be 0 if capped).
 */
export async function awardXp(userId: string, event: XpEvent): Promise<AwardXpResult> {
  const db = getDb();
  const userRef = db.collection('users').doc(userId);
  const capRef = userRef.collection('xp_daily_caps').doc(dailyCapKey());

  return db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const capSnap = await tx.get(capRef);

    const user = (userSnap.data() ?? {}) as Partial<User>;
    const usedToday = (capSnap.data() ?? {}) as Partial<Record<XpEvent, number>>;
    const currentXp = user.xp ?? 0;
    const currentLevel = user.level ?? 1;

    const award = computeXpAward([event], usedToday);

    if (award.xpAwarded === 0 || !userSnap.exists) {
      return {
        xpAwarded: 0,
        newXp: currentXp,
        newLevel: currentLevel,
        leveledUp: false,
        cappedByDailyLimit: award.cappedByDailyLimit,
      };
    }

    const newXp = currentXp + award.xpAwarded;
    const newLevel = levelForXp(newXp);

    tx.update(userRef, {
      xp: newXp,
      level: newLevel,
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

    return {
      xpAwarded: award.xpAwarded,
      newXp,
      newLevel,
      leveledUp: newLevel > currentLevel,
      cappedByDailyLimit: award.cappedByDailyLimit,
    };
  });
}
