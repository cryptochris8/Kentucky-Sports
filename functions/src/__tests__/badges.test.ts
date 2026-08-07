import { describe, it, expect } from 'vitest';
// Import the REAL criteria matcher (pure, no Firebase imports) — a regression
// in badgeLogic.ts must fail this suite, not a private re-implementation.
import { checkBadgeCriteria, type BadgeContext } from '../rewards/badgeLogic';
import type { BadgeCriteria } from '@bluegrass/shared-models';

describe('badge criteria evaluation', () => {
  describe('first_pick (prediction_count threshold 1)', () => {
    const criteria: BadgeCriteria = { type: 'prediction_count', threshold: 1 };

    it('earned when predictionCount >= 1', () => {
      expect(checkBadgeCriteria(criteria, { predictionCount: 1 })).toBe(true);
      expect(checkBadgeCriteria(criteria, { predictionCount: 25 })).toBe(true);
    });

    it('not earned when predictionCount is 0', () => {
      expect(checkBadgeCriteria(criteria, { predictionCount: 0 })).toBe(false);
      expect(checkBadgeCriteria(criteria, {})).toBe(false);
    });
  });

  describe('three_game_streak (prediction_streak threshold 3)', () => {
    const criteria: BadgeCriteria = { type: 'prediction_streak', threshold: 3 };

    it('earned at streak 3+', () => {
      expect(checkBadgeCriteria(criteria, { predictionStreak: 3 })).toBe(true);
      expect(checkBadgeCriteria(criteria, { predictionStreak: 6 })).toBe(true);
    });

    it('not earned at streak 2', () => {
      expect(checkBadgeCriteria(criteria, { predictionStreak: 2 })).toBe(false);
    });
  });

  describe('upset_caller (upset_correct threshold 1)', () => {
    const criteria: BadgeCriteria = { type: 'upset_correct', threshold: 1 };

    it('earned when hasUpsetCorrect is true', () => {
      expect(checkBadgeCriteria(criteria, { hasUpsetCorrect: true })).toBe(true);
    });

    it('not earned when hasUpsetCorrect is false', () => {
      expect(checkBadgeCriteria(criteria, { hasUpsetCorrect: false })).toBe(false);
    });
  });

  describe('exact_score_miracle (exact_score threshold 1)', () => {
    const criteria: BadgeCriteria = { type: 'exact_score', threshold: 1 };

    it('earned when hasExactScore is true', () => {
      expect(checkBadgeCriteria(criteria, { hasExactScore: true })).toBe(true);
    });

    it('not earned by default', () => {
      expect(checkBadgeCriteria(criteria, {})).toBe(false);
    });
  });

  describe('matchup_master (view_matchup threshold 10)', () => {
    const criteria: BadgeCriteria = { type: 'view_matchup', threshold: 10 };

    it('earned at 10+ views', () => {
      expect(checkBadgeCriteria(criteria, { matchupViewCount: 10 })).toBe(true);
      expect(checkBadgeCriteria(criteria, { matchupViewCount: 50 })).toBe(true);
    });

    it('not earned at 9 views', () => {
      expect(checkBadgeCriteria(criteria, { matchupViewCount: 9 })).toBe(false);
    });
  });

  describe('kickoff_crew (gameday_open threshold 1)', () => {
    const criteria: BadgeCriteria = { type: 'gameday_open', threshold: 1 };

    it('earned at 1+ opens', () => {
      expect(checkBadgeCriteria(criteria, { gamedayOpenCount: 1 })).toBe(true);
    });

    it('not earned at 0', () => {
      expect(checkBadgeCriteria(criteria, { gamedayOpenCount: 0 })).toBe(false);
    });
  });

  describe('bluegrass_pipeline_scout (follow_high_school threshold 1)', () => {
    const criteria: BadgeCriteria = { type: 'follow_high_school', threshold: 1 };

    it('earned when followedHighSchool is true', () => {
      expect(checkBadgeCriteria(criteria, { followedHighSchool: true })).toBe(true);
    });

    it('not earned when false', () => {
      expect(checkBadgeCriteria(criteria, { followedHighSchool: false })).toBe(false);
    });
  });

  describe('unknown criteria type', () => {
    it('returns false for unknown type (bad Firestore data must not award)', () => {
      const criteria = { type: 'unknown_type_xyz', threshold: 1 } as unknown as BadgeCriteria;
      const context: BadgeContext = {};
      expect(checkBadgeCriteria(criteria, context)).toBe(false);
    });
  });
});
