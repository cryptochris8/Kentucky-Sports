import { describe, it, expect } from 'vitest';
// Import from scoringLogic (pure, no Firebase imports) so tests run without an emulator
import {
  computePoints,
  isEntryCorrect,
  xpEventsForEntry,
  BASE_POINTS,
} from '../predictions/scoringLogic';
import type { PredictionEntry, Prediction } from '@bluegrass/shared-models';

describe('BASE_POINTS table', () => {
  it('has correct value for winner', () => {
    expect(BASE_POINTS.winner).toBe(10);
  });
  it('has correct value for margin_bucket', () => {
    expect(BASE_POINTS.margin_bucket).toBe(15);
  });
  it('has correct value for exact_score', () => {
    expect(BASE_POINTS.exact_score).toBe(50);
  });
  it('has correct value for upset_pick', () => {
    expect(BASE_POINTS.upset_pick).toBe(20);
  });
  it('has correct value for leading_scorer', () => {
    expect(BASE_POINTS.leading_scorer).toBe(15);
  });
  it('has correct value for stat_over_under', () => {
    expect(BASE_POINTS.stat_over_under).toBe(10);
  });
  it('has correct value for threes_range', () => {
    expect(BASE_POINTS.threes_range).toBe(15);
  });
});

describe('computePoints', () => {
  it('returns 0 for incorrect pick (winner)', () => {
    expect(computePoints('winner', false)).toBe(0);
  });
  it('returns 10 for correct winner pick', () => {
    expect(computePoints('winner', true)).toBe(10);
  });
  it('returns 15 for correct margin_bucket pick', () => {
    expect(computePoints('margin_bucket', true)).toBe(15);
  });
  it('returns 50 for correct exact_score pick', () => {
    expect(computePoints('exact_score', true)).toBe(50);
  });
  it('returns 20 for correct upset_pick', () => {
    expect(computePoints('upset_pick', true)).toBe(20);
  });
  it('returns 0 for incorrect exact_score', () => {
    expect(computePoints('exact_score', false)).toBe(0);
  });
  it('returns 15 for correct threes_range', () => {
    expect(computePoints('threes_range', true)).toBe(15);
  });
  it('returns 15 for correct leading_scorer', () => {
    expect(computePoints('leading_scorer', true)).toBe(15);
  });
  it('returns 10 for correct stat_over_under', () => {
    expect(computePoints('stat_over_under', true)).toBe(10);
  });
});

describe('isEntryCorrect', () => {
  const makePrediction = (
    correctOptionId: string | null | undefined,
  ): Pick<Prediction, 'correctOptionId' | 'type'> => ({
    correctOptionId,
    type: 'winner',
  });

  const makeEntry = (
    selectedOptionId: string,
  ): Pick<PredictionEntry, 'selectedOptionId' | 'numericValue'> => ({
    selectedOptionId,
    numericValue: null,
  });

  it('returns true when selectedOptionId matches correctOptionId', () => {
    expect(isEntryCorrect(makeEntry('kentucky'), makePrediction('kentucky'))).toBe(true);
  });

  it('returns false when selectedOptionId does not match', () => {
    expect(isEntryCorrect(makeEntry('opponent'), makePrediction('kentucky'))).toBe(false);
  });

  it('returns false when correctOptionId is null', () => {
    expect(isEntryCorrect(makeEntry('kentucky'), makePrediction(null))).toBe(false);
  });

  it('returns false when correctOptionId is undefined', () => {
    expect(isEntryCorrect(makeEntry('kentucky'), makePrediction(undefined))).toBe(false);
  });

  it('is case-sensitive', () => {
    expect(isEntryCorrect(makeEntry('Kentucky'), makePrediction('kentucky'))).toBe(false);
  });

  it('margin_bucket prediction correct when ids match', () => {
    expect(
      isEntryCorrect(makeEntry('8_14'), { correctOptionId: '8_14', type: 'margin_bucket' }),
    ).toBe(true);
  });

  it('margin_bucket prediction wrong when ids differ', () => {
    expect(
      isEntryCorrect(makeEntry('1_7'), { correctOptionId: '8_14', type: 'margin_bucket' }),
    ).toBe(false);
  });
});

describe('xpEventsForEntry', () => {
  it('incorrect picks earn no XP events', () => {
    expect(xpEventsForEntry('winner', false)).toEqual([]);
    expect(xpEventsForEntry('exact_score', false)).toEqual([]);
  });

  it('a correct pick earns correct_prediction', () => {
    expect(xpEventsForEntry('winner', true)).toEqual(['correct_prediction']);
    expect(xpEventsForEntry('margin_bucket', true)).toEqual(['correct_prediction']);
    expect(xpEventsForEntry('upset_pick', true)).toEqual(['correct_prediction']);
  });

  it('a correct exact-score pick additionally earns exact_score_bonus', () => {
    expect(xpEventsForEntry('exact_score', true)).toEqual([
      'correct_prediction',
      'exact_score_bonus',
    ]);
  });
});
