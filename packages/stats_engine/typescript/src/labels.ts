// Fan-friendly stat labels for Bluegrass Gameday
// These map raw metric keys to human-readable display names

export const footballStatLabels: Record<string, string> = {
  pointsPerGame: 'Points Per Game',
  pointsAllowedPerGame: 'Points Allowed Per Game',
  yardsPerPlay: 'Yards Per Play',
  passingYardsPerGame: 'Passing Yards/Game',
  rushingYardsPerGame: 'Rushing Yards/Game',
  thirdDownPct: 'Third-Down Conversion %',
  redZoneScorePct: 'Red-Zone Score %',
  turnoverMargin: 'Turnover Margin',
  sacksPerGame: 'Sacks Per Game',
  explosivePlayRate: 'Explosive Play Rate',
  successRate: 'Success Rate',
  ppaOffense: 'Predicted Points Added (Off)',
  ppaDefense: 'Predicted Points Added (Def)',
  epa: 'Expected Points Added',
};

export const basketballStatLabels: Record<string, string> = {
  pointsPerGame: 'Points Per Game',
  pointsAllowedPerGame: 'Points Allowed Per Game',
  fieldGoalPct: 'Field Goal %',
  threePointPct: '3-Point %',
  freeThrowPct: 'Free Throw %',
  reboundsPerGame: 'Rebounds Per Game',
  assistsPerGame: 'Assists Per Game',
  turnoversPerGame: 'Turnovers Per Game',
  adjOffRating: 'Adjusted Offensive Rating',
  adjDefRating: 'Adjusted Defensive Rating',
  adjNetRating: 'Adjusted Net Rating',
  tempo: 'Possessions Per Game (Tempo)',
  effectiveFgPct: 'Effective FG %',
  turnoverRate: 'Turnover Rate',
  offReboundRate: 'Offensive Rebound Rate',
  freeThrowRate: 'Free Throw Rate',
  assistRate: 'Assist Rate',
};

/** Fan-friendly composite label definitions */
export const fanLabels = {
  football: {
    driveFinisher: {
      label: 'Drive Finisher',
      description: 'Red-zone efficiency + points per scoring opportunity',
      metrics: ['redZoneScorePct', 'pointsPerGame'],
    },
    bigPlaySpark: {
      label: 'Big Play Spark',
      description: 'Explosive play rate',
      metrics: ['explosivePlayRate'],
    },
    chaosFactor: {
      label: 'Chaos Factor',
      description: 'Sacks + turnovers forced + havoc events',
      metrics: ['sacksPerGame', 'turnoverMargin'],
    },
    ballSecurityGrade: {
      label: 'Ball Security Grade',
      description: 'Turnovers lost + fumbles + interceptions (lower = better)',
      metrics: ['turnoverMargin'],
    },
    gritIndex: {
      label: 'Grit Index',
      description: 'Rushing success rate + third/fourth-down conversion',
      metrics: ['successRate', 'thirdDownPct'],
    },
  },
  basketball: {
    shotQuality: {
      label: 'Shot Quality',
      description: 'eFG% combined with rim and 3-point attempt profile',
      metrics: ['effectiveFgPct'],
    },
    glassWork: {
      label: 'Glass Work',
      description: 'Offensive + defensive rebound rate',
      metrics: ['offReboundRate'],
    },
    tempoMeter: {
      label: 'Tempo Meter',
      description: 'Possessions per game',
      metrics: ['tempo'],
    },
    clutchMeter: {
      label: 'Clutch Meter',
      description: 'Net rating in close games',
      metrics: ['adjNetRating'],
    },
    paintPressure: {
      label: 'Paint Pressure',
      description: 'Rim attempts + free throw rate',
      metrics: ['freeThrowRate'],
    },
    ballMovement: {
      label: 'Ball Movement',
      description: 'Assist rate + assist/turnover ratio',
      metrics: ['assistRate'],
    },
  },
} as const;

export type FootballFanLabel = keyof typeof fanLabels.football;
export type BasketballFanLabel = keyof typeof fanLabels.basketball;
