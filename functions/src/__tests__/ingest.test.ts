/**
 * Unit tests for ingest normalization logic.
 * These are pure function tests — no Firebase / HTTP calls are made.
 */
import { describe, it, expect } from 'vitest';
import type { CfbdGameDto, CfbdTeamStatDto } from '../ingest/providers/cfbdClient';
import type { CbbdGameDto, CbbdTeamMetricsDto } from '../ingest/providers/cbbdClient';
import { normalizeCfbdGame, normalizeCfbdTeamStat } from '../ingest/providers/cfbdClient';
import { normalizeCbbdGame, normalizeCbbdTeamStat } from '../ingest/providers/cbbdClient';

// ── CFBD game normalization ──────────────────────────────────────────────────

describe('normalizeCfbdGame', () => {
  const baseCfbdGame: CfbdGameDto = {
    id: 401628000,
    season: 2026,
    home_team: 'Kentucky',
    away_team: 'Youngstown State',
    start_date: '2026-09-05T23:00:00.000Z',
    venue: 'Kroger Field',
    completed: false,
    home_points: null,
    away_points: null,
    status: 'scheduled',
  };

  it('maps source to "cfbd"', () => {
    expect(normalizeCfbdGame(baseCfbdGame).source).toBe('cfbd');
  });

  it('maps sport to "football"', () => {
    expect(normalizeCfbdGame(baseCfbdGame).sport).toBe('football');
  });

  it('maps sourceGameId to string id', () => {
    expect(normalizeCfbdGame(baseCfbdGame).sourceGameId).toBe('401628000');
  });

  it('maps homeTeamName and awayTeamName', () => {
    const g = normalizeCfbdGame(baseCfbdGame);
    expect(g.homeTeamName).toBe('Kentucky');
    expect(g.awayTeamName).toBe('Youngstown State');
  });

  it('maps status = scheduled when completed=false and no status override', () => {
    expect(normalizeCfbdGame({ ...baseCfbdGame, status: undefined }).status).toBe('scheduled');
  });

  it('maps status = final when completed=true', () => {
    expect(normalizeCfbdGame({ ...baseCfbdGame, completed: true }).status).toBe('final');
  });

  it('maps status = live when status is in_progress', () => {
    expect(
      normalizeCfbdGame({ ...baseCfbdGame, completed: false, status: 'in_progress' }).status,
    ).toBe('live');
  });

  it('maps homeScore and awayScore when present', () => {
    const g = normalizeCfbdGame({ ...baseCfbdGame, completed: true, home_points: 20, away_points: 13 });
    expect(g.homeScore).toBe(20);
    expect(g.awayScore).toBe(13);
    expect(g.status).toBe('final');
  });

  it('leaves homeScore undefined when null', () => {
    expect(normalizeCfbdGame(baseCfbdGame).homeScore).toBeUndefined();
  });
});

// ── CFBD team stat normalization ─────────────────────────────────────────────

describe('normalizeCfbdTeamStat', () => {
  const baseDto: CfbdTeamStatDto = {
    team: 'Kentucky',
    points_per_game: 29.4,
    passing_yards: 248,
    rushing_yards: 171,
    third_down_conversions: 42,
    third_down_attempts: 100,
    red_zone_scores: 18,
    red_zone_attempts: 21,
    sacks: 2.4,
  };

  it('sets teamId to kentucky_football', () => {
    expect(normalizeCfbdTeamStat(baseDto, 2025).teamId).toBe('kentucky_football');
  });

  it('sets source to cfbd', () => {
    expect(normalizeCfbdTeamStat(baseDto, 2025).source).toBe('cfbd');
  });

  it('computes thirdDownPct as conversions / attempts', () => {
    const stat = normalizeCfbdTeamStat(baseDto, 2025);
    expect(stat.stats['thirdDownPct']).toBeCloseTo(0.42, 5);
  });

  it('computes redZoneScorePct as scores / attempts', () => {
    const stat = normalizeCfbdTeamStat(baseDto, 2025);
    expect(stat.stats['redZoneScorePct']).toBeCloseTo(18 / 21, 5);
  });

  it('returns null thirdDownPct when attempts is 0', () => {
    const stat = normalizeCfbdTeamStat({ ...baseDto, third_down_attempts: 0 }, 2025);
    expect(stat.stats['thirdDownPct']).toBeNull();
  });

  it('passes through pointsPerGame', () => {
    expect(normalizeCfbdTeamStat(baseDto, 2025).stats['pointsPerGame']).toBe(29.4);
  });
});

// ── CBBD game normalization ──────────────────────────────────────────────────

describe('normalizeCbbdGame', () => {
  const baseCbbdGame: CbbdGameDto = {
    id: 'cbbd-2026-01',
    season: 2026,
    homeTeam: 'Kentucky',
    awayTeam: 'Duke',
    startDate: '2026-11-10T02:30:00.000Z',
    arena: 'Rupp Arena',
    status: 'Scheduled',
  };

  it('maps source to "cbbd"', () => {
    expect(normalizeCbbdGame(baseCbbdGame).source).toBe('cbbd');
  });

  it('maps sport to "mens_basketball"', () => {
    expect(normalizeCbbdGame(baseCbbdGame).sport).toBe('mens_basketball');
  });

  it('maps status = scheduled for unknown/Scheduled value', () => {
    expect(normalizeCbbdGame(baseCbbdGame).status).toBe('scheduled');
  });

  it('maps status = final', () => {
    expect(normalizeCbbdGame({ ...baseCbbdGame, status: 'Final' }).status).toBe('final');
  });

  it('maps status = live for InProgress', () => {
    expect(normalizeCbbdGame({ ...baseCbbdGame, status: 'InProgress' }).status).toBe('live');
  });
});

// ── CBBD team metrics normalization ──────────────────────────────────────────

describe('normalizeCbbdTeamStat', () => {
  const baseDto: CbbdTeamMetricsDto = {
    team: 'Kentucky',
    season: 2026,
    adjOE: 118.6,
    adjDE: 96.4,
    adjNetRating: 22.2,
    tempo: 70.3,
    effectiveFGPct: 0.552,
    turnoverRate: 0.151,
    offReboundRate: 0.341,
    freeThrowRate: 0.362,
    pointsPerGame: 84.2,
    pointsAllowedPerGame: 71.8,
  };

  it('sets teamId to kentucky_mens_basketball', () => {
    expect(normalizeCbbdTeamStat(baseDto, 2026).teamId).toBe('kentucky_mens_basketball');
  });

  it('maps adjOffRating from adjOE', () => {
    expect(normalizeCbbdTeamStat(baseDto, 2026).stats['adjOffRating']).toBe(118.6);
  });

  it('maps effectiveFgPct', () => {
    expect(normalizeCbbdTeamStat(baseDto, 2026).stats['effectiveFgPct']).toBe(0.552);
  });

  it('sets source to cbbd', () => {
    expect(normalizeCbbdTeamStat(baseDto, 2026).source).toBe('cbbd');
  });

  it('returns null for missing fields', () => {
    const stat = normalizeCbbdTeamStat({ team: 'Kentucky' }, 2026);
    expect(stat.stats['adjOffRating']).toBeNull();
    expect(stat.stats['tempo']).toBeNull();
  });
});
