/// Percentile ranking helpers (docs/06 — Percentile rankings).
///
/// PARITY: the formula, empty-population semantics, and tier ladder are
/// mirrored exactly in the TypeScript twin
/// (packages/stats_engine/typescript/src/percentile.ts). Change one side only
/// in lockstep with the other — both test suites assert the same fixtures.
library;

/// A quality tier derived from a percentile, used for color + label.
enum PercentileTier { elite, excellent, good, average, belowAverage }

extension PercentileTierLabel on PercentileTier {
  /// Short human label, e.g. "Excellent".
  String get label {
    switch (this) {
      case PercentileTier.elite:
        return 'Elite';
      case PercentileTier.excellent:
        return 'Excellent';
      case PercentileTier.good:
        return 'Good';
      case PercentileTier.average:
        return 'Average';
      case PercentileTier.belowAverage:
        return 'Below Average';
    }
  }
}

/// Result of a percentile evaluation for one metric.
class PercentileResult {
  const PercentileResult({
    required this.metric,
    required this.value,
    this.percentile,
    this.tier,
    required this.explanation,
  });

  final String metric;
  final double value;

  /// 0..100 national percentile, or null when no comparison data was available.
  final int? percentile;

  /// Quality tier, or null when no comparison data was available.
  final PercentileTier? tier;
  final String explanation;
}

/// Maps a 0..100 [percentile] to a [PercentileTier].
PercentileTier tierForPercentile(int percentile) {
  if (percentile >= 90) return PercentileTier.elite;
  if (percentile >= 75) return PercentileTier.excellent;
  if (percentile >= 55) return PercentileTier.good;
  if (percentile >= 35) return PercentileTier.average;
  return PercentileTier.belowAverage;
}

/// Computes the percentile of [value] within [population] (0..100).
///
/// Uses the standard mid-rank definition — (below + 0.5 * equal) / n * 100 —
/// rounded to an integer and clamped to 0..100. If [lowerIsBetter] is true
/// (e.g. points allowed), the percentile is inverted so that a better value
/// always yields a higher percentile.
///
/// Returns null for an empty [population] — there is no basis for a rank, and
/// callers must render "no comparison data" rather than manufacture a tier.
int? percentileOf(
  double value,
  List<double> population, {
  bool lowerIsBetter = false,
}) {
  if (population.isEmpty) return null;
  final int below = population.where((double v) => v < value).length;
  final int equal = population.where((double v) => v == value).length;
  double rawPct = ((below + 0.5 * equal) / population.length) * 100;
  if (lowerIsBetter) rawPct = 100 - rawPct;
  return rawPct.round().clamp(0, 100);
}

/// Convenience that bundles a value's percentile + tier + explanation.
///
/// When a real [population] is unavailable (demo data), pass a precomputed
/// [knownPercentile] from the seed instead. With neither, the result carries a
/// null percentile/tier and an honest "no comparison data" explanation.
PercentileResult evaluatePercentile({
  required String metric,
  required double value,
  List<double> population = const <double>[],
  int? knownPercentile,
  bool lowerIsBetter = false,
}) {
  final int? pct =
      knownPercentile ??
      percentileOf(value, population, lowerIsBetter: lowerIsBetter);
  if (pct == null) {
    return PercentileResult(
      metric: metric,
      value: value,
      explanation: 'No comparison data available.',
    );
  }
  final PercentileTier tier = tierForPercentile(pct);
  return PercentileResult(
    metric: metric,
    value: value,
    percentile: pct,
    tier: tier,
    explanation: _percentileExplanation(pct, tier),
  );
}

String _percentileExplanation(int pct, PercentileTier tier) {
  switch (tier) {
    case PercentileTier.elite:
      return 'Top-tier — better than roughly $pct% of teams.';
    case PercentileTier.excellent:
      return 'Strong — ahead of about $pct% of the field.';
    case PercentileTier.good:
      return 'Above the pack — better than $pct% of teams.';
    case PercentileTier.average:
      return 'Right around the middle ($pct percentile).';
    case PercentileTier.belowAverage:
      return 'A spot to improve — only $pct% of teams rank lower.';
  }
}
