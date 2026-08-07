// Pure XP logic — no I/O, no Firebase imports.
// Imported by xpEngine.ts / scoring.ts (Firestore writers) and by unit tests.
//
// The level curve MUST stay in exact parity with the Dart implementation at
// packages/stats_engine/dart/lib/src/shared/level_calc.dart — both interpolate
// the same doc-07 anchor thresholds so the app and backend agree on levels.

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

/** Highest defined level (doc 07). */
export const MAX_LEVEL = 25;

/** Anchor thresholds from docs/07 (level -> cumulative XP required). */
const ANCHOR_THRESHOLDS: ReadonlyMap<number, number> = new Map([
  [1, 0],
  [2, 250],
  [3, 750],
  [4, 1500],
  [5, 3000],
  [10, 15000],
  [25, 100000],
]);

const ANCHOR_LEVELS: readonly number[] = [...ANCHOR_THRESHOLDS.keys()].sort((a, b) => a - b);

/**
 * Returns the cumulative XP required to reach `level` (1-based).
 * Levels between anchor points are linearly interpolated and rounded
 * (mirrors level_calc.dart `xpForLevel`).
 */
export function xpForLevel(level: number): number {
  if (level <= 1) return 0;
  const anchor = ANCHOR_THRESHOLDS.get(level);
  if (anchor !== undefined) return anchor;

  const last = ANCHOR_LEVELS[ANCHOR_LEVELS.length - 1];
  if (level > last) return ANCHOR_THRESHOLDS.get(last)!;

  // Find the surrounding anchor levels and interpolate.
  let lower = ANCHOR_LEVELS[0];
  let upper = last;
  for (let i = 0; i < ANCHOR_LEVELS.length - 1; i++) {
    if (level > ANCHOR_LEVELS[i] && level < ANCHOR_LEVELS[i + 1]) {
      lower = ANCHOR_LEVELS[i];
      upper = ANCHOR_LEVELS[i + 1];
      break;
    }
  }

  const lowerXp = ANCHOR_THRESHOLDS.get(lower)!;
  const upperXp = ANCHOR_THRESHOLDS.get(upper)!;
  const t = (level - lower) / (upper - lower);
  return Math.round(lowerXp + (upperXp - lowerXp) * t);
}

/** Computes the level (clamped 1..MAX_LEVEL) for a given XP total. */
export function levelForXp(xp: number): number {
  let level = 1;
  for (let candidate = 1; candidate <= MAX_LEVEL; candidate++) {
    if (xp >= xpForLevel(candidate)) {
      level = candidate;
    } else {
      break;
    }
  }
  return level;
}

/**
 * The daily-cap document key: today's date (YYYY-MM-DD) in America/New_York,
 * matching the product's Kentucky audience and the scheduled functions'
 * timezone — NOT UTC, which would roll the "day" over mid-evening.
 */
export function dailyCapKey(date: Date = new Date()): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'America/New_York' }).format(date);
}

export interface XpAwardComputation {
  /** Total XP to add to the user after applying daily caps. */
  xpAwarded: number;
  /** Per-event increments to merge into today's cap document. */
  capUsage: Partial<Record<XpEvent, number>>;
  /** True when at least one event was reduced by a daily cap. */
  cappedByDailyLimit: boolean;
}

/**
 * Pure computation of an XP award for one or more events, given today's
 * cap usage. Shared by awardXp and the prediction scoring transaction.
 */
export function computeXpAward(
  events: readonly XpEvent[],
  usedToday: Partial<Record<XpEvent, number>>,
): XpAwardComputation {
  let xpAwarded = 0;
  let cappedByDailyLimit = false;
  const capUsage: Partial<Record<XpEvent, number>> = {};
  const used: Partial<Record<XpEvent, number>> = { ...usedToday };

  for (const event of events) {
    const amount = XP_TABLE[event] ?? 0;
    if (amount === 0) continue;

    const cap = DAILY_CAPS[event];
    let award = amount;
    if (cap !== undefined) {
      const already = used[event] ?? 0;
      award = Math.max(0, Math.min(amount, cap - already));
      if (award < amount) cappedByDailyLimit = true;
      if (award > 0) {
        used[event] = already + award;
        capUsage[event] = (capUsage[event] ?? 0) + award;
      }
    }
    xpAwarded += award;
  }

  return { xpAwarded, capUsage, cappedByDailyLimit };
}
