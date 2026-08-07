// Football basic + advanced metric helpers

/**
 * Yards Per Play — total scrimmage yards / total plays
 */
export function yardsPerPlay(totalYards: number, totalPlays: number): number {
  if (totalPlays === 0) return 0;
  return totalYards / totalPlays;
}

/**
 * Turnover Margin — turnovers gained minus turnovers lost
 */
export function turnoverMargin(gained: number, lost: number): number {
  return gained - lost;
}

/**
 * Red Zone Score % — scoring drives / red-zone trips
 */
export function redZoneScorePct(scoringDrives: number, redZoneTrips: number): number {
  if (redZoneTrips === 0) return 0;
  return scoringDrives / redZoneTrips;
}

/**
 * Third Down Conversion % — conversions / attempts
 */
export function thirdDownConversionPct(conversions: number, attempts: number): number {
  if (attempts === 0) return 0;
  return conversions / attempts;
}

/**
 * Explosive Play Rate — plays of 20+ yards / total plays
 */
export function explosivePlayRate(explosivePlays: number, totalPlays: number): number {
  if (totalPlays === 0) return 0;
  return explosivePlays / totalPlays;
}

/**
 * Success Rate — plays gaining ≥50% of needed yards on 1st down,
 * ≥70% on 2nd, 100% on 3rd/4th (approximated here as fraction passed to function)
 */
export function successRate(successfulPlays: number, totalPlays: number): number {
  if (totalPlays === 0) return 0;
  return successfulPlays / totalPlays;
}

// PARITY: the two composite formulas below are mirrored exactly in the Dart
// twin (packages/stats_engine/dart/lib/src/football/football_metrics.dart).
// Each term is clamped to 0..1 before weighting so one bad component can never
// silently cancel the other. Both test suites assert the same shared fixtures.

const clamp01 = (v: number): number => Math.min(1, Math.max(0, v));

/**
 * Estimated Drive Finisher score (0-100) based on redzone efficiency and PPG.
 * Used for the fan-friendly "Drive Finisher" label (see labels.ts:
 * metrics ['redZoneScorePct', 'pointsPerGame'] — a 50/50 blend).
 * Formula: clamp01(redZonePct) * 50 + clamp01(pointsPerGame / 50) * 50, rounded.
 */
export function driveFinisherScore(redZonePct: number, pointsPerGame: number): number {
  const rzScore = clamp01(redZonePct) * 50;
  const ppgScore = clamp01(pointsPerGame / 50) * 50;
  return Math.round(rzScore + ppgScore);
}

/**
 * Chaos Factor (0-100) — composite of sacks and turnover margin.
 * Formula: clamp01(sacksPerGame / 5) * 50 + clamp01((turnoverMargin + 3) / 6) * 50, rounded.
 */
export function chaosFactorScore(sacksPerGame: number, turnoverMarginVal: number): number {
  const sackScore = clamp01(sacksPerGame / 5) * 50;
  const toScore = clamp01((turnoverMarginVal + 3) / 6) * 50;
  return Math.round(sackScore + toScore);
}
