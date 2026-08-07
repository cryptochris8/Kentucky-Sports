// Pure badge criteria logic — no I/O, no Firebase imports.
// Imported by badges.ts (Firestore writer) and by unit tests.

import type { BadgeCriteria } from '@bluegrass/shared-models';

/** Everything the badge engine may know about a user when evaluating criteria. */
export interface BadgeContext {
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
}

/** Pure function: does the context satisfy a badge's criteria? */
export function checkBadgeCriteria(criteria: BadgeCriteria, context: BadgeContext): boolean {
  switch (criteria.type) {
    case 'prediction_count':
      return (context.predictionCount ?? 0) >= criteria.threshold;
    case 'prediction_streak':
      return (context.predictionStreak ?? 0) >= criteria.threshold;
    case 'rivalry_correct':
      return (context.hasRivalryCorrect ?? false) && criteria.threshold <= 1;
    case 'upset_correct':
      return (context.hasUpsetCorrect ?? false) && criteria.threshold <= 1;
    case 'exact_score':
      return (context.hasExactScore ?? false) && criteria.threshold <= 1;
    case 'open_stats_lab':
      return (context.openedStatsLab ?? false) && criteria.threshold <= 1;
    case 'view_four_factors':
      return (context.viewedFourFactors ?? false) && criteria.threshold <= 1;
    case 'view_advanced_football':
      return (context.viewedAdvancedFootball ?? false) && criteria.threshold <= 1;
    case 'view_matchup':
      return (context.matchupViewCount ?? 0) >= criteria.threshold;
    case 'gameday_open':
      return (context.gamedayOpenCount ?? 0) >= criteria.threshold;
    case 'gameday_open_bball':
      return (context.gamedayOpenBballCount ?? 0) >= criteria.threshold;
    case 'follow_high_school':
      return (context.followedHighSchool ?? false) && criteria.threshold <= 1;
    case 'view_hs_scoreboard':
      return (context.viewedHsScoreboard ?? false) && criteria.threshold <= 1;
    default:
      return false;
  }
}
