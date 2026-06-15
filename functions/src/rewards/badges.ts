import { getDb, FieldValue } from '../core/admin';
import type { Badge, UserBadge } from '@bluegrass/shared-models';

/**
 * Evaluates which badges a user has earned and writes any new ones idempotently.
 * Called after scoring, XP events, or user actions.
 * Returns list of newly awarded badge IDs.
 */
export async function evaluateBadges(
  userId: string,
  context: {
    predictionCount?: number;
    predictionStreak?: number;
    correctPredictions?: number;
    hasExactScore?: boolean;
    hasRivalryCorrect?: boolean;
    hasUpsetCorrect?: boolean;
    openedStatsLab?: boolean;
    viewedFourFactors?: boolean;
    viewedAdvancedFootball?: boolean;
    matchupViewCount?: number;
    gamedayOpenCount?: number;
    gamedayOpenBballCount?: number;
    followedHighSchool?: boolean;
    viewedHsScoreboard?: boolean;
  },
): Promise<string[]> {
  const db = getDb();

  // Load all badge definitions
  const badgesSnap = await db.collection('badges').get();
  const allBadges = badgesSnap.docs.map((d) => ({ id: d.id, ...(d.data() as Badge) }));

  // Load already-earned badges for this user
  const userBadgesSnap = await db
    .collection('user_badges')
    .where('userId', '==', userId)
    .get();
  const earnedBadgeIds = new Set(userBadgesSnap.docs.map((d) => (d.data() as UserBadge).badgeId));

  const newlyEarned: string[] = [];
  const batch = db.batch();

  for (const badge of allBadges) {
    if (!badge.id || earnedBadgeIds.has(badge.id)) continue;

    const criteria = badge.criteria;
    let earned = false;

    switch (criteria.type) {
      case 'prediction_count':
        earned = (context.predictionCount ?? 0) >= criteria.threshold;
        break;
      case 'prediction_streak':
        earned = (context.predictionStreak ?? 0) >= criteria.threshold;
        break;
      case 'rivalry_correct':
        earned = (context.hasRivalryCorrect ?? false) && criteria.threshold <= 1;
        break;
      case 'upset_correct':
        earned = (context.hasUpsetCorrect ?? false) && criteria.threshold <= 1;
        break;
      case 'exact_score':
        earned = (context.hasExactScore ?? false) && criteria.threshold <= 1;
        break;
      case 'open_stats_lab':
        earned = (context.openedStatsLab ?? false) && criteria.threshold <= 1;
        break;
      case 'view_four_factors':
        earned = (context.viewedFourFactors ?? false) && criteria.threshold <= 1;
        break;
      case 'view_advanced_football':
        earned = (context.viewedAdvancedFootball ?? false) && criteria.threshold <= 1;
        break;
      case 'view_matchup':
        earned = (context.matchupViewCount ?? 0) >= criteria.threshold;
        break;
      case 'gameday_open':
        earned = (context.gamedayOpenCount ?? 0) >= criteria.threshold;
        break;
      case 'gameday_open_bball':
        earned = (context.gamedayOpenBballCount ?? 0) >= criteria.threshold;
        break;
      case 'follow_high_school':
        earned = (context.followedHighSchool ?? false) && criteria.threshold <= 1;
        break;
      case 'view_hs_scoreboard':
        earned = (context.viewedHsScoreboard ?? false) && criteria.threshold <= 1;
        break;
      default:
        break;
    }

    if (earned) {
      const userBadgeRef = db.collection('user_badges').doc();
      const userBadge: Omit<UserBadge, 'id'> = {
        userId,
        badgeId: badge.id,
        earnedAt: new Date().toISOString(),
        metadata: {},
      };
      batch.set(userBadgeRef, {
        ...userBadge,
        earnedAt: FieldValue.serverTimestamp(),
      });
      newlyEarned.push(badge.id);
    }
  }

  if (newlyEarned.length > 0) {
    await batch.commit();
  }

  return newlyEarned;
}
