// Percentile ranking helpers
//
// PARITY: the formula, empty-population semantics, and tier ladder below are
// mirrored exactly in the Dart twin
// (packages/stats_engine/dart/lib/src/shared/percentile_rank.dart).
// Change one side only in lockstep with the other — both test suites assert
// the same shared fixtures.

/**
 * Returns the percentile rank of a value within a population, using the
 * standard mid-rank definition: (below + 0.5 * equal) / n * 100, rounded to an
 * integer and clamped to 0..100. Set higherIsBetter=false (e.g. points
 * allowed) to invert so a better value always yields a higher percentile.
 *
 * Returns null for an empty population — there is no basis for a rank, and
 * callers must render "no comparison data" rather than manufacture a tier.
 */
export function percentileRank(
  value: number,
  population: number[],
  higherIsBetter = true,
): number | null {
  if (population.length === 0) return null;
  const below = population.filter((v) => v < value).length;
  const equal = population.filter((v) => v === value).length;
  let rawPct = ((below + 0.5 * equal) / population.length) * 100;
  if (!higherIsBetter) rawPct = 100 - rawPct;
  return Math.min(100, Math.max(0, Math.round(rawPct)));
}

/**
 * Label a percentile rank as a tier string.
 * Ladder matches the Dart PercentileTier bands exactly.
 */
export function percentileLabel(pct: number): string {
  if (pct >= 90) return 'Elite';
  if (pct >= 75) return 'Excellent';
  if (pct >= 55) return 'Good';
  if (pct >= 35) return 'Average';
  return 'Below Average';
}

export interface PercentileResult {
  metric: string;
  value: number;
  /** 0..100 national percentile, or null when no comparison data was available. */
  nationalPercentile: number | null;
  label: string;
  explanation: string;
}

/**
 * Build a full PercentileResult for display. With an empty population the
 * result makes no tier claim — label "No Data" and an honest explanation.
 */
export function buildPercentileResult(params: {
  metric: string;
  metricLabel: string;
  value: number;
  population: number[];
  higherIsBetter?: boolean;
}): PercentileResult {
  const pct = percentileRank(params.value, params.population, params.higherIsBetter ?? true);
  if (pct === null) {
    return {
      metric: params.metric,
      value: params.value,
      nationalPercentile: null,
      label: 'No Data',
      explanation: `No comparison data available for ${params.metricLabel}.`,
    };
  }
  const label = percentileLabel(pct);
  return {
    metric: params.metric,
    value: params.value,
    nationalPercentile: pct,
    label,
    explanation: `${label} — ranks in the ${pct}th percentile nationally on ${params.metricLabel}.`,
  };
}
