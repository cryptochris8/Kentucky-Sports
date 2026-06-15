// Basketball Four Factors and advanced metric helpers

/**
 * Effective Field Goal % — adjusts FG% by counting 3-pointers as 1.5x
 * Formula: (FGM + 0.5 * 3PM) / FGA
 */
export function effectiveFgPct(fgm: number, threePm: number, fga: number): number {
  if (fga === 0) return 0;
  return (fgm + 0.5 * threePm) / fga;
}

/**
 * Turnover Rate — turnovers per 100 possessions
 * Formula: TO / (FGA + 0.44 * FTA + TO) * 100
 */
export function turnoverRate(to: number, fga: number, fta: number): number {
  const possessions = fga + 0.44 * fta + to;
  if (possessions === 0) return 0;
  return (to / possessions) * 100;
}

/**
 * Offensive Rebound Rate — fraction of available offensive boards captured
 * Formula: OReb / (OReb + OpponentDReb)
 */
export function offReboundRate(oreb: number, opponentDreb: number): number {
  const total = oreb + opponentDreb;
  if (total === 0) return 0;
  return oreb / total;
}

/**
 * Free Throw Rate — free throw attempts relative to field goal attempts
 * Formula: FTA / FGA
 */
export function freeThrowRate(fta: number, fga: number): number {
  if (fga === 0) return 0;
  return fta / fga;
}

/**
 * Four Factors summary for a team
 * Returns all four factors with their computed values
 */
export interface FourFactors {
  effectiveFgPct: number;
  turnoverRate: number;
  offReboundRate: number;
  freeThrowRate: number;
}

export function computeFourFactors(params: {
  fgm: number;
  threePm: number;
  fga: number;
  to: number;
  fta: number;
  oreb: number;
  opponentDreb: number;
}): FourFactors {
  return {
    effectiveFgPct: effectiveFgPct(params.fgm, params.threePm, params.fga),
    turnoverRate: turnoverRate(params.to, params.fga, params.fta),
    offReboundRate: offReboundRate(params.oreb, params.opponentDreb),
    freeThrowRate: freeThrowRate(params.fta, params.fga),
  };
}

/**
 * Adjusted offensive rating estimate from raw points and possessions
 * (Points scored per 100 possessions)
 */
export function offRating(points: number, possessions: number): number {
  if (possessions === 0) return 0;
  return (points / possessions) * 100;
}

/**
 * Adjusted net rating = offensive rating - defensive rating
 */
export function netRating(adjOff: number, adjDef: number): number {
  return adjOff - adjDef;
}
