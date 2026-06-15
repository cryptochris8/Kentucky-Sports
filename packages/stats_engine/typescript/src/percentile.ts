// Percentile ranking helpers

/**
 * Returns the percentile rank of a value within a sorted array.
 * Result is 0-100 (higher is better by default, or set higherIsBetter=false).
 */
export function percentileRank(
  value: number,
  population: number[],
  higherIsBetter = true,
): number {
  if (population.length === 0) return 0;
  const sorted = [...population].sort((a, b) => a - b);
  const below = sorted.filter((v) => v < value).length;
  const equal = sorted.filter((v) => v === value).length;
  const rawPct = ((below + 0.5 * equal) / sorted.length) * 100;
  return higherIsBetter ? rawPct : 100 - rawPct;
}

/**
 * Label a percentile rank as a tier string
 */
export function percentileLabel(pct: number): string {
  if (pct >= 90) return 'Elite';
  if (pct >= 75) return 'Excellent';
  if (pct >= 60) return 'Above Average';
  if (pct >= 40) return 'Average';
  if (pct >= 25) return 'Below Average';
  if (pct >= 10) return 'Poor';
  return 'Bottom Tier';
}

export interface PercentileResult {
  metric: string;
  value: number;
  nationalPercentile: number;
  label: string;
  explanation: string;
}

/**
 * Build a full PercentileResult for display
 */
export function buildPercentileResult(params: {
  metric: string;
  metricLabel: string;
  value: number;
  population: number[];
  higherIsBetter?: boolean;
}): PercentileResult {
  const pct = percentileRank(params.value, params.population, params.higherIsBetter ?? true);
  const label = percentileLabel(pct);
  return {
    metric: params.metric,
    value: params.value,
    nationalPercentile: Math.round(pct),
    label,
    explanation: `${label} — ranks in the ${Math.round(pct)}th percentile nationally on ${params.metricLabel}.`,
  };
}
