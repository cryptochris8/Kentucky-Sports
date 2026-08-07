import { describe, it, expect } from 'vitest';
import { effectiveFgPct, computeFourFactors, turnoverRate, offReboundRate } from '../basketball';
import { yardsPerPlay, driveFinisherScore, chaosFactorScore } from '../football';
import { percentileRank, percentileLabel, buildPercentileResult } from '../percentile';
import { footballStatLabels, basketballStatLabels } from '../labels';
import { explainMetric } from '../explainMetric';

describe('basketball four factors', () => {
  it('computes effectiveFgPct correctly', () => {
    // (10 + 0.5*3) / 20 = 11.5/20 = 0.575
    expect(effectiveFgPct(10, 3, 20)).toBeCloseTo(0.575);
  });

  it('handles zero FGA in effectiveFgPct', () => {
    expect(effectiveFgPct(0, 0, 0)).toBe(0);
  });

  it('computes turnoverRate correctly', () => {
    // 10 / (20 + 0.44*8 + 10) * 100 = 10/33.52 * 100 ≈ 29.83
    expect(turnoverRate(10, 20, 8)).toBeCloseTo(29.83, 1);
  });

  it('computes offReboundRate correctly', () => {
    // 12 / (12 + 18) = 12/30 = 0.4
    expect(offReboundRate(12, 18)).toBeCloseTo(0.4);
  });

  it('computeFourFactors returns all four factors', () => {
    const result = computeFourFactors({
      fgm: 30, threePm: 8, fga: 65,
      to: 12, fta: 20,
      oreb: 10, opponentDreb: 25,
    });
    expect(result.effectiveFgPct).toBeCloseTo((30 + 0.5 * 8) / 65);
    expect(result.offReboundRate).toBeCloseTo(10 / 35);
    expect(typeof result.turnoverRate).toBe('number');
    expect(typeof result.freeThrowRate).toBe('number');
  });
});

describe('football helpers', () => {
  it('computes yardsPerPlay correctly', () => {
    expect(yardsPerPlay(500, 70)).toBeCloseTo(7.14, 1);
  });

  it('handles zero plays in yardsPerPlay', () => {
    expect(yardsPerPlay(500, 0)).toBe(0);
  });

  it('computes driveFinisherScore in 0-100 range', () => {
    const score = driveFinisherScore(0.86, 29.4);
    expect(score).toBeGreaterThanOrEqual(0);
    expect(score).toBeLessThanOrEqual(100);
  });

  it('computes chaosFactorScore in 0-100 range', () => {
    const score = chaosFactorScore(2.4, 0.5);
    expect(score).toBeGreaterThanOrEqual(0);
    expect(score).toBeLessThanOrEqual(100);
  });
});

// ── TS<->Dart parity fixtures ─────────────────────────────────────────────────
// These exact values are also asserted by the Dart suite
// (packages/stats_engine/dart/test/parity_test.dart). If one of these changes,
// change the Dart fixture in the same commit.

describe('football composites parity fixtures (mirrored in Dart)', () => {
  it('driveFinisherScore blends red zone and PPG 50/50', () => {
    expect(driveFinisherScore(0.86, 29.4)).toBe(72);
    expect(driveFinisherScore(1.2, 60)).toBe(100); // both terms capped
    expect(driveFinisherScore(0, 0)).toBe(0);
    // pointsPerGame must matter: elite red zone + no offense is NOT a 100
    expect(driveFinisherScore(0.9, 0)).toBe(45);
  });

  it('chaosFactorScore blends sacks and turnover margin 50/50', () => {
    expect(chaosFactorScore(2.4, 0.5)).toBe(53);
    expect(chaosFactorScore(3.0, 1.0)).toBe(63);
    expect(chaosFactorScore(6, 4)).toBe(100); // both terms capped
    // Each term floors at 0 — a terrible margin cannot go negative and
    // cancel the sack component.
    expect(chaosFactorScore(0, -4)).toBe(0);
    expect(chaosFactorScore(5, -4)).toBe(50);
  });
});

describe('percentile rank', () => {
  const population = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

  it('ranks median value around 50th percentile', () => {
    const pct = percentileRank(55, population);
    expect(pct).toBeGreaterThan(40);
    expect(pct).toBeLessThan(60);
  });

  it('ranks top value near 100th percentile', () => {
    const pct = percentileRank(100, population);
    expect(pct).toBeGreaterThan(90);
  });

  it('ranks bottom value near 0th percentile', () => {
    const pct = percentileRank(10, population);
    expect(pct).toBeLessThan(15);
  });

  it('inverts when higherIsBetter is false', () => {
    const pctGood = percentileRank(10, population, true)!;
    const pctBad = percentileRank(10, population, false)!;
    expect(pctGood + pctBad).toBeCloseTo(100, 0);
  });

  it('returns null for empty population — no rank is manufactured', () => {
    expect(percentileRank(50, [])).toBeNull();
  });

  // Parity fixtures (mirrored in Dart parity_test.dart)
  it('mid-rank formula parity fixtures', () => {
    const pop = [10, 20, 30, 40, 50];
    expect(percentileRank(50, pop)).toBe(90); // (4 + 0.5) / 5 * 100
    expect(percentileRank(10, pop)).toBe(10); // (0 + 0.5) / 5 * 100
    expect(percentileRank(10, pop, false)).toBe(90);
    expect(percentileRank(30, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100])).toBe(25);
  });

  it('labels percentile tiers correctly (ladder matches Dart)', () => {
    expect(percentileLabel(95)).toBe('Elite');
    expect(percentileLabel(80)).toBe('Excellent');
    expect(percentileLabel(60)).toBe('Good');
    expect(percentileLabel(50)).toBe('Average');
    expect(percentileLabel(34)).toBe('Below Average');
    expect(percentileLabel(5)).toBe('Below Average');
  });

  it('buildPercentileResult returns structured result', () => {
    const result = buildPercentileResult({
      metric: 'effectiveFgPct',
      metricLabel: 'Effective FG %',
      value: 0.552,
      population: [0.45, 0.48, 0.50, 0.52, 0.55, 0.58, 0.60],
    });
    expect(result.metric).toBe('effectiveFgPct');
    expect(result.nationalPercentile).toBeGreaterThan(0);
    expect(result.label).toBeTruthy();
    expect(result.explanation).toContain('Effective FG %');
  });

  it('buildPercentileResult makes no tier claim without comparison data', () => {
    const result = buildPercentileResult({
      metric: 'yardsPerPlay',
      metricLabel: 'Yards Per Play',
      value: 5.4,
      population: [],
    });
    expect(result.nationalPercentile).toBeNull();
    expect(result.label).toBe('No Data');
    expect(result.explanation).toBe('No comparison data available for Yards Per Play.');
    expect(result.explanation).not.toContain('percentile');
  });
});

describe('stat labels', () => {
  it('footballStatLabels has expected keys', () => {
    expect(footballStatLabels['pointsPerGame']).toBe('Points Per Game');
    expect(footballStatLabels['yardsPerPlay']).toBe('Yards Per Play');
    expect(footballStatLabels['turnoverMargin']).toBe('Turnover Margin');
  });

  it('basketballStatLabels has expected keys', () => {
    expect(basketballStatLabels['effectiveFgPct']).toBe('Effective FG %');
    expect(basketballStatLabels['tempo']).toBe('Possessions Per Game (Tempo)');
  });
});

describe('explainMetric', () => {
  it('claims the edge for Kentucky only when its rank is better', () => {
    const text = explainMetric({
      metricName: 'effectiveFgPct',
      metricLabel: 'Effective FG %',
      value: 0.552,
      secRank: 3,
      opponentName: 'Duke',
      opponentRank: 5,
      plainMeaning: 'Kentucky makes the most of each shot attempt',
    });
    expect(text).toContain('Kentucky holds the edge in Effective FG %.');
    expect(text).toContain('#3 in the SEC');
    expect(text).toContain('Duke');
  });

  it('credits the opponent when its rank is better', () => {
    const text = explainMetric({
      metricName: 'thirdDownPct',
      metricLabel: 'Third-Down Conversion %',
      value: 0.39,
      secRank: 13,
      opponentName: 'Tennessee',
      opponentRank: 2,
      plainMeaning: 'the offense keeps drives alive on third down',
    });
    expect(text).toContain('Tennessee has the edge in Third-Down Conversion %.');
    expect(text).not.toContain('Kentucky holds the edge');
    expect(text).not.toContain('biggest statistical edge');
  });

  it('calls even ranks even', () => {
    const text = explainMetric({
      metricName: 'tempo',
      metricLabel: 'Tempo',
      value: 69.2,
      secRank: 4,
      opponentName: 'Louisville',
      opponentRank: 4,
      plainMeaning: 'both teams want to push the pace',
    });
    expect(text).toContain('Kentucky and Louisville are even in Tempo.');
  });

  it('stays neutral without comparative data', () => {
    const text = explainMetric({
      metricName: 'turnoverMargin',
      metricLabel: 'Turnover Margin',
      value: 0.5,
      plainMeaning: 'Kentucky takes the ball away more than it gives it up',
      playerOrUnit: 'the defensive front seven',
    });
    expect(text).toContain('Turnover Margin is one to watch in this matchup.');
    expect(text).not.toContain('edge');
    expect(text).toContain('defensive front seven');
  });

  // Parity fixture: this exact verdict sentence is also produced by the Dart
  // buildStatStory for a Kentucky-favoring Shot Quality comparison
  // (see packages/stats_engine/dart/test/parity_test.dart).
  it('verdict phrasing matches the Dart twin word-for-word', () => {
    const text = explainMetric({
      metricName: 'effectiveFgPct',
      metricLabel: 'Shot Quality',
      value: 0.552,
      secRank: 2,
      opponentName: 'Duke',
      opponentRank: 6,
      plainMeaning: 'Kentucky makes the most of each shot attempt',
    });
    expect(text.startsWith('Kentucky holds the edge in Shot Quality.')).toBe(true);
  });
});
