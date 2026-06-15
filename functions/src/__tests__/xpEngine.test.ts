import { describe, it, expect } from 'vitest';
// Import from xpLogic (pure, no Firebase imports) so tests run without an emulator
import { levelForXp, XP_TABLE } from '../rewards/xpLogic';

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
  it('level 5 at 5999 XP', () => {
    expect(levelForXp(5999)).toBe(5);
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
  it('still level 25 at 200000 XP (highest defined)', () => {
    expect(levelForXp(200000)).toBe(25);
  });
  it('xp 1280 → level 3 (below 1500 threshold for L4)', () => {
    // seed data user has xp:1280, stored level:4 — that was written by a prior award;
    // the pure algorithm returns 3 since 1280 < 1500 (L4 threshold)
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
