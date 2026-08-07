// Pure prediction scoring logic — no I/O, no Firebase imports.
// Imported by scoring.ts (Firestore writer) and by unit tests.

import type { PredictionEntry, Prediction, PredictionType, XpEvent } from '@bluegrass/shared-models';

// Points awarded per prediction type (per doc 06)
export const BASE_POINTS: Record<PredictionType, number> = {
  winner: 10,
  margin_bucket: 15,
  exact_score: 50,
  threes_range: 15,
  leading_scorer: 15,
  stat_over_under: 10,
  upset_pick: 20,
};

/** Pure function: determines points awarded for a single entry */
export function computePoints(type: PredictionType, isCorrect: boolean): number {
  if (!isCorrect) return 0;
  return BASE_POINTS[type] ?? 10;
}

/**
 * Pure function: the XP events a scored entry earns (doc 07).
 * A correct pick earns correct_prediction; a correct exact-score pick
 * additionally earns exact_score_bonus. Incorrect picks earn nothing.
 */
export function xpEventsForEntry(type: PredictionType, isCorrect: boolean): XpEvent[] {
  if (!isCorrect) return [];
  const events: XpEvent[] = ['correct_prediction'];
  if (type === 'exact_score') events.push('exact_score_bonus');
  return events;
}

/** Pure function: determines if a pick is correct */
export function isEntryCorrect(
  entry: Pick<PredictionEntry, 'selectedOptionId' | 'numericValue'>,
  prediction: Pick<Prediction, 'correctOptionId' | 'type'>,
): boolean {
  if (!prediction.correctOptionId) return false;
  return entry.selectedOptionId === prediction.correctOptionId;
}
