/// Football basic + advanced metric helpers (docs/06 — Football metrics).
library;

import '../shared/metric_labels.dart';

/// A grouped football metric for the Stats Lab advanced cards.
class FootballMetric {
  const FootballMetric({
    required this.key,
    required this.title,
    required this.fanLabel,
    required this.explanation,
    required this.lowerIsBetter,
  });

  final String key;
  final String title;
  final String fanLabel;
  final String explanation;
  final bool lowerIsBetter;
}

/// Headline advanced football metrics surfaced in the Stats Lab.
const List<FootballMetric> advancedFootballMetrics = <FootballMetric>[
  FootballMetric(
    key: 'successRate',
    title: 'Success Rate',
    fanLabel: 'Stay Ahead',
    lowerIsBetter: false,
    explanation:
        'How often plays gain enough to stay on schedule. Consistency moves '
        'the chains.',
  ),
  FootballMetric(
    key: 'explosivePlayRate',
    title: 'Explosive Plays',
    fanLabel: 'Big Play Spark',
    lowerIsBetter: false,
    explanation:
        'Share of plays that go for big yardage. Explosive plays flip field '
        'position fast.',
  ),
  FootballMetric(
    key: 'ppaOffense',
    title: 'PPA Offense',
    fanLabel: 'Points Added',
    lowerIsBetter: false,
    explanation:
        'Predicted Points Added per offensive play — a modern, opponent-aware '
        'efficiency measure.',
  ),
  FootballMetric(
    key: 'ppaDefense',
    title: 'PPA Defense',
    fanLabel: 'Points Saved',
    lowerIsBetter: true,
    explanation:
        'Predicted Points Added allowed per play. Lower means the defense is '
        'limiting opponent value.',
  ),
  FootballMetric(
    key: 'turnoverMargin',
    title: 'Turnover Margin',
    fanLabel: 'Ball Security Grade',
    lowerIsBetter: false,
    explanation:
        'Takeaways minus giveaways. Winning the turnover battle is strongly '
        'tied to winning games.',
  ),
  FootballMetric(
    key: 'redZoneScorePct',
    title: 'Red-Zone Scoring',
    fanLabel: 'Drive Finisher',
    lowerIsBetter: false,
    explanation:
        'How often red-zone trips produce points. Finishing drives wins close '
        'games.',
  ),
];

/// Basic box-score football metrics for the overview/compare view.
const List<FootballMetric> basicFootballMetrics = <FootballMetric>[
  FootballMetric(
    key: 'pointsPerGame',
    title: 'Points / Game',
    fanLabel: 'Scoring Punch',
    lowerIsBetter: false,
    explanation: 'Average points scored per game.',
  ),
  FootballMetric(
    key: 'pointsAllowedPerGame',
    title: 'Points Allowed',
    fanLabel: 'Defensive Wall',
    lowerIsBetter: true,
    explanation: 'Average points allowed per game.',
  ),
  FootballMetric(
    key: 'yardsPerPlay',
    title: 'Yards / Play',
    fanLabel: 'Efficiency',
    lowerIsBetter: false,
    explanation: 'Average yards gained per offensive snap.',
  ),
  FootballMetric(
    key: 'thirdDownPct',
    title: 'Third Down',
    fanLabel: 'Grit Index',
    lowerIsBetter: false,
    explanation: 'Third-down conversion rate. Sustained drives wear defenses '
        'down.',
  ),
];

// PARITY: the two composite formulas below are mirrored exactly in the
// TypeScript twin (packages/stats_engine/typescript/src/football.ts). Each
// term is clamped to 0..1 before weighting so one bad component can never
// silently cancel the other. Both test suites assert the same shared fixtures.

double _clamp01(double v) => v.clamp(0.0, 1.0);

/// "Chaos Factor" composite (docs/06): sacks + forced takeaways pressure.
///
/// Returns a 0..100 fan-facing score. Demo-grade heuristic, not an official
/// metric. Formula:
///   clamp01(sacksPerGame / 5) * 50 + clamp01((turnoverMargin + 3) / 6) * 50,
/// rounded.
double chaosFactorScore(Map<String, dynamic> stats) {
  final double sacks = (stats['sacksPerGame'] as num?)?.toDouble() ?? 0;
  final double tom = (stats['turnoverMargin'] as num?)?.toDouble() ?? 0;
  final double sackScore = _clamp01(sacks / 5.0) * 50;
  final double tomScore = _clamp01((tom + 3.0) / 6.0) * 50;
  return (sackScore + tomScore).roundToDouble();
}

/// "Drive Finisher" composite: red-zone efficiency + scoring punch on a
/// 0..100 scale — a 50/50 blend, per its documented inputs
/// (redZoneScorePct + pointsPerGame). Formula:
///   clamp01(redZoneScorePct) * 50 + clamp01(pointsPerGame / 50) * 50,
/// rounded.
double driveFinisherScore(Map<String, dynamic> stats) {
  final double rz = (stats['redZoneScorePct'] as num?)?.toDouble() ?? 0;
  final double ppg = (stats['pointsPerGame'] as num?)?.toDouble() ?? 0;
  final double rzScore = _clamp01(rz) * 50;
  final double ppgScore = _clamp01(ppg / 50.0) * 50;
  return (rzScore + ppgScore).roundToDouble();
}

/// Looks up fan-friendly metadata for a football metric key.
MetricLabel footballLabel(String key) => labelFor(key, sport: 'football');
