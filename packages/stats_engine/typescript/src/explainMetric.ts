// Metric explanation template engine
//
// PARITY: the verdict phrasing ("Kentucky holds the edge in X." / "X has the
// edge in Y." / "Kentucky and X are even in Y.") is mirrored word-for-word in
// the Dart twin's buildStatStory
// (packages/stats_engine/dart/lib/src/shared/explain_metric.dart).
// Change one side only in lockstep with the other.

export interface MetricExplanationParams {
  metricName: string;
  metricLabel: string;
  value: number;
  unit?: string;
  /** National rank (1 = best). */
  rank?: number;
  totalTeams?: number;
  /** SEC rank (1 = best). */
  secRank?: number;
  opponentName?: string;
  /** Opponent's rank on the same scale as secRank/rank (1 = best). */
  opponentRank?: number;
  playerOrUnit?: string;
  plainMeaning: string;
}

/**
 * Generates a fan-friendly stat explanation string.
 * Uses a controlled template — no open-ended AI in Phase 1.
 *
 * The lede is honest: an edge is only claimed when the ranks in hand prove one
 * (lower rank number = better). With no opponent comparison the opener stays
 * neutral — never an unconditional "biggest statistical edge" superlative.
 */
export function explainMetric(params: MetricExplanationParams): string {
  const {
    metricLabel,
    rank,
    totalTeams,
    secRank,
    opponentName,
    opponentRank,
    playerOrUnit,
    plainMeaning,
  } = params;

  const kentuckyRank = secRank ?? rank;

  let explanation: string;
  if (opponentName && opponentRank !== undefined && kentuckyRank !== undefined) {
    if (kentuckyRank < opponentRank) {
      explanation = `Kentucky holds the edge in ${metricLabel}. `;
    } else if (kentuckyRank > opponentRank) {
      explanation = `${opponentName} has the edge in ${metricLabel}. `;
    } else {
      explanation = `Kentucky and ${opponentName} are even in ${metricLabel}. `;
    }
  } else {
    explanation = `${metricLabel} is one to watch in this matchup. `;
  }

  if (secRank !== undefined) {
    explanation += `The Cats rank #${secRank} in the SEC`;
    if (opponentName && opponentRank !== undefined) {
      explanation += ` while ${opponentName} ranks #${opponentRank}`;
    }
    explanation += '. ';
  } else if (rank !== undefined && totalTeams !== undefined) {
    explanation += `The Cats rank #${rank} out of ${totalTeams} teams nationally`;
    if (opponentName && opponentRank !== undefined) {
      explanation += ` while ${opponentName} ranks #${opponentRank}`;
    }
    explanation += '. ';
  }

  explanation += `In plain English, this means ${plainMeaning}. `;

  if (playerOrUnit) {
    explanation += `Watch for ${playerOrUnit} to be important in this area.`;
  }

  return explanation;
}
