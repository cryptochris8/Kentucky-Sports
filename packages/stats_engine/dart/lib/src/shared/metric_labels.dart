/// Fan-friendly label maps and plain-English explanations for raw metric keys.
///
/// These map the technical stat keys used in the Firestore data model
/// (docs/04) to human-readable display names and "What this means"
/// explanations described in docs/06 (Stats Engine Design).
library;

/// A single metric's display metadata.
class MetricLabel {
  const MetricLabel({
    required this.key,
    required this.displayName,
    required this.shortLabel,
    required this.explanation,
    this.isPercent = false,
    this.higherIsBetter = true,
  });

  /// Raw stat key, e.g. `effectiveFgPct`.
  final String key;

  /// Full fan-facing display name, e.g. "Effective FG%".
  final String displayName;

  /// Short broadcast-style label, e.g. "Shot Quality".
  final String shortLabel;

  /// Plain-English "What this means" copy.
  final String explanation;

  /// Whether the raw value is a 0..1 ratio that should render as a percent.
  final bool isPercent;

  /// Whether a higher value is better (controls trend arrow direction).
  final bool higherIsBetter;
}

/// Catch-all fallback used when a key is unknown.
const MetricLabel _unknownMetric = MetricLabel(
  key: '__unknown__',
  displayName: 'Stat',
  shortLabel: 'Stat',
  explanation: 'A demo statistic for this matchup.',
);

/// Football metric labels (basic + advanced + fan-friendly).
const Map<String, MetricLabel> footballMetricLabels = <String, MetricLabel>{
  'pointsPerGame': MetricLabel(
    key: 'pointsPerGame',
    displayName: 'Points / Game',
    shortLabel: 'Scoring Punch',
    explanation:
        'How many points the offense averages per game. Higher means a more '
        'productive scoring attack.',
  ),
  'pointsAllowedPerGame': MetricLabel(
    key: 'pointsAllowedPerGame',
    displayName: 'Points Allowed / Game',
    shortLabel: 'Defensive Wall',
    explanation:
        'Average points the defense gives up per game. Lower is better — it '
        'means the defense keeps opponents out of the end zone.',
    higherIsBetter: false,
  ),
  'yardsPerPlay': MetricLabel(
    key: 'yardsPerPlay',
    displayName: 'Yards / Play',
    shortLabel: 'Efficiency',
    explanation:
        'Average yards gained on every offensive snap. It is one of the best '
        'single measures of offensive efficiency.',
  ),
  'passingYardsPerGame': MetricLabel(
    key: 'passingYardsPerGame',
    displayName: 'Passing Yards / Game',
    shortLabel: 'Air Attack',
    explanation: 'Average passing yards per game through the air.',
  ),
  'rushingYardsPerGame': MetricLabel(
    key: 'rushingYardsPerGame',
    displayName: 'Rushing Yards / Game',
    shortLabel: 'Ground Game',
    explanation: 'Average rushing yards per game on the ground.',
  ),
  'thirdDownPct': MetricLabel(
    key: 'thirdDownPct',
    displayName: 'Third-Down Conversion',
    shortLabel: 'Grit Index',
    explanation:
        'How often the offense converts third downs to keep drives alive. '
        'Sustained drives wear down a defense.',
    isPercent: true,
  ),
  'redZoneScorePct': MetricLabel(
    key: 'redZoneScorePct',
    displayName: 'Red-Zone Scoring',
    shortLabel: 'Drive Finisher',
    explanation:
        'How often the team scores once it reaches the red zone. Finishing '
        'drives with touchdowns instead of field goals wins close games.',
    isPercent: true,
  ),
  'turnoverMargin': MetricLabel(
    key: 'turnoverMargin',
    displayName: 'Turnover Margin',
    shortLabel: 'Ball Security Grade',
    explanation:
        'Takeaways minus giveaways per game. A positive margin means the team '
        'wins the turnover battle, which is strongly tied to winning.',
  ),
  'sacksPerGame': MetricLabel(
    key: 'sacksPerGame',
    displayName: 'Sacks / Game',
    shortLabel: 'Chaos Factor',
    explanation:
        'Average quarterback sacks per game. Pressure disrupts the passing '
        'game and forces mistakes.',
  ),
  'explosivePlayRate': MetricLabel(
    key: 'explosivePlayRate',
    displayName: 'Explosive Play Rate',
    shortLabel: 'Big Play Spark',
    explanation:
        'Share of plays that go for big chunks of yardage. Explosive plays '
        'flip field position and put points on the board fast.',
    isPercent: true,
  ),
  'successRate': MetricLabel(
    key: 'successRate',
    displayName: 'Success Rate',
    shortLabel: 'Stay Ahead',
    explanation:
        'How often a play gains "enough" yards for the down and distance. It '
        'rewards consistently staying on schedule.',
    isPercent: true,
  ),
  'ppaOffense': MetricLabel(
    key: 'ppaOffense',
    displayName: 'PPA (Offense)',
    shortLabel: 'Points Added',
    explanation:
        'Predicted Points Added on offense — the average value each play adds '
        'toward scoring. A modern, opponent-aware efficiency stat.',
  ),
  'ppaDefense': MetricLabel(
    key: 'ppaDefense',
    displayName: 'PPA (Defense)',
    shortLabel: 'Points Saved',
    explanation:
        'Predicted Points Added allowed by the defense. Lower is better — the '
        'defense is limiting the value of opponent plays.',
    higherIsBetter: false,
  ),
};

/// Basketball metric labels (basic + advanced + Four Factors).
const Map<String, MetricLabel> basketballMetricLabels = <String, MetricLabel>{
  'pointsPerGame': MetricLabel(
    key: 'pointsPerGame',
    displayName: 'Points / Game',
    shortLabel: 'Scoring',
    explanation: 'Average points scored per game.',
  ),
  'pointsAllowedPerGame': MetricLabel(
    key: 'pointsAllowedPerGame',
    displayName: 'Points Allowed / Game',
    shortLabel: 'Defense',
    explanation: 'Average points allowed per game. Lower is better.',
    higherIsBetter: false,
  ),
  'fieldGoalPct': MetricLabel(
    key: 'fieldGoalPct',
    displayName: 'Field Goal %',
    shortLabel: 'FG%',
    explanation: 'Share of field goal attempts that go in.',
    isPercent: true,
  ),
  'threePointPct': MetricLabel(
    key: 'threePointPct',
    displayName: 'Three-Point %',
    shortLabel: '3P%',
    explanation: 'Share of three-point attempts that go in.',
    isPercent: true,
  ),
  'freeThrowPct': MetricLabel(
    key: 'freeThrowPct',
    displayName: 'Free Throw %',
    shortLabel: 'FT%',
    explanation: 'Share of free throws made.',
    isPercent: true,
  ),
  'effectiveFgPct': MetricLabel(
    key: 'effectiveFgPct',
    displayName: 'Effective FG%',
    shortLabel: 'Shot Quality',
    explanation:
        'Field goal percentage that gives extra credit for three-pointers '
        '(they are worth more). The single best measure of shooting '
        'efficiency.',
    isPercent: true,
  ),
  'turnoverRate': MetricLabel(
    key: 'turnoverRate',
    displayName: 'Turnover Rate',
    shortLabel: 'Ball Control',
    explanation:
        'Share of possessions that end in a turnover. Lower is better — every '
        'turnover is a wasted possession.',
    isPercent: true,
    higherIsBetter: false,
  ),
  'offReboundRate': MetricLabel(
    key: 'offReboundRate',
    displayName: 'Offensive Rebound Rate',
    shortLabel: 'Glass Work',
    explanation:
        'Share of available offensive rebounds the team grabs. More boards '
        'mean more second-chance points.',
    isPercent: true,
  ),
  'freeThrowRate': MetricLabel(
    key: 'freeThrowRate',
    displayName: 'Free Throw Rate',
    shortLabel: 'Paint Pressure',
    explanation:
        'How often the team gets to the free-throw line relative to shots. '
        'Drawing fouls means easy points and foul trouble for opponents.',
    isPercent: true,
  ),
  'adjOffRating': MetricLabel(
    key: 'adjOffRating',
    displayName: 'Adj. Offensive Rating',
    shortLabel: 'Offense Engine',
    explanation:
        'Points scored per 100 possessions, adjusted for opponent strength. '
        'Higher means a more efficient offense.',
  ),
  'adjDefRating': MetricLabel(
    key: 'adjDefRating',
    displayName: 'Adj. Defensive Rating',
    shortLabel: 'Defense Engine',
    explanation:
        'Points allowed per 100 possessions, adjusted for opponent strength. '
        'Lower is better.',
    higherIsBetter: false,
  ),
  'adjNetRating': MetricLabel(
    key: 'adjNetRating',
    displayName: 'Adj. Net Rating',
    shortLabel: 'Overall Edge',
    explanation:
        'Adjusted offense minus adjusted defense. A team-strength summary in '
        'one number — higher is better.',
  ),
  'tempo': MetricLabel(
    key: 'tempo',
    displayName: 'Tempo',
    shortLabel: 'Tempo Meter',
    explanation:
        'Possessions per game. A faster tempo means more shots and a track-'
        'meet style; a slower tempo grinds the clock.',
  ),
  'assistRate': MetricLabel(
    key: 'assistRate',
    displayName: 'Assist Rate',
    shortLabel: 'Ball Movement',
    explanation:
        'Share of made baskets that come off an assist. High assist rates '
        'signal unselfish, connected offense.',
    isPercent: true,
  ),
  'reboundsPerGame': MetricLabel(
    key: 'reboundsPerGame',
    displayName: 'Rebounds / Game',
    shortLabel: 'Boards',
    explanation: 'Average total rebounds per game.',
  ),
  'assistsPerGame': MetricLabel(
    key: 'assistsPerGame',
    displayName: 'Assists / Game',
    shortLabel: 'Dimes',
    explanation: 'Average assists per game.',
  ),
  'turnoversPerGame': MetricLabel(
    key: 'turnoversPerGame',
    displayName: 'Turnovers / Game',
    shortLabel: 'Giveaways',
    explanation: 'Average turnovers per game. Lower is better.',
    higherIsBetter: false,
  ),
};

/// Player-level metric labels shared across sports.
const Map<String, MetricLabel> playerMetricLabels = <String, MetricLabel>{
  'points': MetricLabel(
    key: 'points',
    displayName: 'Points',
    shortLabel: 'PPG',
    explanation: 'Average points per game.',
  ),
  'rebounds': MetricLabel(
    key: 'rebounds',
    displayName: 'Rebounds',
    shortLabel: 'RPG',
    explanation: 'Average rebounds per game.',
  ),
  'assists': MetricLabel(
    key: 'assists',
    displayName: 'Assists',
    shortLabel: 'APG',
    explanation: 'Average assists per game.',
  ),
  'effectiveFgPct': MetricLabel(
    key: 'effectiveFgPct',
    displayName: 'Effective FG%',
    shortLabel: 'eFG%',
    explanation:
        'Shooting efficiency that credits the extra value of three-pointers.',
    isPercent: true,
  ),
  'threePointPct': MetricLabel(
    key: 'threePointPct',
    displayName: 'Three-Point %',
    shortLabel: '3P%',
    explanation: 'Share of three-point attempts that go in.',
    isPercent: true,
  ),
  'usageRate': MetricLabel(
    key: 'usageRate',
    displayName: 'Usage Rate',
    shortLabel: 'USG%',
    explanation:
        'Share of team possessions a player uses while on the floor. High '
        'usage means the offense runs through them.',
    isPercent: true,
  ),
  'assistTurnoverRatio': MetricLabel(
    key: 'assistTurnoverRatio',
    displayName: 'Assist / Turnover',
    shortLabel: 'A/TO',
    explanation:
        'Assists divided by turnovers. Above 2.0 is strong floor-general play.',
  ),
  'blocksPerGame': MetricLabel(
    key: 'blocksPerGame',
    displayName: 'Blocks / Game',
    shortLabel: 'BPG',
    explanation: 'Average blocked shots per game.',
  ),
  'offReboundRate': MetricLabel(
    key: 'offReboundRate',
    displayName: 'Offensive Rebound Rate',
    shortLabel: 'OReb%',
    explanation: 'Share of available offensive rebounds grabbed.',
    isPercent: true,
  ),
  'passYards': MetricLabel(
    key: 'passYards',
    displayName: 'Passing Yards',
    shortLabel: 'Pass Yds',
    explanation: 'Total passing yards on the season.',
  ),
  'passTds': MetricLabel(
    key: 'passTds',
    displayName: 'Passing TDs',
    shortLabel: 'Pass TD',
    explanation: 'Total passing touchdowns.',
  ),
  'interceptions': MetricLabel(
    key: 'interceptions',
    displayName: 'Interceptions',
    shortLabel: 'INT',
    explanation: 'Total interceptions thrown. Lower is better.',
    higherIsBetter: false,
  ),
  'completionPct': MetricLabel(
    key: 'completionPct',
    displayName: 'Completion %',
    shortLabel: 'Comp%',
    explanation: 'Share of pass attempts completed.',
    isPercent: true,
  ),
  'rushYards': MetricLabel(
    key: 'rushYards',
    displayName: 'Rushing Yards',
    shortLabel: 'Rush Yds',
    explanation: 'Total rushing yards on the season.',
  ),
  'rushTds': MetricLabel(
    key: 'rushTds',
    displayName: 'Rushing TDs',
    shortLabel: 'Rush TD',
    explanation: 'Total rushing touchdowns.',
  ),
  'qbr': MetricLabel(
    key: 'qbr',
    displayName: 'QBR',
    shortLabel: 'QBR',
    explanation:
        'A 0-100 quarterback rating that blends efficiency, scoring, and '
        'situation. Higher is better.',
  ),
  'yardsPerCarry': MetricLabel(
    key: 'yardsPerCarry',
    displayName: 'Yards / Carry',
    shortLabel: 'YPC',
    explanation: 'Average rushing yards per carry.',
  ),
  'receptions': MetricLabel(
    key: 'receptions',
    displayName: 'Receptions',
    shortLabel: 'Rec',
    explanation: 'Total catches on the season.',
  ),
  'recYards': MetricLabel(
    key: 'recYards',
    displayName: 'Receiving Yards',
    shortLabel: 'Rec Yds',
    explanation: 'Total receiving yards on the season.',
  ),
  'recTds': MetricLabel(
    key: 'recTds',
    displayName: 'Receiving TDs',
    shortLabel: 'Rec TD',
    explanation: 'Total receiving touchdowns.',
  ),
  'yardsPerCatch': MetricLabel(
    key: 'yardsPerCatch',
    displayName: 'Yards / Catch',
    shortLabel: 'YPC',
    explanation: 'Average yards per reception.',
  ),
};

/// Looks up a [MetricLabel] for [key] across all known maps for [sport].
///
/// [sport] should be `football`, `mens_basketball`, `womens_basketball`, etc.
/// Falls back to a generic label if the key is unknown so the UI never breaks.
MetricLabel labelFor(String key, {String sport = 'football'}) {
  if (sport.contains('basketball')) {
    return basketballMetricLabels[key] ??
        playerMetricLabels[key] ??
        _withKey(key);
  }
  return footballMetricLabels[key] ?? playerMetricLabels[key] ?? _withKey(key);
}

/// Looks up a player metric label across both sports.
MetricLabel playerLabelFor(String key) {
  return playerMetricLabels[key] ??
      basketballMetricLabels[key] ??
      footballMetricLabels[key] ??
      _withKey(key);
}

MetricLabel _withKey(String key) {
  return MetricLabel(
    key: key,
    displayName: _humanize(key),
    shortLabel: _humanize(key),
    explanation: _unknownMetric.explanation,
  );
}

/// Turns `camelCase` keys into "Title Case" words as a last resort.
String _humanize(String key) {
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < key.length; i++) {
    final String ch = key[i];
    if (i == 0) {
      out.write(ch.toUpperCase());
    } else if (ch.toUpperCase() == ch && ch.toLowerCase() != ch) {
      out.write(' $ch');
    } else {
      out.write(ch);
    }
  }
  return out.toString();
}
