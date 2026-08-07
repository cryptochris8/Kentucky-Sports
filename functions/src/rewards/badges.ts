// Badge engine — Firestore writer layer.
// Pure criteria matching lives in badgeLogic.ts so unit tests can import it
// without Firebase.

import { getDb, FieldValue } from '../core/admin';
import type { Badge, UserBadge } from '@bluegrass/shared-models';
import { checkBadgeCriteria, type BadgeContext } from './badgeLogic';

export { checkBadgeCriteria, type BadgeContext } from './badgeLogic';

/** gRPC status code for "document already exists" (concurrent award race). */
const ALREADY_EXISTS = 6;

/**
 * Evaluates which badges a user has earned and writes any new ones idempotently.
 * Called after scoring, XP events, or user actions.
 *
 * Awarded docs live at users/{uid}/user_badges/{badgeId} (the subcollection the
 * security rules cover), keyed on the badge ID so re-evaluation can never award
 * the same badge twice — create() is a no-op when the doc already exists.
 *
 * Returns list of newly awarded badge IDs.
 */
export async function evaluateBadges(userId: string, context: BadgeContext): Promise<string[]> {
  const db = getDb();

  // Load all badge definitions
  const badgesSnap = await db.collection('badges').get();
  const allBadges = badgesSnap.docs.map((d) => ({ ...(d.data() as Badge), id: d.id }));

  // Load already-earned badges for this user (doc ID == badge ID)
  const userBadgesCol = db.collection('users').doc(userId).collection('user_badges');
  const userBadgesSnap = await userBadgesCol.get();
  const earnedBadgeIds = new Set(userBadgesSnap.docs.map((d) => d.id));

  const newlyEarned: string[] = [];

  for (const badge of allBadges) {
    if (!badge.id || earnedBadgeIds.has(badge.id)) continue;
    if (!checkBadgeCriteria(badge.criteria, context)) continue;

    const userBadge: Omit<UserBadge, 'id' | 'earnedAt'> = {
      userId,
      badgeId: badge.id,
      metadata: {},
    };

    try {
      // create() (not set) so a concurrent evaluation cannot double-award.
      await userBadgesCol.doc(badge.id).create({
        ...userBadge,
        earnedAt: FieldValue.serverTimestamp(),
      });
      newlyEarned.push(badge.id);
    } catch (err) {
      if ((err as { code?: number }).code === ALREADY_EXISTS) continue;
      throw err;
    }
  }

  return newlyEarned;
}
