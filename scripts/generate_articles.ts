/**
 * AI Article Pipeline — generates preview or recap articles from seed/Firestore data.
 *
 * Usage:
 *   tsx generate_articles.ts --game=fb_2026_youngstown
 *   tsx generate_articles.ts           # processes all featured games
 *
 * Key-gated:
 *   - If ANTHROPIC_API_KEY is NOT set → deterministic seed_template article (offline-safe).
 *   - If ANTHROPIC_API_KEY IS set     → calls Claude via dynamic import (no install required
 *     for the fallback path).
 *
 * Output:
 *   - Writes seed_data/generated/<gameId>.json always.
 *   - If FIRESTORE_EMULATOR_HOST is set → upserts to Firestore `articles` collection.
 *
 * Security rules:
 *   - No secrets in code. Keys from env only.
 *   - No betting language (odds/wager/parlay/spread).
 *   - No University of Kentucky trademarks.
 *   - Stats come ONLY from stored data — never invented.
 */

import { readFileSync, mkdirSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

// ── Paths ─────────────────────────────────────────────────────────────────────

const __dirname = dirname(fileURLToPath(import.meta.url));
const SEED_PATH = resolve(__dirname, "../seed_data/dev_seed.json");
const OUT_DIR = resolve(__dirname, "../seed_data/generated");

// ── Model config ──────────────────────────────────────────────────────────────

const MODEL = process.env.ANTHROPIC_MODEL ?? "claude-opus-4-8";

// ── System prompt ─────────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `You are an elite independent college-sports journalist covering Kentucky Wildcats basketball and football.

HARD RULES — these override everything else:
1. Use ONLY the numbers provided in the user message. Never invent, estimate, or extrapolate statistics.
2. You are an independent fan voice — NOT an official University of Kentucky publication.
3. No betting language. Do not use: odds, wager, parlay, spread, over/under, line, ATS, pick against, moneyline.
4. No official University of Kentucky trademarks (no ®/™ marks, no licensed marks).
5. Write for a passionate fan audience — vivid, direct, analytically grounded prose.
6. Confidence values (theVerdict.confidence) must be a number between 0 and 100.
7. playerSpotlights: name only players whose stats appear in the data — no invented rosters.
8. Keep openingNarrative under 120 words. tacticalBreakdown.narrative under 100 words. theVerdict.narrative under 80 words. closingLine under 25 words.`;

// ── Zod schema for editorial output ──────────────────────────────────────────

// Zod is imported dynamically only in the LLM branch; for the template branch
// we replicate the shape manually. The import below is static because zod is
// in our dep tree (scripts/package.json) and used for type inference.
import { z } from "zod";

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
    confidence: z.number(),
    narrative: z.string(),
  }),
  closingLine: z.string(),
});

type Editorial = z.infer<typeof EditorialSchema>;

// ── Seed data types ───────────────────────────────────────────────────────────

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
  status: "scheduled" | "final" | "live" | "postponed" | "canceled";
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
  concernMeter?: { level: string; note: string };
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
  classYear?: string;
  jersey?: number;
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
  [key: string]: unknown;
}

// ── Game context (what we send to the LLM) ───────────────────────────────────

interface GameContext {
  game: SeedGame;
  summary?: GameSummary;
  teamStats?: TeamStat;
  relevantPlayerStats: Array<{
    profile: PlayerProfile;
    stats: Record<string, number | string | null>;
  }>;
}

// ── Article output shape ──────────────────────────────────────────────────────

interface ArticleDoc {
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
  publishedAt: string;
  confidence: string;
  featured?: boolean;
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
    .map((profile) => {
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
      return { profile, stats: statDoc.stats };
    })
    .filter((x): x is { profile: PlayerProfile; stats: Record<string, number | string | null> } =>
      x !== null
    );

  return { game, summary, teamStats, relevantPlayerStats };
}

// ── Template fallback (no API key) ───────────────────────────────────────────

export function buildTemplateArticle(ctx: GameContext): Editorial {
  const { game, summary, teamStats } = ctx;
  const isPreview = game.status === "scheduled" || game.status === "live";
  const opponent = game.opponentName;
  const venue = game.venue ?? "home";
  const sport = game.sport;

  // ---------- headline / subheadline ----------
  let headline: string;
  let subheadline: string;

  if (isPreview) {
    headline = `${sport === "football" ? "Cats Host" : "Kentucky Welcomes"} ${opponent} — By the Numbers`;
    subheadline = summary?.statStory
      ? summary.statStory.split(".")[0] + "."
      : `Matchup preview for the upcoming game at ${venue}.`;
  } else {
    const homeScore = game.homeScore ?? 0;
    const awayScore = game.awayScore ?? 0;
    const wonLost =
      game.isHome
        ? homeScore > awayScore
          ? "Win"
          : "Loss"
        : awayScore > homeScore
        ? "Win"
        : "Loss";
    headline = `Kentucky ${wonLost}: Wildcats vs. ${opponent} — Final Recap`;
    subheadline = `A look at the numbers behind the final result.`;
  }

  // ---------- openingNarrative ----------
  let openingNarrative: string;
  if (summary?.statStory) {
    openingNarrative = summary.statStory;
  } else if (isPreview) {
    openingNarrative = `Kentucky returns to ${venue} to take on ${opponent}. The numbers favor the Wildcats — the edge lies in execution.`;
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
    prediction = margin > 0 ? `Kentucky ${margin > 0 ? "wins" : "loses"} by ${Math.abs(margin)}` : `Final: ${homeScore}–${awayScore}`;
  }

  const verdictNarrative =
    summary?.keysToGame?.[2] ??
    (isPreview
      ? "Execute the gameplan, protect the football, and this one goes Kentucky's way."
      : "The final score reflects Kentucky's execution when it mattered most.");

  // ---------- closingLine ----------
  const closingLine = isPreview
    ? `Game time at ${venue} — the numbers like the home team.`
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
      confidence,
      narrative: verdictNarrative,
    },
    closingLine,
  };
}

// ── Provenance stamping ───────────────────────────────────────────────────────

function buildArticleDoc(
  gameId: string,
  ctx: GameContext,
  editorial: Editorial,
  model: string
): ArticleDoc {
  const { game, summary, teamStats } = ctx;

  const articleType: "preview" | "recap" | "stat_story" =
    game.status === "scheduled" || game.status === "live" ? "preview" : "recap";

  const sources: string[] = [];
  if (teamStats) sources.push(`seed_demo:team_stats/${teamStats.id}`);
  if (summary) sources.push(`seed_demo:game_summaries/${gameId}`);
  sources.push(`seed_demo:games/${gameId}`);

  const now = new Date().toISOString();

  return {
    id: `article_${gameId}_${articleType}`,
    type: articleType,
    gameId,
    sport: game.sport,
    status: "published",
    headline: editorial.headline,
    subheadline: editorial.subheadline,
    openingNarrative: editorial.openingNarrative,
    tacticalBreakdown: editorial.tacticalBreakdown,
    byTheNumbers: editorial.byTheNumbers,
    playerSpotlights: editorial.playerSpotlights.map((sp, i) => {
      const profile = ctx.relevantPlayerStats[i]?.profile;
      return {
        playerId: profile?.id,
        name: sp.name,
        position: sp.position,
        narrative: sp.narrative,
        statline: sp.statline,
      };
    }),
    theVerdict: editorial.theVerdict,
    closingLine: editorial.closingLine,
    sources,
    model,
    generatedAt: now,
    publishedAt: now,
    confidence: "demo",
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
    output_config: { effort: "medium", format: zodOutputFormat(EditorialSchema, "editorial") },
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

async function upsertToFirestore(article: ArticleDoc): Promise<void> {
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

  await db
    .collection("articles")
    .doc(id)
    .set(docData, { merge: true });

  console.log(`  Firestore: upserted articles/${id}`);
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function processGame(gameId: string, seed: SeedData): Promise<void> {
  console.log(`\nProcessing game: ${gameId}`);

  const ctx = assembleGameContext(gameId, seed);
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

  const article = buildArticleDoc(gameId, ctx, editorial, model);

  // Write to seed_data/generated/<gameId>.json
  mkdirSync(OUT_DIR, { recursive: true });
  const outPath = resolve(OUT_DIR, `${gameId}.json`);
  writeFileSync(outPath, JSON.stringify(article, null, 2), "utf8");
  console.log(`  Written: ${outPath}`);

  // Upsert to Firestore if emulator is running
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    await upsertToFirestore(article);
  }
}

async function main() {
  const seed = loadSeedData();

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
      await processGame(id, seed);
      successes++;
    } catch (err) {
      console.error(`  Error processing ${id}:`, err instanceof Error ? err.message : err);
      failures++;
    }
  }

  console.log(`\nDone. ${successes} succeeded, ${failures} failed.`);
  process.exit(failures > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
