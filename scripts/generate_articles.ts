/**
 * AI Article Pipeline — generates preview or recap articles from seed/Firestore data.
 *
 * Usage:
 *   tsx generate_articles.ts --game=fb_2026_youngstown
 *   tsx generate_articles.ts           # processes all featured games
 *   tsx generate_articles.ts --publish # mark output published (default is draft)
 *
 * Key-gated:
 *   - If ANTHROPIC_API_KEY is NOT set → deterministic seed_template article (offline-safe).
 *   - If ANTHROPIC_API_KEY IS set     → calls Claude via dynamic import (no install required
 *     for the fallback path).
 *
 * Output:
 *   - Writes seed_data/generated/<gameId>.json always.
 *   - If FIRESTORE_EMULATOR_HOST is set → upserts to Firestore `articles` collection.
 *   - Articles are stamped status:"draft" unless --publish is passed — same
 *     human-in-the-loop model as the Vault legends pipeline.
 *   - The Firestore upsert never demotes an existing published article to draft
 *     or replaces a claude-* article with a seed_template regeneration unless
 *     --force is passed (mirrors seed_firestore.ts's vault-legend guard).
 *
 * Security rules:
 *   - No secrets in code. Keys from env only.
 *   - No betting language. Every article is scanned before it is written and the
 *     run hard-fails on a hit (mirrors apps/admin_portal/src/data/vaultGuards.ts).
 *   - No University of Kentucky trademarks.
 *   - Stats come ONLY from stored data — never invented. Provenance (sources +
 *     confidence) is derived from the underlying docs, weakest confidence wins.
 */

import { readFileSync, mkdirSync, writeFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import type { GameStatus } from "../packages/shared_models/src/index";

// ── Paths ─────────────────────────────────────────────────────────────────────

const __dirname = dirname(fileURLToPath(import.meta.url));
const SEED_PATH = resolve(__dirname, "../seed_data/dev_seed.json");
const OUT_DIR = resolve(__dirname, "../seed_data/generated");

// ── Load .env.local files (gitignored) into process.env ───────────────────────
// Put ANTHROPIC_API_KEY (and optional ANTHROPIC_MODEL) in EITHER the repo-root
// .env.local OR functions/.env.local — both are checked, so you don't have to set
// a shell variable each run. Variables already set in the shell take precedence.
for (const envPath of [
  resolve(__dirname, "../.env.local"),
  resolve(__dirname, "../functions/.env.local"),
]) {
  if (!existsSync(envPath)) continue;
  for (const line of readFileSync(envPath, "utf8").split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (m && !process.env[m[1]]) {
      process.env[m[1]] = m[2].replace(/^["']|["']$/g, "");
    }
  }
}

// ── Model config ──────────────────────────────────────────────────────────────

const MODEL = process.env.ANTHROPIC_MODEL ?? "claude-opus-4-8";

// ── System prompt ─────────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `You are an elite independent college-sports journalist covering Kentucky Wildcats basketball and football.

HARD RULES — these override everything else:
1. Use ONLY the numbers provided in the user message. Never invent, estimate, or extrapolate statistics.
2. You are an independent fan voice — NOT an official University of Kentucky publication.
3. No betting language. Do not use: bet, betting, odds, wager, parlay, spread, point spread, over/under, line, ATS, pick against, moneyline, sportsbook, bookie.
4. No official University of Kentucky trademarks (no ®/™ marks, no licensed marks).
5. Write for a passionate fan audience — vivid, direct, analytically grounded prose.
6. theVerdict.confidence is optional: include it ONLY when the provided data contains a fan confidence or win probability to ground it (then a number between 0 and 100). If no projection is provided, omit the field entirely and never mention a confidence percentage in prose.
7. playerSpotlights: name only players whose stats appear in the data — no invented rosters.
8. Never assert that Kentucky is favored, has the edge, or will win unless the provided win probability or stats actually support it. If no projection is provided, stay neutral.
9. Keep openingNarrative under 120 words. tacticalBreakdown.narrative under 100 words. theVerdict.narrative under 80 words. closingLine under 25 words.`;

// ── Zod schema for editorial output ──────────────────────────────────────────

// Zod is imported dynamically only in the LLM branch; for the template branch
// we replicate the shape manually. The import below is static because zod is
// in our dep tree (scripts/package.json) and used for type inference.
// NOTE: import from "zod/v4" (not "zod") — the Anthropic SDK's zodOutputFormat
// expects the Zod 4 schema shape. zod 3.25+ ships the v4 API at this subpath.
import { z } from "zod/v4";

const EditorialSchema = z.object({
  headline: z.string(),
  subheadline: z.string(),
  openingNarrative: z.string(),
  tacticalBreakdown: z.object({
    title: z.string(),
    narrative: z.string(),
  }),
  byTheNumbers: z.object({
    title: z.string(),
    items: z.array(z.string()),
  }),
  playerSpotlights: z.array(
    z.object({
      name: z.string(),
      position: z.string(),
      narrative: z.string(),
      statline: z.string(),
    })
  ),
  theVerdict: z.object({
    title: z.string(),
    prediction: z.string(),
    // Optional on purpose: a confidence with no fanConfidence / winProbability
    // behind it is a fabricated stat (hard rule 6). Absent means "no projection".
    confidence: z.number().optional(),
    narrative: z.string(),
  }),
  closingLine: z.string(),
});

export type Editorial = z.infer<typeof EditorialSchema>;

// ── Seed data types ───────────────────────────────────────────────────────────
// Game status values come from the canonical GameStatus union in
// packages/shared_models (single source of truth — do not redeclare inline).

export interface SeedGame {
  id: string;
  gameId?: string;
  season: number;
  sport: string;
  homeTeamId?: string;
  awayTeamId?: string;
  opponentName: string;
  opponentShort?: string;
  startTime: string;
  venue?: string | null;
  status: GameStatus;
  homeScore?: number | null;
  awayScore?: number | null;
  broadcast?: string;
  featured?: boolean;
  isHome?: boolean;
  result?: string;
  source?: string;
}

export interface GameSummary {
  id: string;
  gameId?: string;
  matchupVerdict?: string;
  matchupScore?: number;
  fanConfidence?: number;
  winProbability?: { kentucky: number; opponent: number; source?: string };
  teamComparison?: Record<string, Record<string, number>>;
  keysToGame?: string[];
  playerToWatch?: { playerId: string; reason: string };
  concernMeter?: { level: string; note: string };
  statStory?: string;
  source?: string;
  confidence?: string;
}

export interface TeamStat {
  id: string;
  teamId: string;
  season: number;
  sport: string;
  scope: string;
  stats: Record<string, number | string | null>;
  source?: string;
  confidence?: string;
  updatedAt?: string;
}

export interface PlayerProfile {
  id: string;
  name: string;
  teamId: string;
  sport: string;
  position: string;
  classYear?: string;
  jersey?: number;
}

export interface PlayerStat {
  id: string;
  playerId: string;
  teamId: string;
  season: number;
  sport: string;
  scope: string;
  stats: Record<string, number | string | null>;
  source?: string;
  confidence?: string;
}

export interface SeedData {
  games: SeedGame[];
  game_summaries: GameSummary[];
  team_stats: TeamStat[];
  player_profiles: PlayerProfile[];
  player_stats: PlayerStat[];
  [key: string]: unknown;
}

// ── Game context (what we send to the LLM) ───────────────────────────────────

export interface GameContext {
  game: SeedGame;
  summary?: GameSummary;
  teamStats?: TeamStat;
  relevantPlayerStats: Array<{
    profile: PlayerProfile;
    stats: Record<string, number | string | null>;
    /** id + provenance of the player_stats doc the stats came from */
    statId: string;
    source?: string;
    confidence?: string;
  }>;
}

// ── Article output shape ──────────────────────────────────────────────────────

export interface ArticleDoc {
  id: string;
  type: "preview" | "recap" | "stat_story";
  gameId: string;
  sport: string;
  status: "draft" | "published" | "hidden";
  headline: string;
  subheadline: string;
  openingNarrative: string;
  tacticalBreakdown?: { title: string; narrative: string };
  byTheNumbers: { title: string; items: string[] };
  playerSpotlights: Array<{
    playerId?: string;
    name: string;
    position: string;
    narrative: string;
    statline: string;
  }>;
  theVerdict: {
    title: string;
    prediction?: string;
    confidence?: number;
    narrative: string;
  };
  closingLine: string;
  sources: string[];
  model: string;
  generatedAt: string;
  /** Only present when the article was generated with --publish. */
  publishedAt?: string;
  confidence: string;
  featured?: boolean;
}

// ── Betting-language guard ────────────────────────────────────────────────────
// Free-to-play hard rule: no betting language may reach any article surface.
// Mirrors the admin portal's Vault guard (apps/admin_portal/src/data/vaultGuards.ts),
// including the spaced/hyphenated variants ("money line", "point-spread",
// "over / under") plus bare "odds", "vig", whole-word "ats" and "pick against".
// Deliberately whole-word so "Wildcats" (ats), "better" (bet) and football usage
// of a bare "spread" (spread offense) don't false-positive.

const BETTING_LANGUAGE_RE =
  /\b(?:bet|bets|betting|wager\w*|parlay\w*|sportsbook\w*|bookie\w*|money[\s-]?lines?|point[\s-]+spreads?|over\s*[/–-]\s*under|odds|vig|ats|pick(?:s|ed|ing)?\s+against)\b/i;

/** Returns the first betting term found anywhere in the article's text, or null. */
export function findBettingLanguage(article: unknown): string | null {
  const m = JSON.stringify(article).match(BETTING_LANGUAGE_RE);
  return m ? m[0].toLowerCase() : null;
}

// ── Published-work protection ─────────────────────────────────────────────────
// Mirrors the vault-legend guard in seed_firestore.ts: a routine regeneration
// must never demote a published article to draft, and a template must never
// replace a Claude-written article. Shared by the Firestore upsert below and by
// apply_generated_articles.ts; --force overrides in both.

/** Returns a human-readable reason the existing article must not be replaced, or null. */
export function protectedArticleReplacement(
  existing: { status?: unknown; model?: unknown },
  incoming: { status?: unknown; model?: unknown }
): string | null {
  if (existing.status === "published" && incoming.status !== "published") {
    return `status "published" would be demoted to "${String(incoming.status)}"`;
  }
  if (
    typeof existing.model === "string" &&
    existing.model.startsWith("claude-") &&
    incoming.model === "seed_template"
  ) {
    return `model "${existing.model}" would be replaced by a seed_template regeneration`;
  }
  return null;
}

// ── Context assembly ──────────────────────────────────────────────────────────

function loadSeedData(): SeedData {
  const raw = readFileSync(SEED_PATH, "utf8");
  return JSON.parse(raw) as SeedData;
}

function resolveTeamId(sport: string): string {
  if (sport === "football") return "kentucky_football";
  if (sport === "mens_basketball") return "kentucky_mens_basketball";
  if (sport === "womens_basketball") return "kentucky_womens_basketball";
  return `kentucky_${sport}`;
}

function assembleSeason(game: SeedGame): number {
  // Prefer game.season; fallback parse from startTime year
  if (game.season) return game.season;
  return new Date(game.startTime).getFullYear();
}

/**
 * True when Kentucky is the home team. Derived from homeTeamId/awayTeamId (the
 * authoritative fields), falling back to the optional isHome flag. Throws
 * rather than guessing when neither is present — a wrong home/away call
 * produces a wrong W/L headline (hard rule 6).
 */
export function kentuckyIsHome(game: SeedGame): boolean {
  const teamId = resolveTeamId(game.sport);
  if (game.homeTeamId === teamId) return true;
  if (game.awayTeamId === teamId) return false;
  if (typeof game.isHome === "boolean") return game.isHome;
  throw new Error(
    `Cannot determine home/away for ${game.id}: no homeTeamId/awayTeamId/isHome in the game doc.`
  );
}

export function assembleGameContext(gameId: string, seed: SeedData): GameContext {
  const game = seed.games.find((g) => g.id === gameId);
  if (!game) throw new Error(`Game not found in seed data: ${gameId}`);

  const summary = seed.game_summaries.find(
    (s) => s.id === gameId || s.gameId === gameId
  );

  const teamId = resolveTeamId(game.sport);
  const season = assembleSeason(game);

  // Match team_stats by teamId + season + scope=season.
  // If no exact season match, fall back to the most recent season available
  // (e.g. 2025 carry-forward stats used for 2026 preview articles).
  let teamStats = seed.team_stats.find(
    (ts) =>
      ts.teamId === teamId &&
      ts.season === season &&
      ts.scope === "season" &&
      ts.sport === game.sport
  );
  if (!teamStats) {
    const fallbackStats = seed.team_stats
      .filter((ts) => ts.teamId === teamId && ts.scope === "season" && ts.sport === game.sport)
      .sort((a, b) => b.season - a.season);
    teamStats = fallbackStats[0];
  }

  // Gather player profiles for this sport/team
  const teamProfiles = seed.player_profiles.filter(
    (p) => p.teamId === teamId && p.sport === game.sport
  );

  // Gather player stats for the same team/sport. Try exact season first,
  // then fall back to the most recent season for each player.
  const relevantPlayerStats = teamProfiles
    .map((profile): GameContext["relevantPlayerStats"][number] | null => {
      let statDoc = seed.player_stats.find(
        (ps) =>
          ps.playerId === profile.id &&
          ps.teamId === teamId &&
          ps.season === season &&
          ps.sport === game.sport
      );
      if (!statDoc) {
        const fallback = seed.player_stats
          .filter(
            (ps) =>
              ps.playerId === profile.id &&
              ps.teamId === teamId &&
              ps.sport === game.sport
          )
          .sort((a, b) => b.season - a.season);
        statDoc = fallback[0];
      }
      if (!statDoc) return null;
      return {
        profile,
        stats: statDoc.stats,
        statId: statDoc.id,
        source: statDoc.source,
        confidence: statDoc.confidence,
      };
    })
    .filter((x): x is GameContext["relevantPlayerStats"][number] => x !== null);

  return { game, summary, teamStats, relevantPlayerStats };
}

// ── Game-status eligibility ──────────────────────────────────────────────────
// Articles exist only for games that are being (or were) played. A postponed
// or canceled game has no honest preview and no recap — generating one would
// fabricate a result (hard rule 6). Refuse loudly; a neutral notice card is a
// deliberate admin/CMS decision, never something this pipeline invents.

export function assertArticleEligible(game: SeedGame): void {
  if (game.status === "postponed" || game.status === "canceled") {
    throw new Error(
      `Refusing to generate an article for ${game.id}: status is "${game.status}" — no preview/recap exists for a game that is not being played.`
    );
  }
}

// ── Template fallback (no API key) ───────────────────────────────────────────
// Every claim below must follow from the data in ctx or stay neutral — the
// template never asserts a Kentucky edge the stored numbers don't support.

export function buildTemplateArticle(ctx: GameContext): Editorial {
  const { game, summary, teamStats } = ctx;
  assertArticleEligible(game);
  // After the guard, the only non-preview status left is "final".
  const isPreview = game.status === "scheduled" || game.status === "live";
  const opponent = game.opponentName;
  const home = kentuckyIsHome(game);
  const site = game.venue ? `at ${game.venue}` : home ? "at home" : "on the road";
  const sport = game.sport;
  const winProb = summary?.winProbability?.kentucky;

  // ---------- headline / subheadline ----------
  let headline: string;
  let subheadline: string;

  if (isPreview) {
    headline = home
      ? `${sport === "football" ? "Cats Host" : "Kentucky Welcomes"} ${opponent} — By the Numbers`
      : `Kentucky Visits ${opponent} — By the Numbers`;
    subheadline = summary?.statStory
      ? summary.statStory.split(".")[0] + "."
      : `Matchup preview for the upcoming game ${site}.`;
  } else {
    // Derive the result from stored data — game.result is the seed's explicit
    // call; the Kentucky-vs-opponent score comparison is the fallback. When
    // neither settles it, make no W/L claim at all.
    const kyScore = home ? game.homeScore : game.awayScore;
    const oppScore = home ? game.awayScore : game.homeScore;
    let wonLost: string | null = null;
    if (game.result === "win" || game.result === "loss") {
      wonLost = game.result === "win" ? "Win" : "Loss";
    } else if (kyScore != null && oppScore != null && kyScore !== oppScore) {
      wonLost = kyScore > oppScore ? "Win" : "Loss";
    }
    headline = wonLost
      ? `Kentucky ${wonLost}: Wildcats vs. ${opponent} — Final Recap`
      : `Kentucky vs. ${opponent} — Final Recap`;
    subheadline = `A look at the numbers behind the final result.`;
  }

  // ---------- openingNarrative ----------
  let openingNarrative: string;
  if (summary?.statStory) {
    openingNarrative = summary.statStory;
  } else if (isPreview) {
    const setting = home
      ? `returns ${game.venue ? `to ${game.venue}` : "home"}`
      : `hits the road`;
    if (winProb == null) {
      openingNarrative = `Kentucky ${setting} to take on ${opponent}. No projection is available for this matchup — the numbers will have to tell the story on game day.`;
    } else if (winProb >= 0.6) {
      openingNarrative = `Kentucky ${setting} to take on ${opponent}. The numbers favor the Wildcats — the edge lies in execution.`;
    } else if (winProb >= 0.5) {
      openingNarrative = `Kentucky ${setting} to take on ${opponent}. The numbers make this one close, with a narrow Kentucky lean on paper.`;
    } else {
      openingNarrative = `Kentucky ${setting} to take on ${opponent}. The numbers lean ${opponent} — the Wildcats enter as the underdog on paper.`;
    }
  } else {
    const finalScore =
      game.homeScore != null && game.awayScore != null
        ? ` ${game.homeScore}–${game.awayScore}`
        : "";
    openingNarrative = `The Wildcats and ${opponent} played out a${finalScore} final. The stats told the story.`;
  }

  // ---------- tacticalBreakdown ----------
  const keys = summary?.keysToGame ?? [];
  const tacticalNarrative =
    keys.length > 0
      ? keys.slice(0, 2).join(". ") + "."
      : `Kentucky will look to exploit matchup advantages and control tempo throughout the contest.`;

  // ---------- byTheNumbers ----------
  const byItems: string[] = [];
  if (teamStats?.stats) {
    const s = teamStats.stats;
    if (s["pointsPerGame"] != null)
      byItems.push(`Points per game: ${s["pointsPerGame"]}`);
    if (s["yardsPerPlay"] != null)
      byItems.push(`Yards per play: ${s["yardsPerPlay"]}`);
    if (s["turnoverMargin"] != null)
      byItems.push(`Turnover margin: ${Number(s["turnoverMargin"]) >= 0 ? "+" : ""}${s["turnoverMargin"]} per game`);
    if (s["thirdDownPct"] != null)
      byItems.push(`Third-down conversion rate: ${(Number(s["thirdDownPct"]) * 100).toFixed(0)}%`);
    if (s["redZoneScorePct"] != null)
      byItems.push(`Red-zone scoring rate: ${(Number(s["redZoneScorePct"]) * 100).toFixed(0)}%`);
    if (s["adjOffRating"] != null)
      byItems.push(`Adjusted offensive rating: ${s["adjOffRating"]}`);
    if (s["adjDefRating"] != null)
      byItems.push(`Adjusted defensive rating: ${s["adjDefRating"]}`);
    if (s["effectiveFgPct"] != null)
      byItems.push(`Effective FG%: ${(Number(s["effectiveFgPct"]) * 100).toFixed(1)}%`);
    if (s["tempo"] != null)
      byItems.push(`Tempo (possessions/game): ${s["tempo"]}`);
  }
  if (summary?.teamComparison?.kentucky) {
    const kComp = summary.teamComparison.kentucky;
    if (byItems.length === 0) {
      // Use comparison stats if no team_stats available
      for (const [key, val] of Object.entries(kComp)) {
        byItems.push(`${key}: ${val}`);
      }
    }
  }
  if (byItems.length === 0) {
    byItems.push("See the matchup breakdown for detailed statistics.");
  }

  // ---------- playerSpotlights ----------
  const spotlights = ctx.relevantPlayerStats.slice(0, 3).map(({ profile, stats }) => {
    const lines: string[] = [];
    for (const [key, val] of Object.entries(stats)) {
      if (val != null) lines.push(`${key}: ${val}`);
    }
    const statline = lines.slice(0, 3).join(", ");
    return {
      name: profile.name,
      position: profile.position,
      narrative: `${profile.name} (${profile.position}) is one to watch in this contest.`,
      statline: statline || "Stats available in full matchup data.",
    };
  });

  // Fallback if no player stats in seed
  if (spotlights.length === 0) {
    spotlights.push({
      name: "Kentucky Offense",
      position: "UNIT",
      narrative: "The offensive unit's efficiency will be the key variable in this matchup.",
      statline: "See team stats above.",
    });
  }

  // ---------- theVerdict ----------
  // The lean must follow the stored win probability; with no projection, say so
  // rather than asserting a Kentucky lean. Confidence is only ever the stored
  // fanConfidence — when there is none, the field is omitted, never invented.
  const confidence = summary?.fanConfidence;

  let prediction: string;
  if (isPreview) {
    if (winProb == null) {
      prediction = `No projection available for this matchup`;
    } else if (winProb >= 0.6) {
      prediction = `Kentucky by double digits`;
    } else if (winProb >= 0.5) {
      prediction = `Kentucky in a close game`;
    } else {
      prediction = `A competitive contest — leaning ${opponent}`;
    }
  } else {
    // Recap: only real stored scores may appear — a "final" doc whose scores
    // haven't landed yet must not fabricate a 0–0 (hard rule 6).
    const kyScore = home ? game.homeScore : game.awayScore;
    const oppScore = home ? game.awayScore : game.homeScore;
    if (kyScore != null && oppScore != null) {
      const margin = kyScore - oppScore;
      prediction =
        margin !== 0
          ? `Kentucky ${margin > 0 ? "wins" : "loses"} by ${Math.abs(margin)}`
          : `Final: ${game.homeScore}–${game.awayScore}`;
    } else {
      prediction = `Final score not yet recorded`;
    }
  }

  const verdictNarrative =
    summary?.keysToGame?.[2] ??
    (isPreview
      ? "Execution and ball security will decide it — the matchup data above tells the story."
      : "The final score reflects how each side executed when it mattered most.");

  // ---------- closingLine ----------
  const closingLine = isPreview
    ? winProb == null
      ? `Game time ${site} — the numbers will tell the story.`
      : winProb >= 0.5
        ? `Game time ${site} — the numbers lean Kentucky.`
        : `Game time ${site} — the numbers lean ${opponent}.`
    : `Final result locked in. The stats hold up under review.`;

  return {
    headline,
    subheadline,
    openingNarrative,
    tacticalBreakdown: {
      title: "The Chess Match",
      narrative: tacticalNarrative,
    },
    byTheNumbers: {
      title: "By the Numbers",
      items: byItems.slice(0, 6),
    },
    playerSpotlights: spotlights,
    theVerdict: {
      title: "The Verdict",
      prediction,
      ...(confidence != null ? { confidence } : {}),
      narrative: verdictNarrative,
    },
    closingLine,
  };
}

// ── Provenance stamping ───────────────────────────────────────────────────────
// Sources and confidence are derived from the docs the article was actually
// built from — never hardcoded. Weakest input confidence wins (hard rule 6:
// an article is only as trustworthy as its least-verified source).

const CONFIDENCE_RANK: Record<string, number> = {
  demo: 0,
  fan_rumor: 0,
  researched: 1,
  official: 2,
};

function docProvenance(source?: string, confidence?: string): { source: string; confidence: string } {
  const src = source ?? "seed_demo";
  const conf =
    confidence ?? (src === "cfbd" || src === "cbbd" || src === "khsaa" ? "official" : "demo");
  return { source: src, confidence: conf };
}

export function buildArticleDoc(
  gameId: string,
  ctx: GameContext,
  editorial: Editorial,
  model: string,
  publish = false
): ArticleDoc {
  const { game, summary, teamStats } = ctx;

  // Both paths (template AND LLM editorial) sink through here — enforce the
  // status eligibility again so a postponed/canceled game can never be typed
  // as a "recap".
  assertArticleEligible(game);
  const articleType: "preview" | "recap" | "stat_story" =
    game.status === "scheduled" || game.status === "live" ? "preview" : "recap";

  // ── Spotlights: bind playerIds by identity (name), never by array index ──
  const playerSpotlights: ArticleDoc["playerSpotlights"] = [];
  const spotlightedStats: GameContext["relevantPlayerStats"] = [];
  for (const sp of editorial.playerSpotlights) {
    const match = ctx.relevantPlayerStats.find((p) => p.profile.name === sp.name);
    if (match) {
      spotlightedStats.push(match);
      playerSpotlights.push({
        playerId: match.profile.id,
        name: sp.name,
        position: sp.position,
        narrative: sp.narrative,
        statline: sp.statline,
      });
    } else if (sp.position === "UNIT") {
      // Template fallback block (e.g. "Kentucky Offense") — no player identity to bind.
      playerSpotlights.push({
        name: sp.name,
        position: sp.position,
        narrative: sp.narrative,
        statline: sp.statline,
      });
    } else {
      // System-prompt rule 7: only players present in the data may be named.
      console.warn(`  ! Dropping spotlight "${sp.name}" — no matching player in the provided data.`);
    }
  }

  const inputs: Array<{ source: string; confidence: string; ref: string }> = [];
  if (teamStats)
    inputs.push({ ...docProvenance(teamStats.source, teamStats.confidence), ref: `team_stats/${teamStats.id}` });
  if (summary)
    inputs.push({ ...docProvenance(summary.source, summary.confidence), ref: `game_summaries/${gameId}` });
  inputs.push({ ...docProvenance(game.source), ref: `games/${gameId}` });
  for (const ps of spotlightedStats)
    inputs.push({ ...docProvenance(ps.source, ps.confidence), ref: `player_stats/${ps.statId}` });

  const sources = inputs.map((i) => `${i.source}:${i.ref}`);
  let confidence = "official";
  for (const i of inputs) {
    if ((CONFIDENCE_RANK[i.confidence] ?? 0) < (CONFIDENCE_RANK[confidence] ?? 0)) {
      confidence = i.confidence;
    }
  }

  const now = new Date().toISOString();

  return {
    id: `article_${gameId}_${articleType}`,
    type: articleType,
    gameId,
    sport: game.sport,
    // Draft by default — publishing requires the explicit --publish flag.
    status: publish ? "published" : "draft",
    headline: editorial.headline,
    subheadline: editorial.subheadline,
    openingNarrative: editorial.openingNarrative,
    tacticalBreakdown: editorial.tacticalBreakdown,
    byTheNumbers: editorial.byTheNumbers,
    playerSpotlights,
    theVerdict: editorial.theVerdict,
    closingLine: editorial.closingLine,
    sources,
    model,
    generatedAt: now,
    ...(publish ? { publishedAt: now } : {}),
    confidence,
    featured: game.featured,
  };
}

// ── LLM generation (key-present branch) ──────────────────────────────────────

async function generateWithLLM(ctx: GameContext): Promise<Editorial> {
  // Dynamic import — only reached when ANTHROPIC_API_KEY is present.
  // This means the SDK is never imported in the no-key fallback path.
  const { default: Anthropic } = await import("@anthropic-ai/sdk");
  const { zodOutputFormat } = await import("@anthropic-ai/sdk/helpers/zod");

  const client = new Anthropic();

  const res = await client.messages.parse({
    model: MODEL,
    max_tokens: 4096,
    thinking: { type: "adaptive" },
    output_config: { effort: "medium", format: zodOutputFormat(EditorialSchema) },
    system: [{ type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
    messages: [{ role: "user", content: JSON.stringify(ctx) }],
  });

  const editorial = res.parsed_output;
  if (!editorial) {
    throw new Error(
      `LLM returned null parsed_output (stop_reason=${(res as { stop_reason?: string }).stop_reason ?? "unknown"}). Falling back is not automatic — re-run without key to get template.`
    );
  }

  return editorial as Editorial;
}

// ── Firestore upsert (emulator-only) ─────────────────────────────────────────

async function upsertToFirestore(article: ArticleDoc, force: boolean): Promise<void> {
  const { initializeApp, getApps } = await import("firebase-admin/app");
  const { getFirestore, Timestamp } = await import("firebase-admin/firestore");

  const PROJECT_ID = process.env.GCLOUD_PROJECT ?? "bluegrass-gameday-dev";
  if (getApps().length === 0) {
    initializeApp({ projectId: PROJECT_ID });
  }
  const db = getFirestore();

  // Convert ISO strings to Timestamps for Firestore
  const ISO_DATETIME = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?([+-]\d{2}:\d{2}|Z)$/;
  function convertTimestamps(value: unknown): unknown {
    if (typeof value === "string" && ISO_DATETIME.test(value)) {
      return Timestamp.fromDate(new Date(value));
    }
    if (Array.isArray(value)) return value.map(convertTimestamps);
    if (value && typeof value === "object") {
      const out: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
        out[k] = convertTimestamps(v);
      }
      return out;
    }
    return value;
  }

  const { id, ...data } = article;
  const docData = convertTimestamps(data) as Record<string, unknown>;
  docData["updatedAt"] = Timestamp.now();

  const ref = db.collection("articles").doc(id);

  // Published-work guard: a draft re-run must not demote a published article,
  // and a template must not replace a Claude-written one. --force overrides.
  if (!force) {
    const existing = await ref.get();
    if (existing.exists) {
      const reason = protectedArticleReplacement(
        existing.data() as { status?: unknown; model?: unknown },
        article
      );
      if (reason) {
        console.log(`  - Firestore: articles/${id} skipped (${reason} — pass --force to overwrite)`);
        return;
      }
    }
  }

  await ref.set(docData, { merge: true });

  console.log(`  Firestore: upserted articles/${id}`);
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function processGame(
  gameId: string,
  seed: SeedData,
  publish: boolean,
  force: boolean
): Promise<void> {
  console.log(`\nProcessing game: ${gameId}`);

  const ctx = assembleGameContext(gameId, seed);
  // Refuse postponed/canceled up front — before any LLM call is spent.
  assertArticleEligible(ctx.game);
  const apiKey = process.env.ANTHROPIC_API_KEY;

  let editorial: Editorial;
  let model: string;

  if (!apiKey) {
    console.log("  ANTHROPIC_API_KEY not set — using seed_template fallback.");
    editorial = buildTemplateArticle(ctx);
    model = "seed_template";
  } else {
    console.log(`  ANTHROPIC_API_KEY present — calling Claude (${MODEL})...`);
    editorial = await generateWithLLM(ctx);
    model = MODEL;
    console.log("  LLM generation complete.");
  }

  const article = buildArticleDoc(gameId, ctx, editorial, model, publish);

  // Hard gate: refuse to write any article containing betting language.
  const term = findBettingLanguage(article);
  if (term) {
    throw new Error(
      `Betting language ("${term}") found in the generated article for ${gameId} — refusing to write it.`
    );
  }

  // Write to seed_data/generated/<gameId>.json
  mkdirSync(OUT_DIR, { recursive: true });
  const outPath = resolve(OUT_DIR, `${gameId}.json`);
  writeFileSync(outPath, JSON.stringify(article, null, 2), "utf8");
  console.log(`  Written: ${outPath} (status: ${article.status}, confidence: ${article.confidence})`);

  // Upsert to Firestore if emulator is running
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    await upsertToFirestore(article, force);
  }
}

async function main() {
  const seed = loadSeedData();
  const publish = process.argv.includes("--publish");
  const force = process.argv.includes("--force");
  if (!publish) {
    console.log("Articles will be written as DRAFTS — pass --publish to mark them published.");
  }

  // Parse --game=<id> arg
  const gameArg = process.argv.find((a) => a.startsWith("--game="));
  let gameIds: string[];

  if (gameArg) {
    const id = gameArg.split("=")[1];
    if (!id) {
      console.error("Error: --game= requires a value, e.g. --game=fb_2026_youngstown");
      process.exit(1);
    }
    gameIds = [id];
  } else {
    // Default: all featured games
    gameIds = seed.games
      .filter((g) => g.featured === true)
      .map((g) => g.id);

    if (gameIds.length === 0) {
      console.warn("No featured games found in seed data. Pass --game=<id> to target a specific game.");
      process.exit(0);
    }
    console.log(`No --game arg — processing ${gameIds.length} featured game(s): ${gameIds.join(", ")}`);
  }

  let successes = 0;
  let failures = 0;
  for (const id of gameIds) {
    try {
      await processGame(id, seed, publish, force);
      successes++;
    } catch (err) {
      console.error(`  Error processing ${id}:`, err instanceof Error ? err.message : err);
      failures++;
    }
  }

  console.log(`\nDone. ${successes} succeeded, ${failures} failed.`);
  process.exit(failures > 0 ? 1 : 0);
}

// Only run the CLI when executed directly (tsx generate_articles.ts) — importing
// this module (e.g. from functions/src/__tests__/articles.test.ts) must not
// trigger a generation run.
const entryPoint = process.argv[1] ? resolve(process.argv[1]) : "";
const thisFile = fileURLToPath(import.meta.url);
if (entryPoint && entryPoint.toLowerCase() === thisFile.toLowerCase()) {
  main().catch((err) => {
    console.error("Fatal error:", err);
    process.exit(1);
  });
}
