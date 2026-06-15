/// Basketball "Four Factors" helpers (docs/06 — Basketball metrics).
///
/// Dean Oliver's Four Factors of winning basketball:
///   1. Shooting   (Effective FG%)
///   2. Turnovers  (Turnover Rate — lower is better)
///   3. Rebounding (Offensive Rebound Rate)
///   4. Free Throws(Free Throw Rate)
library;

import '../shared/metric_labels.dart';

/// One of the four factors, with its raw key and fan-friendly framing.
class FourFactor {
  const FourFactor({
    required this.key,
    required this.title,
    required this.fanLabel,
    required this.weight,
    required this.lowerIsBetter,
    required this.explanation,
  });

  /// Raw stat key in team_stats.stats (e.g. `effectiveFgPct`).
  final String key;

  /// Display title, e.g. "Shooting".
  final String title;

  /// Broadcast-style label, e.g. "Shot Quality".
  final String fanLabel;

  /// Approximate importance weight (sums to ~1.0) per Oliver's research.
  final double weight;

  /// Whether a lower raw value is better (true for turnover rate).
  final bool lowerIsBetter;

  /// Plain-English explanation.
  final String explanation;
}

/// The canonical Four Factors in priority order.
const List<FourFactor> fourFactors = <FourFactor>[
  FourFactor(
    key: 'effectiveFgPct',
    title: 'Shooting',
    fanLabel: 'Shot Quality',
    weight: 0.40,
    lowerIsBetter: false,
    explanation:
        'Effective FG% — the most important factor. It measures how '
        'efficiently a team scores, giving extra credit for three-pointers.',
  ),
  FourFactor(
    key: 'turnoverRate',
    title: 'Turnovers',
    fanLabel: 'Ball Control',
    weight: 0.25,
    lowerIsBetter: true,
    explanation:
        'Turnover Rate — the share of possessions wasted on turnovers. '
        'Protecting the ball means more chances to score. Lower is better.',
  ),
  FourFactor(
    key: 'offReboundRate',
    title: 'Rebounding',
    fanLabel: 'Glass Work',
    weight: 0.20,
    lowerIsBetter: false,
    explanation:
        'Offensive Rebound Rate — how often a team grabs its own misses for '
        'second-chance points.',
  ),
  FourFactor(
    key: 'freeThrowRate',
    title: 'Free Throws',
    fanLabel: 'Paint Pressure',
    weight: 0.15,
    lowerIsBetter: false,
    explanation:
        'Free Throw Rate — how often a team gets to the line for easy points '
        'and puts opponents in foul trouble.',
  ),
];

/// A computed Four Factor reading for one team.
class FourFactorValue {
  const FourFactorValue({
    required this.factor,
    required this.value,
    required this.percentile,
  });

  final FourFactor factor;
  final double value;

  /// 0..100 national percentile (from seed rankings or computed).
  final int percentile;

  /// Display string honoring percent metrics.
  String get display => '${(value * 100).toStringAsFixed(1)}%';
}

/// Extracts the Four Factors from a team's `stats` map.
///
/// Missing factors are skipped so partial demo data still renders.
List<FourFactorValue> extractFourFactors(
  Map<String, dynamic> stats, {
  Map<String, int> percentiles = const <String, int>{},
}) {
  final List<FourFactorValue> out = <FourFactorValue>[];
  for (final FourFactor f in fourFactors) {
    final dynamic raw = stats[f.key];
    if (raw is num) {
      out.add(
        FourFactorValue(
          factor: f,
          value: raw.toDouble(),
          percentile: percentiles[f.key] ?? 50,
        ),
      );
    }
  }
  return out;
}

/// "Shot Quality" composite: eFG% expressed on a 0..100 fan scale.
double shotQualityScore(Map<String, dynamic> stats) {
  final dynamic efg = stats['effectiveFgPct'];
  if (efg is num) {
    // Map a realistic 0.45..0.60 eFG% band onto 0..100.
    final double scaled = ((efg.toDouble() - 0.45) / 0.15) * 100;
    return scaled.clamp(0, 100);
  }
  return 50;
}

/// Looks up the fan-friendly label metadata for a Four Factor key.
MetricLabel fourFactorLabel(String key) =>
    labelFor(key, sport: 'mens_basketball');
