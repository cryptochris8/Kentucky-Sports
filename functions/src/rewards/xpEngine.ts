// XP engine — Firestore writer layer.
// Pure logic (XP_TABLE, DAILY_CAPS, LEVEL_THRESHOLDS, levelForXp) lives in xpLogic.ts
// so unit tests can import it without Firebase.

import { getDb, FieldValue } from '../core/admin';
import type { User } from '@bluegrass/shared-models';
import { XP_TABLE, DAILY_CAPS, levelForXp } from './xpLogic';

// Re-export so callers of this module still find everything here.
export { XP_TABLE, DAILY_CAPS, LEVEL_THRESHOLDS, levelForXp } from './xpLogic';

export interface AwardXpResult {
  xpAwarded: number;
  newXp: number;
  newLevel: number;
  leveledUp: boolean;
  cappedByDailyLimit: boolean;
}

import type { XpEvent } from '@bluegrass/shared-models';

/**
 * Awards XP to a user for an event.
 * Enforces daily caps by reading a sub-document with today's usage.
 * Returns the amount awarded (may be 0 if capped).
 */
export async function awardXp(userId: string, event: XpEvent): Promise<AwardXpResult> {
  const db = getDb();
  const userRef = db.collection('users').doc(userId);
  const xpAmount = XP_TABLE[event] ?? 0;

  if (xpAmount === 0) {
    const snap = await userRef.get();
    const user = snap.data() as User;
    return {
      xpAwarded: 0,
      newXp: user.xp,
      newLevel: user.level,
      leveledUp: false,
      cappedByDailyLimit: false,
    };
  }

  const todayKey = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
  const capRef = db
    .collection('users')
    .doc(userId)
    .collection('xp_daily_caps')
    .doc(todayKey);

  const cap = DAILY_CAPS[event];

  return db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const capSnap = await tx.get(capRef);

    const user = userSnap.data() as User;
    const capData = capSnap.data() ?? {};
    const usedToday: number = (capData[event] as number | undefined) ?? 0;

    let actualXp = xpAmount;
    let capped = false;

    if (cap !== undefined && usedToday + xpAmount > cap) {
      actualXp = Math.max(0, cap - usedToday);
      capped = true;
    }

    if (actualXp > 0) {
      const newXp = (user.xp ?? 0) + actualXp;
      const oldLevel = user.level ?? 1;
      const newLevel = levelForXp(newXp);

      tx.update(userRef, {
        xp: FieldValue.increment(actualXp),
        level: newLevel,
        updatedAt: FieldValue.serverTimestamp(),
      });

      tx.set(
        capRef,
        { [event]: FieldValue.increment(actualXp), updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );

      return {
        xpAwarded: actualXp,
        newXp,
        newLevel,
        leveledUp: newLevel > oldLevel,
        cappedByDailyLimit: capped,
      };
    }

    return {
      xpAwarded: 0,
      newXp: user.xp,
      newLevel: user.level,
      leveledUp: false,
      cappedByDailyLimit: true,
    };
  });
}
