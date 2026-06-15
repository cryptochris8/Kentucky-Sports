// Pure XP logic — no I/O, no Firebase imports.
// Imported by xpEngine.ts (Firestore writer) and by unit tests.

import type { XpEvent } from '@bluegrass/shared-models';

// XP amounts per event (doc 07)
export const XP_TABLE: Record<XpEvent, number> = {
  daily_open: 5,
  vote_poll: 5,
  submit_prediction: 10,
  correct_prediction: 20,
  exact_score_bonus: 100,
  comment_approved: 5,
  game_checkin: 25,
  watch_party_checkin: 25,
  read_stat_explainer: 5,
  follow_team: 5,
};

// Daily caps for low-value repeated actions
export const DAILY_CAPS: Partial<Record<XpEvent, number>> = {
  daily_open: 5,         // once per day
  vote_poll: 15,         // up to 3 polls/day
  read_stat_explainer: 25, // up to 5/day
  follow_team: 10,       // up to 2 follows/day
};

// Level thresholds (doc 07) — sorted ascending, [level, minXp]
export const LEVEL_THRESHOLDS: [number, number][] = [
  [1, 0],
  [2, 250],
  [3, 750],
  [4, 1500],
  [5, 3000],
  [6, 6000],
  [7, 10000],
  [8, 12000],
  [9, 14000],
  [10, 15000],
  [25, 100000],
];

/** Compute level from total XP */
export function levelForXp(xp: number): number {
  let level = 1;
  for (const [lvl, threshold] of LEVEL_THRESHOLDS) {
    if (xp >= threshold) {
      level = lvl;
    } else {
      break;
    }
  }
  return level;
}
