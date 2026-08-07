/**
 * Unit tests for the article generator (scripts/generate_articles.ts).
 *
 * Tested here (pure functions, no network, no Firestore, no API key):
 *   1. assembleGameContext — pulls the correct data for a given game ID
 *   2. buildTemplateArticle — produces a valid article with all required fields,
 *      and never asserts a Kentucky edge the stored data doesn't support
 *   3. buildArticleDoc — draft-by-default status, honest provenance derived
 *      from the underlying docs, spotlight playerIds bound by identity
 *   4. findBettingLanguage — the pre-write guard scan
 *
 * The functions are imported directly from scripts/generate_articles.ts (its
 * CLI main() only runs when the file is executed directly). Importing the real
 * implementations — rather than keeping an inline copy — is deliberate: a
 * previous copy of this suite drifted out of sync with both the generator and
 * the seed data, and its fixtures went stale without failing.
 */

import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assembleGameContext,
  assertArticleEligible,
  buildTemplateArticle,
  buildArticleDoc,
  findBettingLanguage,
  kentuckyIsHome,
  protectedArticleReplacement,
  type Editorial,
  type GameContext,
  type SeedData,
  type SeedGame,
} from '../../../scripts/generate_articles';

// ── Load seed data directly ──────────────────────────────────────────────────

const SEED_PATH = resolve(__dirname, '../../../seed_data/dev_seed.json');

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

  it('carries provenance for each player stat doc', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    for (const ps of ctx.relevantPlayerStats) {
      expect(ps.statId).toBeTruthy();
      // The synced seed carries real CFBD player stats
      expect(ps.source).toBe('cfbd');
      expect(ps.confidence).toBe('official');
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

// ── Home/away derivation ──────────────────────────────────────────────────────

describe('kentuckyIsHome', () => {
  it('derives home from homeTeamId even when isHome is absent', () => {
    const base = assembleGameContext('fb_2025_eastern_michigan', seed).game;
    expect(kentuckyIsHome({ ...base, isHome: undefined })).toBe(true);
  });

  it('derives away from awayTeamId', () => {
    const base = assembleGameContext('fb_2026_texas_am', seed).game;
    expect(kentuckyIsHome({ ...base, isHome: undefined })).toBe(false);
  });

  it('throws rather than guessing when nothing identifies the home side', () => {
    const base = assembleGameContext('fb_2025_eastern_michigan', seed).game;
    const stripped: SeedGame = {
      ...base,
      homeTeamId: undefined,
      awayTeamId: undefined,
      isHome: undefined,
    };
    expect(() => kentuckyIsHome(stripped)).toThrow('Cannot determine home/away');
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
    // 2025 team_stats have pointsPerGame: 23 (real CFBD value)
    const hasPpg = art.byTheNumbers.items.some((item) => item.includes('Points per game: 23'));
    expect(hasPpg).toBe(true);
  });

  it('player spotlights use players from the real football roster', () => {
    const art = buildTemplateArticle(ctx);
    const footballPlayers = ['Cutter Boley', 'Seth McGowan', 'Kendrick Law'];
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

  // ── W/L derivation (the old isHome-only branch called home wins losses) ──

  it('recap calls a home win a Win even when isHome and result are absent', () => {
    const base = assembleGameContext('fb_2025_eastern_michigan', seed);
    const art = buildTemplateArticle({
      ...base,
      game: { ...base.game, isHome: undefined, result: undefined },
    });
    // Kentucky 48, Eastern Michigan 23 at home
    expect(art.headline).toContain('Kentucky Win');
    expect(art.theVerdict.prediction).toBe('Kentucky wins by 25');
  });

  it('recap calls an away win a Win', () => {
    const base = assembleGameContext('fb_2025_eastern_michigan', seed);
    const awayWin: GameContext = {
      ...base,
      game: {
        ...base.game,
        homeTeamId: 'opp_eastern_michigan',
        awayTeamId: 'kentucky_football',
        isHome: undefined,
        result: undefined,
        homeScore: 24,
        awayScore: 31,
      },
    };
    const art = buildTemplateArticle(awayWin);
    expect(art.headline).toContain('Kentucky Win');
    expect(art.theVerdict.prediction).toBe('Kentucky wins by 7');
  });

  it('recap calls an away loss a Loss (no dead "wins" branch)', () => {
    const base = assembleGameContext('fb_2025_eastern_michigan', seed);
    const awayLoss: GameContext = {
      ...base,
      game: {
        ...base.game,
        homeTeamId: 'opp_eastern_michigan',
        awayTeamId: 'kentucky_football',
        isHome: undefined,
        result: undefined,
        homeScore: 30,
        awayScore: 20,
      },
    };
    const art = buildTemplateArticle(awayLoss);
    expect(art.headline).toContain('Kentucky Loss');
    expect(art.theVerdict.prediction).toBe('Kentucky loses by 10');
  });

  // ── Honest leans (no unsupported pro-Kentucky assertions) ────────────────

  it('preview leans the opponent when the stored win probability says so', () => {
    const underdog: GameContext = {
      ...ctx,
      summary: {
        ...ctx.summary!,
        statStory: undefined,
        winProbability: { kentucky: 0.35, opponent: 0.65, source: 'seed_demo' },
      },
    };
    const art = buildTemplateArticle(underdog);
    expect(art.theVerdict.prediction).toBe('A competitive contest — leaning Youngstown State');
    expect(art.closingLine).toContain('the numbers lean Youngstown State');
    const fullText = JSON.stringify(art);
    expect(fullText).not.toContain('leaning Kentucky');
    expect(fullText).not.toContain('favor the Wildcats');
  });

  it('preview says so instead of asserting a lean when no projection exists', () => {
    const noProjection: GameContext = {
      ...ctx,
      summary: { ...ctx.summary!, statStory: undefined, winProbability: undefined },
    };
    const art = buildTemplateArticle(noProjection);
    expect(art.theVerdict.prediction).toBe('No projection available for this matchup');
    expect(art.openingNarrative).toContain('No projection is available');
    const fullText = JSON.stringify(art);
    expect(fullText).not.toContain('favor the Wildcats');
    expect(fullText).not.toContain('the numbers like the home team');
  });

  it('preview keeps the Kentucky lean when the data actually supports it', () => {
    // fb_2026_youngstown carries winProbability.kentucky = 0.92
    const art = buildTemplateArticle(ctx);
    expect(art.theVerdict.prediction).toBe('Kentucky by double digits');
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

  it('confidence is a number when the summary carries a real fanConfidence', () => {
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

  it('omits confidence entirely when there is no real fanConfidence (never invents one)', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    const ctxNoConf: GameContext = {
      ...ctx,
      summary: ctx.summary ? { ...ctx.summary, fanConfidence: undefined } : undefined,
    };
    const art = buildTemplateArticle(ctxNoConf);
    expect(art.theVerdict.confidence).toBeUndefined();
    // The key must be absent, not present-with-undefined — no fabricated stat pill.
    expect('confidence' in art.theVerdict).toBe(false);
    // And it stays absent through the ArticleDoc sink.
    const doc = buildArticleDoc('fb_2026_youngstown', ctxNoConf, art, 'seed_template');
    expect(doc.theVerdict.confidence).toBeUndefined();
  });

  it('omits confidence when the game has no summary at all', () => {
    const ctx = assembleGameContext('fb_2026_youngstown', seed);
    const art = buildTemplateArticle({ ...ctx, summary: undefined });
    expect('confidence' in art.theVerdict).toBe(false);
  });
});

// ── buildArticleDoc: draft default + derived provenance + identity binding ───

describe('buildArticleDoc', () => {
  let ctx: GameContext;
  let editorial: Editorial;

  beforeAll(() => {
    ctx = assembleGameContext('fb_2026_youngstown', seed);
    editorial = buildTemplateArticle(ctx);
  });

  it('defaults to status "draft" with no publishedAt', () => {
    const doc = buildArticleDoc('fb_2026_youngstown', ctx, editorial, 'seed_template');
    expect(doc.status).toBe('draft');
    expect(doc.publishedAt).toBeUndefined();
    expect('publishedAt' in doc).toBe(false);
    expect(doc.generatedAt).toBeTruthy();
  });

  it('marks published (with publishedAt) only when publish=true', () => {
    const doc = buildArticleDoc('fb_2026_youngstown', ctx, editorial, 'seed_template', true);
    expect(doc.status).toBe('published');
    expect(doc.publishedAt).toBeTruthy();
  });

  it('derives sources from the underlying docs, not a hardcoded prefix', () => {
    const doc = buildArticleDoc('fb_2026_youngstown', ctx, editorial, 'seed_template');
    // team_stats are real CFBD; summary + game are still seed_demo
    expect(doc.sources).toContain('cfbd:team_stats/kentucky_football_2025_season');
    expect(doc.sources).toContain('seed_demo:game_summaries/fb_2026_youngstown');
    expect(doc.sources).toContain('seed_demo:games/fb_2026_youngstown');
    // spotlighted players contribute their stat docs
    expect(doc.sources).toContain('cfbd:player_stats/fb_qb_demo_2025');
    // nothing claims seed_demo for the CFBD-backed docs
    expect(doc.sources).not.toContain('seed_demo:team_stats/kentucky_football_2025_season');
  });

  it('article confidence is the weakest input confidence (demo summary => demo)', () => {
    const doc = buildArticleDoc('fb_2026_youngstown', ctx, editorial, 'seed_template');
    expect(doc.confidence).toBe('demo');
  });

  it('article confidence is official only when every input is official', () => {
    const officialCtx: GameContext = {
      game: { ...ctx.game, source: 'cfbd' },
      summary: undefined,
      teamStats: ctx.teamStats, // cfbd / official
      relevantPlayerStats: ctx.relevantPlayerStats, // cfbd / official
    };
    const officialEditorial = buildTemplateArticle(officialCtx);
    const doc = buildArticleDoc('fb_2026_youngstown', officialCtx, officialEditorial, 'seed_template');
    expect(doc.confidence).toBe('official');
  });

  it('binds spotlight playerIds by name identity, not array index', () => {
    // Reverse the spotlight order — the LLM controls ordering, we must not
    // zip by index against relevantPlayerStats.
    const reversed: Editorial = {
      ...editorial,
      playerSpotlights: [...editorial.playerSpotlights].reverse(),
    };
    const doc = buildArticleDoc('fb_2026_youngstown', ctx, reversed, 'seed_template');
    const byName = new Map(ctx.relevantPlayerStats.map((p) => [p.profile.name, p.profile.id]));
    for (const sp of doc.playerSpotlights) {
      expect(sp.playerId).toBe(byName.get(sp.name));
    }
  });

  it('drops spotlights naming players absent from the provided data', () => {
    const invented: Editorial = {
      ...editorial,
      playerSpotlights: [
        ...editorial.playerSpotlights,
        {
          name: 'Made Up Player',
          position: 'QB',
          narrative: 'Not in the data.',
          statline: 'n/a',
        },
      ],
    };
    const doc = buildArticleDoc('fb_2026_youngstown', ctx, invented, 'seed_template');
    expect(doc.playerSpotlights.map((sp) => sp.name)).not.toContain('Made Up Player');
  });
});

// ── Betting-language guard scan ──────────────────────────────────────────────

describe('findBettingLanguage guard', () => {
  it('passes both template articles clean', () => {
    for (const gameId of ['fb_2026_youngstown', 'mbb_2026_louisville']) {
      const ctx = assembleGameContext(gameId, seed);
      const doc = buildArticleDoc(gameId, ctx, buildTemplateArticle(ctx), 'seed_template');
      expect(findBettingLanguage(doc), `betting term leaked into ${gameId}`).toBeNull();
    }
  });

  it('detects each banned term family', () => {
    expect(findBettingLanguage({ headline: 'Best point spread tonight' })).toBe('point spread');
    expect(findBettingLanguage({ headline: 'a point-spread pick' })).toBe('point-spread');
    expect(findBettingLanguage({ narrative: 'stop wagering on it' })).toBe('wagering');
    expect(findBettingLanguage({ item: 'the over/under sits at 48' })).toBe('over/under');
    expect(findBettingLanguage({ item: 'the over - under sits at 48' })).toBe('over - under');
    expect(findBettingLanguage({ item: 'moneyline value' })).toBe('moneyline');
    expect(findBettingLanguage({ item: 'the money line told the story' })).toBe('money line');
    expect(findBettingLanguage({ item: 'a three-leg Parlay' })).toBe('parlay');
    expect(findBettingLanguage({ item: 'your local sportsbooks' })).toBe('sportsbooks');
    expect(findBettingLanguage({ item: 'ask the bookie' })).toBe('bookie');
    expect(findBettingLanguage({ item: 'I bet he scores twice' })).toBe('bet');
    expect(findBettingLanguage({ item: 'betting is banned' })).toBe('betting');
    expect(findBettingLanguage({ item: 'the odds heavily favor Kentucky' })).toBe('odds');
    expect(findBettingLanguage({ item: 'the vig eats the profit' })).toBe('vig');
    expect(findBettingLanguage({ item: 'best team ATS this year' })).toBe('ats');
    expect(findBettingLanguage({ item: 'a reason to pick against the Cats' })).toBe('pick against');
    expect(findBettingLanguage({ item: 'he picked against Kentucky all season' })).toBe('picked against');
  });

  it('does not false-positive on football vocabulary', () => {
    expect(
      findBettingLanguage({
        text: 'The Wildcats spread the field and looked better than the alphabets suggest.',
      }),
    ).toBeNull();
    expect(findBettingLanguage({ text: 'A spread offense with tempo.' })).toBeNull();
    // "Wildcats" must never trip the whole-word \bats\b term.
    expect(findBettingLanguage({ text: 'Wildcats stats formats' })).toBeNull();
    expect(findBettingLanguage({ text: 'They navigate pressure well.' })).toBeNull();
  });
});

// ── No betting language audit (template output) ──────────────────────────────

describe('no betting language in template output', () => {
  // Each entry is a whole-word regex — avoids false-positives like "ats" in "Wildcats".
  const BANNED_PATTERNS: Array<{ label: string; regex: RegExp }> = [
    { label: 'bet/bets/betting', regex: /\bbets?\b|\bbetting\b/ },
    { label: 'odds', regex: /\bodds\b/ },
    { label: 'wager', regex: /\bwager\w*\b/ },
    { label: 'parlay', regex: /\bparlay\w*\b/ },
    { label: 'sportsbook', regex: /\bsportsbook\w*\b/ },
    { label: 'bookie', regex: /\bbookie\w*\b/ },
    { label: 'point spread', regex: /\bpoint\s+spread\b/ },
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

// ── Full GameStatus union: postponed/canceled refusal + honest score-less finals ──

describe('game status eligibility', () => {
  it.each(['postponed', 'canceled'] as const)(
    'refuses to build a template article for a %s game',
    (status) => {
      const base = assembleGameContext('fb_2026_youngstown', seed);
      const ctx: GameContext = { ...base, game: { ...base.game, status } };
      expect(() => buildTemplateArticle(ctx)).toThrow(`status is "${status}"`);
      expect(() => assertArticleEligible(ctx.game)).toThrow('Refusing to generate');
    },
  );

  it('buildArticleDoc refuses postponed/canceled too (guards the LLM path sink)', () => {
    const base = assembleGameContext('fb_2026_youngstown', seed);
    const editorial = buildTemplateArticle(base);
    const ctx: GameContext = { ...base, game: { ...base.game, status: 'canceled' } };
    expect(() => buildArticleDoc('fb_2026_youngstown', ctx, editorial, 'seed_template')).toThrow(
      'status is "canceled"',
    );
  });

  it('allows every playable status through', () => {
    const base = assembleGameContext('fb_2026_youngstown', seed);
    for (const status of ['scheduled', 'live', 'final'] as const) {
      expect(() => assertArticleEligible({ ...base.game, status })).not.toThrow();
    }
  });

  it('recap for a final doc with missing scores never fabricates a 0–0 final', () => {
    const base = assembleGameContext('fb_2025_eastern_michigan', seed);
    const ctx: GameContext = {
      ...base,
      game: { ...base.game, homeScore: null, awayScore: null, result: undefined },
    };
    const art = buildTemplateArticle(ctx);
    const fullText = JSON.stringify(art);
    expect(fullText).not.toMatch(/\b0\s*[–-]\s*0\b/);
    expect(art.theVerdict.prediction).toBe('Final score not yet recorded');
    // With no scores and no stored result, no W/L claim may be made either.
    expect(art.headline).not.toContain('Win');
    expect(art.headline).not.toContain('Loss');
  });
});

// ── Published-work protection (apply-articles + Firestore upsert guard) ──────

describe('protectedArticleReplacement', () => {
  const publishedClaude = { status: 'published', model: 'claude-opus-4-8' };

  it('blocks demoting a published article to draft', () => {
    const reason = protectedArticleReplacement(publishedClaude, {
      status: 'draft',
      model: 'claude-opus-4-8',
    });
    expect(reason).toMatch(/demoted to "draft"/);
  });

  it('blocks replacing a claude-* article with a seed_template regeneration', () => {
    const reason = protectedArticleReplacement(publishedClaude, {
      status: 'published',
      model: 'seed_template',
    });
    expect(reason).toMatch(/seed_template regeneration/);
  });

  it('allows a fresh published claude regeneration over a published claude article', () => {
    expect(
      protectedArticleReplacement(publishedClaude, { status: 'published', model: 'claude-opus-4-8' }),
    ).toBeNull();
  });

  it('allows anything to replace a draft template', () => {
    const draftTemplate = { status: 'draft', model: 'seed_template' };
    expect(
      protectedArticleReplacement(draftTemplate, { status: 'draft', model: 'seed_template' }),
    ).toBeNull();
    expect(
      protectedArticleReplacement(draftTemplate, { status: 'published', model: 'claude-opus-4-8' }),
    ).toBeNull();
  });

  it('protects a draft claude article from a template regeneration (edit work preserved)', () => {
    const draftClaude = { status: 'draft', model: 'claude-opus-4-8' };
    expect(
      protectedArticleReplacement(draftClaude, { status: 'draft', model: 'seed_template' }),
    ).toMatch(/claude-opus-4-8/);
  });
});
