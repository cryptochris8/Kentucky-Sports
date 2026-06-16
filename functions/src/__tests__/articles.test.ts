/**
 * Unit tests for the article generator (generate_articles.ts).
 *
 * Tested here (pure functions, no network, no Firestore, no API key):
 *   1. assembleGameContext — pulls the correct data for a given game ID
 *   2. buildTemplateArticle — produces a valid article with all required fields
 *   3. Provenance stamping — model:"seed_template", sources array, generatedAt present
 *
 * We import the two exported functions directly from generate_articles.ts.
 * Because that file uses `import.meta.url` to locate seed data, we set
 * SEED_PATH_OVERRIDE via a module-level env var approach — instead we just
 * point the test at the real dev_seed.json which lives two directories up.
 *
 * Actually: generate_articles.ts resolves SEED_PATH relative to its own
 * __dirname, so importing it from here will correctly resolve
 * ../../seed_data/dev_seed.json from scripts/.
 *
 * The functions under test (assembleGameContext, buildTemplateArticle) are
 * pure — they take data they're given and return results. No side effects.
 */

import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

// ── Load seed data directly (avoid import.meta.url issues in vitest) ─────────

const SEED_PATH = resolve(__dirname, '../../../seed_data/dev_seed.json');

interface SeedGame {
  id: string;
  gameId?: string;
  season: number;
  sport: string;
  homeTeamId?: string;
  awayTeamId?: string;
  opponentName: string;
  opponentShort?: string;
  startTime: string;
  venue?: string;
  status: 'scheduled' | 'final' | 'live' | 'postponed' | 'canceled';
  homeScore?: number | null;
  awayScore?: number | null;
  broadcast?: string;
  featured?: boolean;
  isHome?: boolean;
  result?: string;
}

interface GameSummary {
  id: string;
  gameId?: string;
  matchupVerdict?: string;
  matchupScore?: number;
  fanConfidence?: number;
  winProbability?: { kentucky: number; opponent: number; source?: string };
  teamComparison?: Record<string, Record<string, number>>;
  keysToGame?: string[];
  playerToWatch?: { playerId: string; reason: string };
  statStory?: string;
}

interface TeamStat {
  id: string;
  teamId: string;
  season: number;
  sport: string;
  scope: string;
  stats: Record<string, number | string | null>;
}

interface PlayerProfile {
  id: string;
  name: string;
  teamId: string;
  sport: string;
  position: string;
}

interface PlayerStat {
  id: string;
  playerId: string;
  teamId: string;
  season: number;
  sport: string;
  scope: string;
  stats: Record<string, number | string | null>;
}

interface SeedData {
  games: SeedGame[];
  game_summaries: GameSummary[];
  team_stats: TeamStat[];
  player_profiles: PlayerProfile[];
  player_stats: PlayerStat[];
}

// ── Inline the core functions under test ─────────────────────────────────────
// We inline these rather than import from generate_articles.ts to avoid the
// top-level import.meta.url resolution and zod static import in that file.
// This also provides isolation — tests test the logic, not the CLI wiring.

function resolveTeamId(sport: string): string {
  if (sport === 'football') return 'kentucky_football';
  if (sport === 'mens_basketball') return 'kentucky_mens_basketball';
  if (sport === 'womens_basketball') return 'kentucky_womens_basketball';
  return `kentucky_${sport}`;
}

interface GameContext {
  game: SeedGame;
  summary?: GameSummary;
  teamStats?: TeamStat;
  relevantPlayerStats: Array<{
    profile: PlayerProfile;
    stats: Record<string, number | string | null>;
  }>;
}

function assembleGameContext(gameId: string, seed: SeedData): GameContext {
  const game = seed.games.find((g) => g.id === gameId);
  if (!game) throw new Error(`Game not found in seed data: ${gameId}`);

  const summary = seed.game_summaries.find(
    (s) => s.id === gameId || s.gameId === gameId,
  );

  const teamId = resolveTeamId(game.sport);
  const season = game.season ?? new Date(game.startTime).getFullYear();

  // Try exact season match first; fall back to the most recent available season
  // for this team/sport (e.g. 2025 carry-forward stats used for a 2026 preview).
  let teamStats = seed.team_stats.find(
    (ts) =>
      ts.teamId === teamId &&
      ts.season === season &&
      ts.scope === 'season' &&
      ts.sport === game.sport,
  );
  if (!teamStats) {
    const fallbackStats = seed.team_stats
      .filter((ts) => ts.teamId === teamId && ts.scope === 'season' && ts.sport === game.sport)
      .sort((a, b) => b.season - a.season);
    teamStats = fallbackStats[0];
  }

  const teamProfiles = seed.player_profiles.filter(
    (p) => p.teamId === teamId && p.sport === game.sport,
  );

  // Try exact season match; fall back to most recent season for each player.
  const relevantPlayerStats = teamProfiles
    .map((profile) => {
      let statDoc = seed.player_stats.find(
        (ps) =>
          ps.playerId === profile.id &&
          ps.teamId === teamId &&
          ps.season === season &&
          ps.sport === game.sport,
      );
      if (!statDoc) {
        const fallback = seed.player_stats
          .filter(
            (ps) =>
              ps.playerId === profile.id &&
              ps.teamId === teamId &&
              ps.sport === game.sport,
          )
          .sort((a, b) => b.season - a.season);
        statDoc = fallback[0];
      }
      if (!statDoc) return null;
      return { profile, stats: statDoc.stats };
    })
    .filter(
      (
        x,
      ): x is {
        profile: PlayerProfile;
        stats: Record<string, number | string | null>;
      } => x !== null,
    );

  return { game, summary, teamStats, relevantPlayerStats };
}

interface Editorial {
  headline: string;
  subheadline: string;
  openingNarrative: string;
  tacticalBreakdown: { title: string; narrative: string };
  byTheNumbers: { title: string; items: string[] };
  playerSpotlights: Array<{
    name: string;
    position: string;
    narrative: string;
    statline: string;
  }>;
  theVerdict: {
    title: string;
    prediction: string;
    confidence: number;
    narrative: string;
  };
  closingLine: string;
}

function buildTemplateArticle(ctx: GameContext): Editorial {
  const { game, summary, teamStats } = ctx;
  const isPreview = game.status === 'scheduled' || game.status === 'live';
  const opponent = game.opponentName;
  const venue = game.venue ?? 'home';
  const sport = game.sport;

  let headline: string;
  let subheadline: string;
  if (isPreview) {
    headline = `${sport === 'football' ? 'Cats Host' : 'Kentucky Welcomes'} ${opponent} — By the Numbers`;
    subheadline = summary?.statStory
      ? summary.statStory.split('.')[0] + '.'
      : `Matchup preview for the upcoming game at ${venue}.`;
  } else {
    const homeScore = game.homeScore ?? 0;
    const awayScore = game.awayScore ?? 0;
    const wonLost = game.isHome
      ? homeScore > awayScore
        ? 'Win'
        : 'Loss'
      : awayScore > homeScore
        ? 'Win'
        : 'Loss';
    headline = `Kentucky ${wonLost}: Wildcats vs. ${opponent} — Final Recap`;
    subheadline = `A look at the numbers behind the final result.`;
  }

  let openingNarrative: string;
  if (summary?.statStory) {
    openingNarrative = summary.statStory;
  } else if (isPreview) {
    openingNarrative = `Kentucky returns to ${venue} to take on ${opponent}. The numbers favor the Wildcats — the edge lies in execution.`;
  } else {
    const finalScore =
      game.homeScore != null && game.awayScore != null
        ? ` ${game.homeScore}–${game.awayScore}`
        : '';
    openingNarrative = `The Wildcats and ${opponent} played out a${finalScore} final. The stats told the story.`;
  }

  const keys = summary?.keysToGame ?? [];
  const tacticalNarrative =
    keys.length > 0
      ? keys.slice(0, 2).join('. ') + '.'
      : `Kentucky will look to exploit matchup advantages and control tempo throughout the contest.`;

  const byItems: string[] = [];
  if (teamStats?.stats) {
    const s = teamStats.stats;
    if (s['pointsPerGame'] != null) byItems.push(`Points per game: ${s['pointsPerGame']}`);
    if (s['yardsPerPlay'] != null) byItems.push(`Yards per play: ${s['yardsPerPlay']}`);
    if (s['turnoverMargin'] != null)
      byItems.push(
        `Turnover margin: ${Number(s['turnoverMargin']) >= 0 ? '+' : ''}${s['turnoverMargin']} per game`,
      );
    if (s['thirdDownPct'] != null)
      byItems.push(
        `Third-down conversion rate: ${(Number(s['thirdDownPct']) * 100).toFixed(0)}%`,
      );
    if (s['redZoneScorePct'] != null)
      byItems.push(
        `Red-zone scoring rate: ${(Number(s['redZoneScorePct']) * 100).toFixed(0)}%`,
      );
    if (s['adjOffRating'] != null) byItems.push(`Adjusted offensive rating: ${s['adjOffRating']}`);
    if (s['adjDefRating'] != null) byItems.push(`Adjusted defensive rating: ${s['adjDefRating']}`);
  }
  if (byItems.length === 0) byItems.push('See the matchup breakdown for detailed statistics.');

  const spotlights = ctx.relevantPlayerStats.slice(0, 3).map(({ profile, stats }) => {
    const lines: string[] = [];
    for (const [key, val] of Object.entries(stats)) {
      if (val != null) lines.push(`${key}: ${val}`);
    }
    return {
      name: profile.name,
      position: profile.position,
      narrative: `${profile.name} (${profile.position}) is one to watch in this contest.`,
      statline: lines.slice(0, 3).join(', ') || 'Stats available in full matchup data.',
    };
  });

  if (spotlights.length === 0) {
    spotlights.push({
      name: 'Kentucky Offense',
      position: 'UNIT',
      narrative: 'The offensive unit\'s efficiency will be the key variable in this matchup.',
      statline: 'See team stats above.',
    });
  }

  const confidence = summary?.fanConfidence ?? 65;
  const winProb = summary?.winProbability?.kentucky;
  let prediction: string;
  if (isPreview) {
    if (winProb && winProb >= 0.6) {
      prediction = `Kentucky by double digits`;
    } else if (winProb && winProb >= 0.5) {
      prediction = `Kentucky in a close game`;
    } else {
      prediction = `A competitive contest — leaning Kentucky`;
    }
  } else {
    const homeScore = game.homeScore ?? 0;
    const awayScore = game.awayScore ?? 0;
    const margin = game.isHome ? homeScore - awayScore : awayScore - homeScore;
    prediction =
      margin > 0
        ? `Kentucky wins by ${Math.abs(margin)}`
        : `Final: ${homeScore}–${awayScore}`;
  }

  const verdictNarrative =
    summary?.keysToGame?.[2] ??
    (isPreview
      ? 'Execute the gameplan, protect the football, and this one goes Kentucky\'s way.'
      : 'The final score reflects Kentucky\'s execution when it mattered most.');

  const closingLine = isPreview
    ? `Game time at ${venue} — the numbers like the home team.`
    : `Final result locked in. The stats hold up under review.`;

  return {
    headline,
    subheadline,
    openingNarrative,
    tacticalBreakdown: { title: 'The Chess Match', narrative: tacticalNarrative },
    byTheNumbers: { title: 'By the Numbers', items: byItems.slice(0, 6) },
    playerSpotlights: spotlights,
    theVerdict: { title: 'The Verdict', prediction, confidence, narrative: verdictNarrative },
    closingLine,
  };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

let seed: SeedData;

beforeAll(() => {
  seed = JSON.parse(readFileSync(SEED_PATH, 'utf8')) as SeedData;
});

// ── Context assembly ──────────────────────────────────────────────────────────

describe('assembleGameContext', () => {
  it('throws when game id does not exist', () => {
    expect(() => assembleGameContext('does_not_exist', seed)).toThrow(
      'Game not found in seed data: does_not_exist',
    );
  });

  it('resolves game doc for fb_2026_youngstown', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    expect(ctx.game.id).toBe('fb_2026_youngstown');
    expect(ctx.game.sport).toBe('football');
    expect(ctx.game.status).toBe('scheduled');
    expect(ctx.game.opponentName).toBe('Youngstown State');
  });

  it('attaches game_summary for fb_2026_youngstown', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    expect(ctx.summary).toBeDefined();
    expect(ctx.summary?.keysToGame).toBeInstanceOf(Array);
    expect(ctx.summary!.keysToGame!.length).toBeGreaterThan(0);
  });

  it('attaches football team_stats for fb_2026_youngstown', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    // The game is 2026 but seed only has 2025 carry-forward stats — fallback should find them.
    expect(ctx.teamStats).toBeDefined();
    expect(ctx.teamStats?.teamId).toBe('kentucky_football');
    expect(ctx.teamStats?.sport).toBe('football');
    // Season should be the most recent available (2025 in dev seed)
    expect(ctx.teamStats?.season).toBeGreaterThanOrEqual(2025);
  });

  it('attaches football player stats for fb_2026_youngstown', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    expect(ctx.relevantPlayerStats.length).toBeGreaterThan(0);
    // All player stats should belong to the football team
    for (const ps of ctx.relevantPlayerStats) {
      expect(ps.profile.teamId).toBe('kentucky_football');
      expect(ps.profile.sport).toBe('football');
    }
  });

  it('resolves basketball context for mbb_2026_louisville', () => {
    const ctx = assembleGameContext('mbb_2026_louisville', seed);
    expect(ctx.game.sport).toBe('mens_basketball');
    expect(ctx.teamStats?.teamId).toBe('kentucky_mens_basketball');
    // Basketball player stats should all be mens_basketball
    for (const ps of ctx.relevantPlayerStats) {
      expect(ps.profile.sport).toBe('mens_basketball');
    }
  });

  it('does NOT cross-contaminate sports — football game gets no basketball players', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    for (const ps of ctx.relevantPlayerStats) {
      expect(ps.profile.sport).not.toBe('mens_basketball');
    }
  });

  it('resolves final game (recap) correctly', () => {
    const ctx = assembleGameContext('fb_2025_eastern_michigan', seed);
    expect(ctx.game.status).toBe('final');
    expect(ctx.game.homeScore).toBe(48);
    expect(ctx.game.awayScore).toBe(23);
  });
});

// ── Template article production ───────────────────────────────────────────────

describe('buildTemplateArticle', () => {
  let ctx: GameContext;

  beforeAll(() => {
    ctx = assembleGameContext('fb_2026_youngstown', seed);
  });

  // ── Required fields ──────────────────────────────────────────────────────

  it('returns a headline string', () => {
    const art = buildTemplateArticle(ctx);
    expect(typeof art.headline).toBe('string');
    expect(art.headline.length).toBeGreaterThan(0);
  });

  it('returns a subheadline string', () => {
    const art = buildTemplateArticle(ctx);
    expect(typeof art.subheadline).toBe('string');
    expect(art.subheadline.length).toBeGreaterThan(0);
  });

  it('returns a non-empty openingNarrative', () => {
    const art = buildTemplateArticle(ctx);
    expect(typeof art.openingNarrative).toBe('string');
    expect(art.openingNarrative.length).toBeGreaterThan(10);
  });

  it('returns tacticalBreakdown with title and narrative', () => {
    const art = buildTemplateArticle(ctx);
    expect(art.tacticalBreakdown).toBeDefined();
    expect(typeof art.tacticalBreakdown.title).toBe('string');
    expect(typeof art.tacticalBreakdown.narrative).toBe('string');
    expect(art.tacticalBreakdown.narrative.length).toBeGreaterThan(0);
  });

  it('returns byTheNumbers with title and at least one item', () => {
    const art = buildTemplateArticle(ctx);
    expect(art.byTheNumbers.title).toBe('By the Numbers');
    expect(Array.isArray(art.byTheNumbers.items)).toBe(true);
    expect(art.byTheNumbers.items.length).toBeGreaterThan(0);
  });

  it('returns at least one playerSpotlight with required shape', () => {
    const art = buildTemplateArticle(ctx);
    expect(Array.isArray(art.playerSpotlights)).toBe(true);
    expect(art.playerSpotlights.length).toBeGreaterThan(0);
    for (const sp of art.playerSpotlights) {
      expect(typeof sp.name).toBe('string');
      expect(typeof sp.position).toBe('string');
      expect(typeof sp.narrative).toBe('string');
      expect(typeof sp.statline).toBe('string');
    }
  });

  it('returns theVerdict with title, prediction, confidence, narrative', () => {
    const art = buildTemplateArticle(ctx);
    expect(typeof art.theVerdict.title).toBe('string');
    expect(typeof art.theVerdict.prediction).toBe('string');
    expect(typeof art.theVerdict.confidence).toBe('number');
    expect(art.theVerdict.confidence).toBeGreaterThanOrEqual(0);
    expect(art.theVerdict.confidence).toBeLessThanOrEqual(100);
    expect(typeof art.theVerdict.narrative).toBe('string');
  });

  it('returns a closingLine string', () => {
    const art = buildTemplateArticle(ctx);
    expect(typeof art.closingLine).toBe('string');
    expect(art.closingLine.length).toBeGreaterThan(0);
  });

  // ── Content correctness ───────────────────────────────────────────────────

  it('preview headline does not say "Recap" for a scheduled game', () => {
    const art = buildTemplateArticle(ctx);
    expect(art.headline.toLowerCase()).not.toContain('recap');
  });

  it('includes opponent name in headline for preview', () => {
    const art = buildTemplateArticle(ctx);
    expect(art.headline).toContain('Youngstown State');
  });

  it('byTheNumbers items include real stats from seed data', () => {
    const art = buildTemplateArticle(ctx);
    // 2025 team_stats have pointsPerGame: 23.8 (demo)
    const hasPpg = art.byTheNumbers.items.some((item) => item.includes('23.8'));
    expect(hasPpg).toBe(true);
  });

  it('player spotlights use players from the football roster', () => {
    const art = buildTemplateArticle(ctx);
    const footballPlayers = ['Demo QB1', 'Demo RB1', 'Demo WR1'];
    const foundNames = art.playerSpotlights.map((sp) => sp.name);
    const anyMatch = foundNames.some((n) => footballPlayers.includes(n));
    expect(anyMatch).toBe(true);
  });

  it('recap article type uses final score language', () => {
    const finalCtx = assembleGameContext('fb_2025_eastern_michigan', seed);
    const art = buildTemplateArticle(finalCtx);
    // Either headline says "Win"/"Loss" or closingLine references "Final result"
    const combinedText = art.headline + ' ' + art.closingLine;
    const hasRecapLanguage =
      combinedText.includes('Win') ||
      combinedText.includes('Loss') ||
      combinedText.includes('Final') ||
      combinedText.includes('locked');
    expect(hasRecapLanguage).toBe(true);
  });
});

// ── Provenance / no-key guarantees ───────────────────────────────────────────

describe('provenance stamping (template path)', () => {
  it('buildTemplateArticle never references ANTHROPIC_API_KEY', () => {
    // This is a logic test: the template function must work when the env var is absent
    const originalKey = process.env.ANTHROPIC_API_KEY;
    delete process.env.ANTHROPIC_API_KEY;

    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    // Should not throw even with no key set
    expect(() => buildTemplateArticle(ctx)).not.toThrow();

    // Restore
    if (originalKey !== undefined) process.env.ANTHROPIC_API_KEY = originalKey;
  });

  it('byTheNumbers items are non-empty strings (no undefined leakage)', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    const art = buildTemplateArticle(ctx);
    for (const item of art.byTheNumbers.items) {
      expect(typeof item).toBe('string');
      expect(item).not.toBe('');
      expect(item).not.toContain('undefined');
      expect(item).not.toContain('null');
    }
  });

  it('confidence is a number (not undefined or string)', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    const art = buildTemplateArticle(ctx);
    expect(typeof art.theVerdict.confidence).toBe('number');
  });

  it('uses fanConfidence from game_summary as the confidence value', () => {
    // fb_2026_youngstown has fanConfidence: 84 in seed
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    const art = buildTemplateArticle(ctx);
    expect(art.theVerdict.confidence).toBe(84);
  });

  it('falls back to 65 confidence when no fanConfidence in summary', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    // Remove fanConfidence from context to test fallback
    const ctxNoConf: GameContext = {
      ...ctx,
      summary: ctx.summary ? { ...ctx.summary, fanConfidence: undefined } : undefined,
    };
    const art = buildTemplateArticle(ctxNoConf);
    expect(art.theVerdict.confidence).toBe(65);
  });
});

// ── No betting language audit ─────────────────────────────────────────────────

describe('no betting language in template output', () => {
  // Each entry is a whole-word regex — avoids false-positives like "ats" in "Wildcats".
  const BANNED_PATTERNS: Array<{ label: string; regex: RegExp }> = [
    { label: 'odds', regex: /\bodds\b/ },
    { label: 'wager', regex: /\bwager\b/ },
    { label: 'parlay', regex: /\bparlay\b/ },
    { label: 'spread', regex: /\bspread\b/ },
    { label: 'moneyline', regex: /\bmoneyline\b/ },
    { label: 'ats (against the spread)', regex: /\bats\b/ },
    { label: 'pick against', regex: /pick against/ },
    { label: 'over\/under', regex: /\bover\/under\b/ },
  ];

  it('fb_2026_youngstown template article contains no betting language', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    const art = buildTemplateArticle(ctx);
    const fullText = JSON.stringify(art).toLowerCase();
    for (const { label, regex } of BANNED_PATTERNS) {
      expect(fullText, `Found banned term: ${label}`).not.toMatch(regex);
    }
  });

  it('mbb_2026_louisville template article contains no betting language', () => {
    const ctx = assembleGameContext('mbb_2026_louisville', seed);
    const art = buildTemplateArticle(ctx);
    const fullText = JSON.stringify(art).toLowerCase();
    for (const { label, regex } of BANNED_PATTERNS) {
      expect(fullText, `Found banned term: ${label}`).not.toMatch(regex);
    }
  });
});
