import { describe, it, expect } from 'vitest';
// Import from xpLogic (pure, no Firebase imports) so tests run without an emulator
import { levelForXp, xpForLevel, computeXpAward, dailyCapKey, XP_TABLE } from '../rewards/xpLogic';

// The level curve must stay in EXACT parity with the Dart implementation at
// packages/stats_engine/dart/lib/src/shared/level_calc.dart: the doc-07 anchors
// {1:0, 2:250, 3:750, 4:1500, 5:3000, 10:15000, 25:100000} with linear
// interpolation (rounded) between anchors, levels clamped 1..25.
describe('xpForLevel (Dart level_calc parity)', () => {
  it('anchor levels return the doc-07 thresholds', () => {
    expect(xpForLevel(1)).toBe(0);
    expect(xpForLevel(2)).toBe(250);
    expect(xpForLevel(3)).toBe(750);
    expect(xpForLevel(4)).toBe(1500);
    expect(xpForLevel(5)).toBe(3000);
    expect(xpForLevel(10)).toBe(15000);
    expect(xpForLevel(25)).toBe(100000);
  });
  it('level 0 and below clamp to 0 XP', () => {
    expect(xpForLevel(0)).toBe(0);
    expect(xpForLevel(-3)).toBe(0);
  });
  it('interpolates linearly between anchors 5 and 10', () => {
    // 3000 + (15000-3000) * t, t in fifths
    expect(xpForLevel(6)).toBe(5400);
    expect(xpForLevel(7)).toBe(7800);
    expect(xpForLevel(8)).toBe(10200);
    expect(xpForLevel(9)).toBe(12600);
  });
  it('interpolates (rounded) between anchors 10 and 25', () => {
    // 15000 + (100000-15000) * t, t in fifteenths — rounds like Dart .round()
    expect(xpForLevel(11)).toBe(20667);
    expect(xpForLevel(24)).toBe(94333);
  });
  it('levels above 25 return the level-25 threshold', () => {
    expect(xpForLevel(26)).toBe(100000);
    expect(xpForLevel(100)).toBe(100000);
  });
});

describe('levelForXp', () => {
  it('level 1 at 0 XP', () => {
    expect(levelForXp(0)).toBe(1);
  });
  it('level 1 at 249 XP', () => {
    expect(levelForXp(249)).toBe(1);
  });
  it('level 2 at 250 XP', () => {
    expect(levelForXp(250)).toBe(2);
  });
  it('level 3 at 750 XP', () => {
    expect(levelForXp(750)).toBe(3);
  });
  it('level 4 at 1500 XP', () => {
    expect(levelForXp(1500)).toBe(4);
  });
  it('level 5 at 3000 XP', () => {
    expect(levelForXp(3000)).toBe(5);
  });
  it('level 5 at 5399 XP (just below interpolated L6)', () => {
    expect(levelForXp(5399)).toBe(5);
  });
  it('level 6 at 5400 XP (interpolated threshold)', () => {
    expect(levelForXp(5400)).toBe(6);
  });
  it('level 6 at 6000 XP', () => {
    expect(levelForXp(6000)).toBe(6);
  });
  it('level 10 at 15000 XP', () => {
    expect(levelForXp(15000)).toBe(10);
  });
  it('level 25 at 100000 XP', () => {
    expect(levelForXp(100000)).toBe(25);
  });
  it('still level 25 at 200000 XP (clamped to MAX_LEVEL)', () => {
    expect(levelForXp(200000)).toBe(25);
  });
  it('xp 1280 → level 3 (below 1500 threshold for L4)', () => {
    // seed data user has xp:1280 — the unified curve returns 3 since 1280 < 1500
    expect(levelForXp(1280)).toBe(3);
  });
  it('xp 1499 → level 3 (just below L4)', () => {
    expect(levelForXp(1499)).toBe(3);
  });
  it('xp 1500 → level 4 (exactly at L4 threshold)', () => {
    expect(levelForXp(1500)).toBe(4);
  });
  it('seed user xp 3120 → level 5', () => {
    expect(levelForXp(3120)).toBe(5);
  });
});

describe('XP_TABLE', () => {
  it('daily_open awards 5 XP', () => {
    expect(XP_TABLE.daily_open).toBe(5);
  });
  it('submit_prediction awards 10 XP', () => {
    expect(XP_TABLE.submit_prediction).toBe(10);
  });
  it('correct_prediction awards 20 XP', () => {
    expect(XP_TABLE.correct_prediction).toBe(20);
  });
  it('exact_score_bonus awards 100 XP', () => {
    expect(XP_TABLE.exact_score_bonus).toBe(100);
  });
  it('game_checkin awards 25 XP', () => {
    expect(XP_TABLE.game_checkin).toBe(25);
  });
  it('vote_poll awards 5 XP', () => {
    expect(XP_TABLE.vote_poll).toBe(5);
  });
});

describe('computeXpAward', () => {
  it('awards full table value for uncapped events', () => {
    const award = computeXpAward(['correct_prediction'], {});
    expect(award.xpAwarded).toBe(20);
    expect(award.cappedByDailyLimit).toBe(false);
    expect(award.capUsage).toEqual({});
  });
  it('sums a correct exact-score pick (correct_prediction + exact_score_bonus)', () => {
    const award = computeXpAward(['correct_prediction', 'exact_score_bonus'], {});
    expect(award.xpAwarded).toBe(120);
    expect(award.cappedByDailyLimit).toBe(false);
  });
  it('awards nothing for no events', () => {
    expect(computeXpAward([], {}).xpAwarded).toBe(0);
  });
  it('tracks cap usage for capped events', () => {
    const award = computeXpAward(['daily_open'], {});
    expect(award.xpAwarded).toBe(5);
    expect(award.capUsage).toEqual({ daily_open: 5 });
    expect(award.cappedByDailyLimit).toBe(false);
  });
  it('awards 0 when the daily cap is already spent', () => {
    const award = computeXpAward(['daily_open'], { daily_open: 5 });
    expect(award.xpAwarded).toBe(0);
    expect(award.cappedByDailyLimit).toBe(true);
    expect(award.capUsage).toEqual({});
  });
  it('partially awards up to the cap', () => {
    // vote_poll: 5 XP each, cap 15/day — 12 already used leaves room for 3
    const award = computeXpAward(['vote_poll'], { vote_poll: 12 });
    expect(award.xpAwarded).toBe(3);
    expect(award.cappedByDailyLimit).toBe(true);
    expect(award.capUsage).toEqual({ vote_poll: 3 });
  });
  it('caps repeated events within a single call', () => {
    const award = computeXpAward(['daily_open', 'daily_open'], {});
    expect(award.xpAwarded).toBe(5);
    expect(award.cappedByDailyLimit).toBe(true);
    expect(award.capUsage).toEqual({ daily_open: 5 });
  });
});

describe('dailyCapKey', () => {
  it('formats as YYYY-MM-DD', () => {
    expect(dailyCapKey()).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
  it('keys on the America/New_York day, not UTC', () => {
    // 2026-08-08T02:00Z is still Aug 7, 10pm in Kentucky (EDT) — the cap day
    // must NOT roll over mid-broadcast.
    expect(dailyCapKey(new Date('2026-08-08T02:00:00Z'))).toBe('2026-08-07');
  });
  it('matches the calendar day once Kentucky passes midnight', () => {
    expect(dailyCapKey(new Date('2026-08-08T05:00:00Z'))).toBe('2026-08-08');
  });
});
