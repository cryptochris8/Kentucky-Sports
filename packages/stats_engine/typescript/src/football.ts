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

/**
 * Estimated Drive Finisher score (0-100) based on redzone efficiency and PPG
 * Used for the fan-friendly "Drive Finisher" label
 */
export function driveFinisherScore(redZonePct: number, pointsPerGame: number): number {
  const rzScore = Math.min(redZonePct, 1) * 50;
  const ppgScore = Math.min(pointsPerGame / 50, 1) * 50;
  return Math.round(rzScore + ppgScore);
}

/**
 * Chaos Factor (0-100) — composite of sacks and turnover margin
 */
export function chaosFactorScore(sacksPerGame: number, turnoverMarginVal: number): number {
  const sackScore = Math.min(sacksPerGame / 5, 1) * 50;
  const toScore = Math.min((turnoverMarginVal + 3) / 6, 1) * 50;
  return Math.round(sackScore + toScore);
}
