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

/// "Chaos Factor" composite (docs/06): sacks + forced takeaways pressure.
///
/// Returns a 0..100 fan-facing score from sacks/game and a positive turnover
/// margin. Demo-grade heuristic, not an official metric.
double chaosFactorScore(Map<String, dynamic> stats) {
  final double sacks = (stats['sacksPerGame'] as num?)?.toDouble() ?? 0;
  final double tom = (stats['turnoverMargin'] as num?)?.toDouble() ?? 0;
  // 3.0 sacks/game ~ strong; +1.0 turnover margin ~ elite.
  final double sackScore = (sacks / 3.0) * 60;
  final double tomScore = ((tom + 1.0) / 2.0) * 40;
  return (sackScore + tomScore).clamp(0, 100);
}

/// "Drive Finisher" composite: red-zone scoring on a 0..100 scale.
double driveFinisherScore(Map<String, dynamic> stats) {
  final double rz = (stats['redZoneScorePct'] as num?)?.toDouble() ?? 0;
  return (rz * 100).clamp(0, 100);
}

/// Looks up fan-friendly metadata for a football metric key.
MetricLabel footballLabel(String key) => labelFor(key, sport: 'football');
