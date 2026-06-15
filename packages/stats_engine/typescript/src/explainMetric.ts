// Metric explanation template engine

export interface MetricExplanationParams {
  metricName: string;
  metricLabel: string;
  value: number;
  unit?: string;
  rank?: number;
  totalTeams?: number;
  secRank?: number;
  opponentName?: string;
  opponentRank?: number;
  playerOrUnit?: string;
  plainMeaning: string;
}

/**
 * Generates a fan-friendly stat explanation string.
 * Uses a controlled template — no open-ended AI in Phase 1.
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

  let explanation = `Kentucky's biggest statistical edge is **${metricLabel}**. `;

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
    explanation += `Watch for **${playerOrUnit}** to be important in this area.`;
  }

  return explanation;
}
