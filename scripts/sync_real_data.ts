/**
 * Sync REAL Kentucky Wildcats data into the dev seed.
 *
 * Replaces the illustrative DEMO stat values in seed_data/dev_seed.json with REAL
 * Kentucky data fetched live from:
 *   - CollegeFootballData  (CFBD)  — https://api.collegefootballdata.com   (2025 football)
 *   - CollegeBasketballData (CBBD) — https://api.collegebasketballdata.com (2025-26 men's hoops, season=2026)
 *
 * What it updates (surgical, array-targeted — the rest of the file is preserved):
 *   - team_stats/kentucky_football_2025_season          (source: cfbd, confidence: official)
 *   - team_stats/kentucky_mens_basketball_2026_season   (source: cbbd, confidence: official)
 *   - player_profiles  (the 6 existing slot IDs, filled with the real mapped player)
 *   - player_stats     (real season stats for those 6 players)
 *
 * The 6 player slots map to:
 *   fb_qb_demo  -> primary QB (most passing yards)
 *   fb_rb_demo  -> lead rusher (most rushing yards)
 *   fb_wr_demo  -> leading receiver (most receiving yards)
 *   mbb_g_demo1 -> top guard by points
 *   mbb_g_demo2 -> second guard by points
 *   mbb_f_demo  -> top forward/center by points
 *
 * ACCURACY: Only real API values are written. If the API does not return a field,
 * the previous value is dropped (not fabricated) and noted in the run summary.
 *
 * Usage (corporate SSL-inspection proxy may break Node's TLS — disable verify for
 * LOCAL DEV ONLY via NODE_TLS_REJECT_UNAUTHORIZED=0, which the `sync-data` npm
 * script sets through cross-env):
 *   npm run sync-data            (from repo root)
 *   npm --prefix scripts run sync-data
 *
 * No secrets in code. Keys are read from .env.local (root or functions/). Nothing is logged.
 */
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

// ── Paths ─────────────────────────────────────────────────────────────────────

const __dirname = dirname(fileURLToPath(import.meta.url));
const SEED = resolve(__dirname, "../seed_data/dev_seed.json");
const ASSET = resolve(__dirname, "../apps/mobile_flutter/assets/seed/dev_seed.json");

// ── Load .env.local (gitignored) into process.env (same pattern as check_keys.ts) ──
for (const envPath of [
  resolve(__dirname, "../.env.local"),
  resolve(__dirname, "../functions/.env.local"),
]) {
  if (!existsSync(envPath)) continue;
  for (const line of readFileSync(envPath, "utf8").split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, "");
  }
}

const CFBD_KEY = process.env.CFBD_API_KEY ?? "";
const CBBD_KEY = process.env.CBBD_API_KEY ?? "";
const CFBD_BASE = "https://api.collegefootballdata.com";
const CBBD_BASE = "https://api.collegebasketballdata.com";

const FOOTBALL_YEAR = 2025; // 2025 football season
const BASKETBALL_SEASON = 2026; // CBBD labels 2025-26 as season=2026

if (!CFBD_KEY) throw new Error("CFBD_API_KEY not set (add it to functions/.env.local).");
if (!CBBD_KEY) throw new Error("CBBD_API_KEY not set (add it to functions/.env.local).");

// ── HTTP helpers ──────────────────────────────────────────────────────────────

async function getJson<T>(base: string, path: string, key: string): Promise<T> {
  const res = await fetch(base + path, {
    headers: { Authorization: `Bearer ${key}`, Accept: "application/json" },
  });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${path}: ${(await res.text()).slice(0, 200)}`);
  const text = await res.text();
  // CBBD serves a Swagger HTML page (200) for unknown routes — guard against that.
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new Error(`Non-JSON response for ${path} (route may not exist): ${text.slice(0, 120)}`);
  }
  return parsed as T;
}

// Round to n decimals, returning a number (null passes through).
const r = (v: number | null | undefined, n = 1): number | null =>
  v == null || Number.isNaN(v) ? null : Number(v.toFixed(n));

// Inches -> "F-I" height string (e.g. 77 -> "6-5").
const heightStr = (inches: number | null | undefined): string | null =>
  inches == null || inches <= 0 ? null : `${Math.floor(inches / 12)}-${inches % 12}`;

// CFBD roster `year` integer -> class abbreviation.
const classYear = (year: number | null | undefined): string | null =>
  ({ 1: "FR", 2: "SO", 3: "JR", 4: "SR", 5: "SR" } as Record<number, string>)[year ?? 0] ?? null;

const hometown = (city?: string | null, state?: string | null): string | null =>
  city && state ? `${city}, ${state}` : city ?? null;

// Drop null/undefined entries so we never write a fabricated/empty value.
function clean<T extends Record<string, unknown>>(o: T): Partial<T> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(o)) if (v != null) out[k] = v;
  return out as Partial<T>;
}

// ── CFBD wire types ─────────────────────────────────────────────────────────────

interface CfbdSeasonStat { statName: string; statValue: number }
interface CfbdRecord {
  total: { games: number; wins: number; losses: number; ties: number };
}
interface CfbdGame {
  homeTeam: string; awayTeam: string; homePoints: number | null; awayPoints: number | null;
  startDate?: string;
}
interface CfbdAdvanced {
  offense: { plays: number; ppa: number; successRate: number; explosiveness: number };
  defense: { ppa: number };
}
interface CfbdPlayerSeasonStat {
  playerId: string; player: string; position: string; category: string; statType: string; stat: string;
}
interface CfbdRosterPlayer {
  id: string; firstName: string; lastName: string; weight: number | null; height: number | null;
  jersey: number | null; year: number | null; position: string;
  homeCity: string | null; homeState: string | null;
}

// ── CBBD wire types ─────────────────────────────────────────────────────────────

interface CbbdTeamSeason {
  games: number; wins: number; losses: number; pace: number;
  teamStats: CbbdTeamSide; opponentStats: CbbdTeamSide;
}
interface CbbdTeamSide {
  rating: number; trueShooting: number;
  fieldGoals: Pct; threePointFieldGoals: Pct; freeThrows: Pct;
  rebounds: { offensive: number; defensive: number; total: number };
  assists: number; turnovers: { total: number };
  points: { total: number };
  fourFactors: { effectiveFieldGoalPct: number; turnoverRatio: number; offensiveReboundPct: number; freeThrowRate: number };
}
interface Pct { made: number; attempted: number; pct: number }
interface CbbdAdjusted { offensiveRating: number; defensiveRating: number; netRating: number }
interface CbbdPlayerSeason {
  athleteId: number; name: string; position: string; games: number; starts: number;
  minutes: number; points: number; assists: number; steals: number; blocks: number; turnovers: number;
  usage: number; assistsTurnoverRatio: number; offensiveReboundPct: number;
  effectiveFieldGoalPct: number; trueShootingPct: number;
  fieldGoals: Pct; threePointFieldGoals: Pct; freeThrows: Pct;
  rebounds: { offensive: number; defensive: number; total: number };
}
interface CbbdRosterPlayer {
  id: number; name: string; jersey: string; position: string;
  height: number | null; weight: number | null;
  hometown: { city: string | null; state: string | null } | null;
}

// ── Fetch + transform: FOOTBALL ─────────────────────────────────────────────────

interface MappedProfile {
  id: string; name: string; teamId: string; sport: string; position: string;
  classYear?: string; height?: string; weight?: string; hometown?: string; jersey?: number;
  active: boolean; source: string; sourceId?: string;
}
interface MappedTeamStat {
  id: string; teamId: string; season: number; sport: string; scope: string;
  stats: Record<string, number | string | null>;
  rankings?: Record<string, number>;
  source: string; updatedAt: string; confidence: string; note?: string;
}
interface MappedPlayerStat {
  id: string; playerId: string; teamId: string; season: number; sport: string; scope: string;
  stats: Record<string, number | string | null>;
  source: string; updatedAt: string; confidence: string;
}

async function syncFootball(now: string, missing: string[]) {
  const FB = "kentucky_football";
  const seasonStatsArr = await getJson<CfbdSeasonStat[]>(
    CFBD_BASE, `/stats/season?year=${FOOTBALL_YEAR}&team=Kentucky`, CFBD_KEY,
  );
  const S: Record<string, number> = {};
  for (const s of seasonStatsArr) S[s.statName] = s.statValue;

  const recArr = await getJson<CfbdRecord[]>(CFBD_BASE, `/records?year=${FOOTBALL_YEAR}&team=Kentucky`, CFBD_KEY);
  const rec = recArr[0]?.total;
  // Never guess a denominator: when neither /records nor /stats/season returns
  // the game count, per-game values are omitted (not fabricated over 12).
  const games: number | null = rec?.games ?? S["games"] ?? null;
  const record = rec ? `${rec.wins}-${rec.losses}` : null;
  if (!games) missing.push("football games played (per-game values omitted — no game count from /records or /stats/season)");

  // Points scored / allowed from the games list (not exposed in /stats/season).
  const gamesArr = await getJson<CfbdGame[]>(
    CFBD_BASE, `/games?year=${FOOTBALL_YEAR}&team=Kentucky&seasonType=regular`, CFBD_KEY,
  );
  let pf = 0, pa = 0, scored = 0;
  for (const g of gamesArr) {
    if (g.homePoints == null || g.awayPoints == null) continue;
    const home = g.homeTeam === "Kentucky";
    pf += home ? g.homePoints : g.awayPoints;
    pa += home ? g.awayPoints : g.homePoints;
    scored++;
  }

  const advArr = await getJson<CfbdAdvanced[]>(
    CFBD_BASE, `/stats/season/advanced?year=${FOOTBALL_YEAR}&team=Kentucky`, CFBD_KEY,
  );
  const adv = advArr[0];

  const plays = adv?.offense.plays ?? null;
  const teamStat: MappedTeamStat = {
    id: "kentucky_football_2025_season",
    teamId: FB, season: FOOTBALL_YEAR, sport: "football", scope: "season",
    stats: clean({
      record,
      pointsPerGame: scored ? r(pf / scored) : null,
      pointsAllowedPerGame: scored ? r(pa / scored) : null,
      yardsPerPlay: plays ? r(S["totalYards"] / plays, 2) : null,
      totalYardsPerGame: games ? r(S["totalYards"] / games) : null,
      passingYardsPerGame: games ? r(S["netPassingYards"] / games) : null,
      rushingYardsPerGame: games ? r(S["rushingYards"] / games) : null,
      thirdDownPct: S["thirdDowns"] ? r(S["thirdDownConversions"] / S["thirdDowns"], 3) : null,
      turnoverMargin: games ? r((S["turnoversOpponent"] - S["turnovers"]) / games, 2) : null,
      takeaways: S["turnoversOpponent"] ?? null,
      giveaways: S["turnovers"] ?? null,
      sacksPerGame: games ? r(S["sacks"] / games, 2) : null,
      successRate: r(adv?.offense.successRate ?? null, 3),
      explosiveness: r(adv?.offense.explosiveness ?? null, 3),
      ppaOffense: r(adv?.offense.ppa ?? null, 3),
      ppaDefense: r(adv?.defense.ppa ?? null, 3),
    }) as Record<string, number | string | null>,
    source: "cfbd", updatedAt: now, confidence: "official",
    note: `Real ${FOOTBALL_YEAR} CFBD data. ${games
      ? `Per-game values derived from season totals over ${games} games; `
      : "Per-game values omitted (game count unavailable from CFBD); "
    }points from the game log. redZoneScorePct/QBR not provided by the available CFBD tier.`,
  };
  if (!record) missing.push("football record (/records)");

  // ── Player aggregation (long -> per-player) ──
  const psArr = await getJson<CfbdPlayerSeasonStat[]>(
    CFBD_BASE, `/stats/player/season?year=${FOOTBALL_YEAR}&team=Kentucky`, CFBD_KEY,
  );
  const players: Record<string, { id: string; name: string; position: string; st: Record<string, number> }> = {};
  for (const p of psArr) {
    players[p.playerId] ??= { id: p.playerId, name: p.player, position: p.position, st: {} };
    const num = Number(p.stat);
    if (!Number.isNaN(num)) players[p.playerId].st[`${p.category}.${p.statType}`] = num;
  }
  const all = Object.values(players);
  const top = (key: string) =>
    all.filter((p) => p.st[key] != null).sort((a, b) => b.st[key] - a.st[key])[0];

  const qb = top("passing.YDS");
  const rb = top("rushing.YDS");
  const wr = top("receiving.YDS");

  const rosterArr = await getJson<CfbdRosterPlayer[]>(
    CFBD_BASE, `/roster?team=Kentucky&year=${FOOTBALL_YEAR}`, CFBD_KEY,
  );
  const roster: Record<string, CfbdRosterPlayer> = {};
  for (const rp of rosterArr) roster[rp.id] = rp;

  const fbProfile = (slot: string, p: typeof qb, pos: string): MappedProfile => {
    const rp = roster[p.id];
    return clean({
      id: slot, name: p.name, teamId: FB, sport: "football", position: rp?.position ?? pos,
      classYear: classYear(rp?.year) ?? undefined,
      height: heightStr(rp?.height) ?? undefined,
      weight: rp?.weight != null ? String(rp.weight) : undefined,
      hometown: hometown(rp?.homeCity, rp?.homeState) ?? undefined,
      jersey: rp?.jersey ?? undefined,
      active: true, source: "cfbd", sourceId: p.id,
    }) as MappedProfile;
  };

  const profiles: MappedProfile[] = [
    fbProfile("fb_qb_demo", qb, "QB"),
    fbProfile("fb_rb_demo", rb, "RB"),
    fbProfile("fb_wr_demo", wr, "WR"),
  ];

  const stats: MappedPlayerStat[] = [
    {
      id: "fb_qb_demo_2025", playerId: "fb_qb_demo", teamId: FB, season: FOOTBALL_YEAR,
      sport: "football", scope: "season",
      stats: clean({
        passYards: qb.st["passing.YDS"], passTds: qb.st["passing.TD"], interceptions: qb.st["passing.INT"],
        completions: qb.st["passing.COMPLETIONS"], passAttempts: qb.st["passing.ATT"],
        completionPct: qb.st["passing.PCT"], yardsPerAttempt: qb.st["passing.YPA"],
        rushYards: qb.st["rushing.YDS"], rushTds: qb.st["rushing.TD"],
      }) as Record<string, number | string | null>,
      source: "cfbd", updatedAt: now, confidence: "official",
    },
    {
      id: "fb_rb_demo_2025", playerId: "fb_rb_demo", teamId: FB, season: FOOTBALL_YEAR,
      sport: "football", scope: "season",
      stats: clean({
        rushYards: rb.st["rushing.YDS"], rushTds: rb.st["rushing.TD"], carries: rb.st["rushing.CAR"],
        yardsPerCarry: rb.st["rushing.YPC"], longRush: rb.st["rushing.LONG"],
        receptions: rb.st["receiving.REC"], recYards: rb.st["receiving.YDS"], recTds: rb.st["receiving.TD"],
      }) as Record<string, number | string | null>,
      source: "cfbd", updatedAt: now, confidence: "official",
    },
    {
      id: "fb_wr_demo_2025", playerId: "fb_wr_demo", teamId: FB, season: FOOTBALL_YEAR,
      sport: "football", scope: "season",
      stats: clean({
        receptions: wr.st["receiving.REC"], recYards: wr.st["receiving.YDS"], recTds: wr.st["receiving.TD"],
        yardsPerCatch: wr.st["receiving.YPR"], longRec: wr.st["receiving.LONG"],
      }) as Record<string, number | string | null>,
      source: "cfbd", updatedAt: now, confidence: "official",
    },
  ];

  return { teamStat, profiles, stats, picks: { qb, rb, wr }, gamesArr };
}

// ── Fetch + transform: BASKETBALL ───────────────────────────────────────────────

async function syncBasketball(now: string, missing: string[]) {
  const MBB = "kentucky_mens_basketball";

  const teamArr = await getJson<CbbdTeamSeason[]>(
    CBBD_BASE, `/stats/team/season?season=${BASKETBALL_SEASON}&team=Kentucky`, CBBD_KEY,
  );
  const t = teamArr[0];
  if (!t) throw new Error("CBBD team season stats returned no row for Kentucky.");
  const g = t.games;
  const ts = t.teamStats;
  const os = t.opponentStats;

  let adj: CbbdAdjusted | undefined;
  try {
    const adjArr = await getJson<CbbdAdjusted[]>(
      CBBD_BASE, `/ratings/adjusted?season=${BASKETBALL_SEASON}&team=Kentucky`, CBBD_KEY,
    );
    adj = adjArr[0];
  } catch {
    missing.push("basketball adjusted ratings (/ratings/adjusted)");
  }

  const teamStat: MappedTeamStat = {
    id: "kentucky_mens_basketball_2026_season",
    teamId: MBB, season: BASKETBALL_SEASON, sport: "mens_basketball", scope: "season",
    stats: clean({
      record: `${t.wins}-${t.losses}`,
      pointsPerGame: r(ts.points.total / g),
      pointsAllowedPerGame: r(os.points.total / g),
      fieldGoalPct: r(ts.fieldGoals.pct / 100, 3),
      threePointPct: r(ts.threePointFieldGoals.pct / 100, 3),
      freeThrowPct: r(ts.freeThrows.pct / 100, 3),
      reboundsPerGame: r(ts.rebounds.total / g),
      assistsPerGame: r(ts.assists / g),
      turnoversPerGame: r(ts.turnovers.total / g),
      offensiveRating: r(ts.rating),
      defensiveRating: r(os.rating),
      adjOffRating: r(adj?.offensiveRating ?? null),
      adjDefRating: r(adj?.defensiveRating ?? null),
      adjNetRating: r(adj?.netRating ?? null),
      tempo: r(t.pace),
      effectiveFgPct: r(ts.fourFactors.effectiveFieldGoalPct / 100, 3),
      trueShootingPct: r(ts.trueShooting / 100, 3),
      turnoverRate: r(ts.fourFactors.turnoverRatio, 3),
      offReboundRate: r(ts.fourFactors.offensiveReboundPct / 100, 3),
      freeThrowRate: r(ts.fourFactors.freeThrowRate / 100, 3),
    }) as Record<string, number | string | null>,
    source: "cbbd", updatedAt: now, confidence: "official",
    note: "Real 2025-26 (season=2026) CBBD data. Per-game values derived from season totals; rates from CBBD four factors.",
  };

  // Players: top 2 guards by points + top forward/center by points.
  const playersArr = await getJson<CbbdPlayerSeason[]>(
    CBBD_BASE, `/stats/player/season?season=${BASKETBALL_SEASON}&team=Kentucky`, CBBD_KEY,
  );
  const byPoints = [...playersArr].sort((a, b) => b.points - a.points);
  const guards = byPoints.filter((p) => p.position === "G");
  const bigs = byPoints.filter((p) => p.position === "F" || p.position === "C");
  const g1 = guards[0];
  const g2 = guards[1];
  const f1 = bigs[0];
  if (!g1 || !g2) missing.push("two guards (CBBD player season)");
  if (!f1) missing.push("forward/center (CBBD player season)");

  const rosterArr = await getJson<{ players: CbbdRosterPlayer[] }[]>(
    CBBD_BASE, `/teams/roster?team=Kentucky&season=${BASKETBALL_SEASON}`, CBBD_KEY,
  );
  const roster: Record<number, CbbdRosterPlayer> = {};
  for (const rp of rosterArr[0]?.players ?? []) roster[rp.id] = rp;

  // CBBD roster carries no class/year — note it once.
  if (!missing.includes("basketball classYear (not in CBBD roster)"))
    missing.push("basketball classYear (not in CBBD roster)");

  const posWord = (short: string) =>
    ({ G: "G", F: "F", C: "C" } as Record<string, string>)[short] ?? short;

  const bbProfile = (slot: string, p: CbbdPlayerSeason): MappedProfile => {
    const rp = roster[p.athleteId];
    const jerseyNum = rp?.jersey != null ? Number(rp.jersey) : NaN;
    return clean({
      id: slot, name: p.name, teamId: MBB, sport: "mens_basketball",
      position: posWord(p.position),
      // classYear intentionally omitted — CBBD roster does not provide it.
      height: heightStr(rp?.height) ?? undefined,
      weight: rp?.weight != null ? String(rp.weight) : undefined,
      hometown: hometown(rp?.hometown?.city, rp?.hometown?.state) ?? undefined,
      jersey: Number.isNaN(jerseyNum) ? undefined : jerseyNum,
      active: true, source: "cbbd", sourceId: String(p.athleteId),
    }) as MappedProfile;
  };

  const bbStat = (id: string, slot: string, p: CbbdPlayerSeason, extra: Record<string, number | null>): MappedPlayerStat => ({
    id, playerId: slot, teamId: MBB, season: BASKETBALL_SEASON, sport: "mens_basketball", scope: "season",
    stats: clean({
      points: r(p.points / p.games),
      rebounds: r(p.rebounds.total / p.games),
      assists: r(p.assists / p.games),
      effectiveFgPct: r(p.effectiveFieldGoalPct / 100, 3),
      threePointPct: r(p.threePointFieldGoals.pct / 100, 3),
      trueShootingPct: r(p.trueShootingPct, 3),
      usageRate: r(p.usage / 100, 3),
      ...extra,
    }) as Record<string, number | string | null>,
    source: "cbbd", updatedAt: now, confidence: "official",
  });

  const profiles: MappedProfile[] = [
    bbProfile("mbb_g_demo1", g1),
    bbProfile("mbb_g_demo2", g2),
    bbProfile("mbb_f_demo", f1),
  ];
  const stats: MappedPlayerStat[] = [
    bbStat("mbb_g_demo1_2026", "mbb_g_demo1", g1, { stealsPerGame: r(g1.steals / g1.games) }),
    bbStat("mbb_g_demo2_2026", "mbb_g_demo2", g2, { assistTurnoverRatio: r(g2.assistsTurnoverRatio, 2) }),
    bbStat("mbb_f_demo_2026", "mbb_f_demo", f1, {
      blocksPerGame: r(f1.blocks / f1.games),
      offReboundRate: r(f1.offensiveReboundPct / 100, 3),
    }),
  ];

  return { teamStat, profiles, stats, picks: { g1, g2, f1 } };
}

// ── Surgical seed update (replace one top-level array, preserve everything else) ──

function replaceArray(text: string, key: string, value: unknown[]): string {
  // Match `"<key>": [ ... ]` at top-level (2-space indent), non-greedy through the
  // matching close. The seed is hand-formatted with each top-level key at indent 2.
  const re = new RegExp(`(\\n  "${key}":\\s*)\\[[\\s\\S]*?\\n  \\]`, "");
  if (!re.test(text)) throw new Error(`Could not locate top-level array "${key}" in seed.`);
  const body = JSON.stringify(value, null, 2).replace(/\n/g, "\n  "); // re-indent to 2 spaces
  return text.replace(re, `$1${body}`);
}

// Rewrite _meta.description so the file's self-description can't drift from
// what the sync actually wrote (the old text claimed all stat values were demo
// long after they became real).
const META_DESCRIPTION =
  "Bluegrass Gameday development seed data. SCHEDULE/opponents are the REAL 2026 Kentucky football schedule plus a REAL 2025 result (Eastern Michigan); the 2026-27 basketball slate is tentative (schedule not yet released). team_stats and player_stats carry REAL synced values (source: cfbd/cbbd, confidence: official) refreshed via npm run sync-data; player ids like fb_qb_demo are legacy slot slugs that now hold real CFBD/CBBD players — do not rename them (player_stats and articles reference them). game_summaries, predictions, polls, recruits, high_school_games and users remain illustrative demo content (source: seed_demo or manual, confidence: demo). No official UK marks, no copyrighted article text, no real athlete likenesses for collectibles.";

function replaceMetaDescription(text: string, desc: string): string {
  const re = /("_meta":\s*\{\s*\r?\n\s*"description":\s*")(?:[^"\\]|\\.)*(")/;
  if (!re.test(text)) throw new Error('Could not locate _meta.description in seed.');
  return text.replace(re, `$1${desc.replace(/[\\"]/g, (c) => "\\" + c)}$2`);
}

// ── Games verification (schedule facts reconciled against CFBD) ────────────────
// The seed's games array is the app's factual anchor for opponents, dates,
// home/away and final scores. For the synced football season we check each seed
// game against the CFBD game log already fetched: rows that match get stamped
// source:"cfbd" / confidence:"official"; mismatches are REPORTED, never silently
// overwritten (real data may reveal a hand-entry typo that needs a human look).

interface SeedGameRow {
  id: string;
  sport?: string;
  season?: number;
  opponentName?: string;
  homeTeamId?: string;
  startTime?: string;
  status?: string;
  homeScore?: number | null;
  awayScore?: number | null;
  [k: string]: unknown;
}

function reconcileFootballGames(
  seedGames: SeedGameRow[],
  cfbdGames: CfbdGame[],
  now: string,
  notes: string[],
): SeedGameRow[] {
  return seedGames.map((g) => {
    if (g.sport !== "football" || g.season !== FOOTBALL_YEAR) return g;
    const row = cfbdGames.find((c) => {
      const opp = c.homeTeam === "Kentucky" ? c.awayTeam : c.homeTeam;
      return opp === g.opponentName;
    });
    if (!row) {
      notes.push(`games/${g.id}: no CFBD ${FOOTBALL_YEAR} row for opponent "${g.opponentName}" — left as-is`);
      return g;
    }
    const cfbdKyHome = row.homeTeam === "Kentucky";
    const seedKyHome = g.homeTeamId === "kentucky_football";
    const dtSeed = g.startTime ? Date.parse(g.startTime) : NaN;
    const dtCfbd = row.startDate ? Date.parse(row.startDate) : NaN;
    const sameDay =
      Number.isFinite(dtSeed) && Number.isFinite(dtCfbd) &&
      Math.abs(dtSeed - dtCfbd) < 36 * 3600 * 1000;
    const cfbdKy = cfbdKyHome ? row.homePoints : row.awayPoints;
    const cfbdOpp = cfbdKyHome ? row.awayPoints : row.homePoints;
    const seedKy = seedKyHome ? g.homeScore : g.awayScore;
    const seedOpp = seedKyHome ? g.awayScore : g.homeScore;
    const scoresMatch = g.status !== "final" || (seedKy === cfbdKy && seedOpp === cfbdOpp);
    if (cfbdKyHome === seedKyHome && sameDay && scoresMatch) {
      return { ...g, source: "cfbd", updatedAt: now, confidence: "official" };
    }
    notes.push(
      `games/${g.id}: CFBD MISMATCH (home ${seedKyHome}/${cfbdKyHome}, sameDay ${sameDay}, ` +
        `score seed ${seedKy}-${seedOpp} vs cfbd ${cfbdKy}-${cfbdOpp}) — NOT overwritten, verify by hand`,
    );
    return g;
  });
}

// ── Main ────────────────────────────────────────────────────────────────────────

async function main() {
  const now = new Date().toISOString();
  const missing: string[] = [];

  console.log("Fetching REAL Kentucky data (football=2025 CFBD, basketball=2025-26 CBBD)...");
  const fb = await syncFootball(now, missing);
  const bb = await syncBasketball(now, missing);

  const original = readFileSync(SEED, "utf8");

  const teamStats = [fb.teamStat, bb.teamStat];
  const playerProfiles = [...fb.profiles, ...bb.profiles];
  const playerStats = [...fb.stats, ...bb.stats];

  // Verify hand-entered schedule facts against the CFBD game log (matches get
  // stamped official; mismatches are reported below, never overwritten).
  const gameNotes: string[] = [];
  const seedGames = (JSON.parse(original) as { games?: SeedGameRow[] }).games ?? [];
  const reconciledGames = reconcileFootballGames(seedGames, fb.gamesArr, now, gameNotes);

  let out = original;
  out = replaceArray(out, "games", reconciledGames);
  out = replaceArray(out, "team_stats", teamStats);
  out = replaceArray(out, "player_profiles", playerProfiles);
  out = replaceArray(out, "player_stats", playerStats);
  out = replaceMetaDescription(out, META_DESCRIPTION);

  JSON.parse(out); // validate before writing — throws on any malformed result
  writeFileSync(SEED, out);
  if (existsSync(dirname(ASSET))) writeFileSync(ASSET, out);

  // ── Summary ──
  const { qb, rb, wr } = fb.picks;
  const { g1, g2, f1 } = bb.picks;
  console.log("\n================ REAL DATA WRITTEN ================");
  console.log(`Football team (2025): record ${fb.teamStat.stats.record}, ` +
    `PPG ${fb.teamStat.stats.pointsPerGame}, PA/G ${fb.teamStat.stats.pointsAllowedPerGame}, ` +
    `Y/play ${fb.teamStat.stats.yardsPerPlay}, rush ${fb.teamStat.stats.rushingYardsPerGame}/g, ` +
    `pass ${fb.teamStat.stats.passingYardsPerGame}/g, 3rd-down ${fb.teamStat.stats.thirdDownPct}, ` +
    `TO margin ${fb.teamStat.stats.turnoverMargin}, PPA off ${fb.teamStat.stats.ppaOffense}/def ${fb.teamStat.stats.ppaDefense}`);
  console.log(`Basketball team (2025-26): record ${bb.teamStat.stats.record}, ` +
    `PPG ${bb.teamStat.stats.pointsPerGame}, PA/G ${bb.teamStat.stats.pointsAllowedPerGame}, ` +
    `adjOff ${bb.teamStat.stats.adjOffRating}/adjDef ${bb.teamStat.stats.adjDefRating}/net ${bb.teamStat.stats.adjNetRating}, ` +
    `tempo ${bb.teamStat.stats.tempo}, eFG ${bb.teamStat.stats.effectiveFgPct}, 3P ${bb.teamStat.stats.threePointPct}`);
  console.log("\nPlayer slots -> real player (key stat line):");
  const fbs = fb.stats;
  console.log(`  fb_qb_demo  -> ${qb.name} (QB): ${fbs[0].stats.passYards} pass yds, ${fbs[0].stats.passTds} TD, ${fbs[0].stats.interceptions} INT, ${fbs[0].stats.completionPct} comp%, ${fbs[0].stats.rushYards} rush yds`);
  console.log(`  fb_rb_demo  -> ${rb.name} (RB): ${fbs[1].stats.rushYards} rush yds, ${fbs[1].stats.rushTds} TD, ${fbs[1].stats.yardsPerCarry} YPC, ${fbs[1].stats.receptions} rec/${fbs[1].stats.recYards} yds`);
  console.log(`  fb_wr_demo  -> ${wr.name} (WR): ${fbs[2].stats.receptions} rec, ${fbs[2].stats.recYards} yds, ${fbs[2].stats.recTds} TD, ${fbs[2].stats.yardsPerCatch} yds/catch`);
  const bbs = bb.stats;
  console.log(`  mbb_g_demo1 -> ${g1.name} (${g1.position}): ${bbs[0].stats.points} PPG, ${bbs[0].stats.rebounds} REB, ${bbs[0].stats.assists} AST, ${bbs[0].stats.effectiveFgPct} eFG, ${bbs[0].stats.threePointPct} 3P, ${bbs[0].stats.usageRate} usg`);
  console.log(`  mbb_g_demo2 -> ${g2.name} (${g2.position}): ${bbs[1].stats.points} PPG, ${bbs[1].stats.rebounds} REB, ${bbs[1].stats.assists} AST, ${bbs[1].stats.effectiveFgPct} eFG, ${bbs[1].stats.threePointPct} 3P`);
  console.log(`  mbb_f_demo  -> ${f1.name} (${f1.position}): ${bbs[2].stats.points} PPG, ${bbs[2].stats.rebounds} REB, ${bbs[2].stats.blocksPerGame} BLK, ${bbs[2].stats.effectiveFgPct} eFG`);

  if (missing.length) {
    console.log("\nLeft as-is / not provided by the API (NOT fabricated):");
    for (const m of missing) console.log(`  - ${m}`);
  }
  const verified = reconciledGames.filter((g) => g.source === "cfbd").length;
  console.log(`\nGames verified against CFBD: ${verified} stamped official.`);
  if (gameNotes.length) {
    console.log("Games needing a human look (NOT overwritten):");
    for (const n of gameNotes) console.log(`  - ${n}`);
  }
  console.log("\nWrote seed + Flutter asset. JSON validated.");
}

main().catch((err) => {
  console.error("sync_real_data failed:", err instanceof Error ? err.message : err);
  process.exit(1);
});
