/**
 * Unit tests for ingest normalization logic.
 * These are pure function tests — no Firebase / HTTP calls are made.
 */
import { describe, it, expect } from 'vitest';
import type { CfbdGameDto, CfbdTeamStatDto } from '../ingest/providers/cfbdClient';
import type { CbbdGameDto, CbbdTeamMetricsDto } from '../ingest/providers/cbbdClient';
import { normalizeCfbdGame, normalizeCfbdTeamStat } from '../ingest/providers/cfbdClient';
import { normalizeCbbdGame, normalizeCbbdTeamStat } from '../ingest/providers/cbbdClient';
import {
  deriveKentuckySide,
  gameDayKey,
  gameMatchKey,
  hasAnyStatValue,
  isKentuckyTeamName,
  opponentTeamId,
} from '../ingest/persistLogic';

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

// ── Persist matching logic (curated-doc dedupe) ──────────────────────────────

describe('isKentuckyTeamName', () => {
  it('matches "Kentucky" regardless of case/whitespace', () => {
    expect(isKentuckyTeamName('Kentucky')).toBe(true);
    expect(isKentuckyTeamName('  kentucky ')).toBe(true);
  });

  it('never matches other Kentucky schools', () => {
    expect(isKentuckyTeamName('Western Kentucky')).toBe(false);
    expect(isKentuckyTeamName('Eastern Kentucky')).toBe(false);
    expect(isKentuckyTeamName('Kentucky State')).toBe(false);
  });
});

describe('deriveKentuckySide', () => {
  it('detects a home game and names the opponent', () => {
    const side = deriveKentuckySide({ homeTeamName: 'Kentucky', awayTeamName: 'Youngstown State' });
    expect(side).toEqual({ isHome: true, opponentName: 'Youngstown State' });
  });

  it('detects an away game', () => {
    const side = deriveKentuckySide({ homeTeamName: 'Texas A&M', awayTeamName: 'Kentucky' });
    expect(side).toEqual({ isHome: false, opponentName: 'Texas A&M' });
  });

  it('returns null when neither side is Kentucky', () => {
    expect(deriveKentuckySide({ homeTeamName: 'Duke', awayTeamName: 'Louisville' })).toBeNull();
  });
});

describe('gameDayKey / gameMatchKey', () => {
  it('extracts the Eastern-time day from an ISO string', () => {
    expect(gameDayKey('2026-09-05T23:00:00.000Z')).toBe('2026-09-05');
    // Seed docs carry an offset — same instant, same ET day
    expect(gameDayKey('2026-09-05T19:00:00-04:00')).toBe('2026-09-05');
  });

  it('keeps an evening ET tip on the ET calendar day (not the UTC rollover day)', () => {
    // 9:30pm EST on Nov 9 is already Nov 10 in UTC — the key must stay Nov 9.
    expect(gameDayKey('2026-11-10T02:30:00.000Z')).toBe('2026-11-09');
  });

  it('handles Firestore Timestamp-like objects', () => {
    const ts = { toDate: () => new Date('2026-11-10T02:30:00.000Z') };
    expect(gameDayKey(ts)).toBe('2026-11-09');
  });

  it('returns null for unparseable values', () => {
    expect(gameDayKey('not a date')).toBeNull();
    expect(gameDayKey(undefined)).toBeNull();
    expect(gameDayKey(null)).toBeNull();
  });

  it('builds the same match key from a curated doc and a provider row', () => {
    // Curated seed doc: startTime "2026-09-05T19:00:00-04:00", opponent "Youngstown State"
    const curated = gameMatchKey('football', '2026-09-05T19:00:00-04:00', 'Youngstown State');
    // CFBD row: start_date "2026-09-05T23:00:00.000Z", away_team "Youngstown State"
    const provider = gameMatchKey('football', '2026-09-05T23:00:00.000Z', 'youngstown state');
    expect(curated).toBe('football|2026-09-05|youngstown state');
    expect(provider).toBe(curated);
  });

  it('matches a 7:30pm ET kickoff to the curated timeTbd doc for that ET day', () => {
    // Curated seed doc (fb_2026_tennessee): timeTbd placeholder on the ET calendar day
    const curated = gameMatchKey('football', '2026-11-07T15:30:00-05:00', 'Tennessee');
    // CFBD announces the real kickoff: 7:30pm EST = 2026-11-08T00:30Z — a UTC day
    // key would put this on Nov 8 and mint a duplicate game.
    const provider = gameMatchKey('football', '2026-11-07T19:30:00-05:00', 'tennessee');
    expect(curated).toBe('football|2026-11-07|tennessee');
    expect(provider).toBe(curated);
  });
});

describe('opponentTeamId', () => {
  it('slugs opponents to the seed convention', () => {
    expect(opponentTeamId('Youngstown State')).toBe('opp_youngstown_state');
    expect(opponentTeamId('Texas A&M')).toBe('opp_texas_am');
    expect(opponentTeamId('LSU')).toBe('opp_lsu');
  });
});

describe('hasAnyStatValue', () => {
  it('true when at least one stat is present', () => {
    expect(hasAnyStatValue({ pointsPerGame: 29.4, totalYards: null })).toBe(true);
    expect(hasAnyStatValue({ label: 'ok' })).toBe(true);
  });

  it('false for an all-null payload (must not be persisted as official)', () => {
    expect(hasAnyStatValue({ pointsPerGame: null, totalYards: null })).toBe(false);
    expect(hasAnyStatValue({})).toBe(false);
  });
});
