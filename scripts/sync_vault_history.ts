/**
 * The Vault — season-records spine. Pulls REAL Kentucky football (CFBD) and men's
 * basketball (CBBD) season records and writes seed_data/vault_seasons.json (+ the
 * Flutter asset). Records only here; modern team/player stats are layered in later.
 *
 * Run: npm run vault-sync   (from repo root; sets the corp-proxy TLS flag)
 */
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
for (const p of [resolve(__dirname, "../.env.local"), resolve(__dirname, "../functions/.env.local")]) {
  if (!existsSync(p)) continue;
  for (const line of readFileSync(p, "utf8").split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, "");
  }
}
const CFBD = process.env.CFBD_API_KEY;
const CBBD = process.env.CBBD_API_KEY;
if (!CFBD || !CBBD) { console.error("Missing CFBD_API_KEY / CBBD_API_KEY in .env.local"); process.exit(1); }

const OUT = resolve(__dirname, "../seed_data/vault_seasons.json");
const ASSET = resolve(__dirname, "../apps/mobile_flutter/assets/vault/vault_seasons.json");
const now = new Date().toISOString();
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function getJson(url: string, key: string): Promise<any[]> {
  const res = await fetch(url, { headers: { Authorization: `Bearer ${key}` } });
  if (res.status !== 200) { console.warn(`  ! ${res.status} ${url.replace(/Bearer.*/, "")}`); return []; }
  const d = await res.json();
  return Array.isArray(d) ? d : d ? [d] : [];
}

interface VaultSeason {
  id: string; sport: "football" | "mens_basketball"; season: number; seasonLabel: string;
  conference?: string; wins: number | null; losses: number | null; ties?: number | null;
  record: string; conferenceRecord?: string; source: "cfbd" | "cbbd"; confidence: "official"; updatedAt: string;
}

const seasons: VaultSeason[] = [];

async function syncFootball() {
  for (let y = 2025; y >= 1985; y--) {
    const [r] = await getJson(`https://api.collegefootballdata.com/records?year=${y}&team=Kentucky`, CFBD!);
    if (!r) { await sleep(120); continue; }
    const w = r.total?.wins ?? null, l = r.total?.losses ?? null, t = r.total?.ties ?? 0;
    const cw = r.conferenceGames?.wins, cl = r.conferenceGames?.losses;
    seasons.push({
      id: `fb_${y}`, sport: "football", season: y, seasonLabel: String(y),
      conference: r.conference ?? "SEC",
      wins: w, losses: l, ties: t || undefined,
      record: w == null ? "—" : `${w}-${l}${t ? `-${t}` : ""}`,
      conferenceRecord: cw != null ? `${cw}-${cl}` : undefined,
      source: "cfbd", confidence: "official", updatedAt: now,
    });
    await sleep(120);
  }
}

async function syncBasketball() {
  for (let s = 2026; s >= 1985; s--) {
    const [r] = await getJson(`https://api.collegebasketballdata.com/stats/team/season?season=${s}&team=Kentucky`, CBBD!);
    if (!r || (r.wins == null && r.games == null)) { await sleep(120); continue; }
    const w = r.wins ?? null, l = r.losses ?? null;
    seasons.push({
      id: `bb_${s}`, sport: "mens_basketball", season: s,
      seasonLabel: `${s - 1}-${String(s).slice(2)}`, // CBBD's own label is unformatted ("20242025")
      conference: r.conference ?? "SEC",
      wins: w, losses: l,
      record: w == null ? "—" : `${w}-${l}`,
      source: "cbbd", confidence: "official", updatedAt: now,
    });
    await sleep(120);
  }
}

(async () => {
  console.log("Pulling Kentucky football season records (CFBD, 1985-2025)...");
  await syncFootball();
  console.log("Pulling Kentucky men's basketball season records (CBBD, 1985-2026)...");
  await syncBasketball();

  const payload = {
    _meta: { description: "The Vault — real UK season records. source: CFBD (football) / CBBD (basketball).", generatedAt: now },
    vault_seasons: seasons,
  };
  writeFileSync(OUT, JSON.stringify(payload, null, 2) + "\n");
  mkdirSync(dirname(ASSET), { recursive: true });
  writeFileSync(ASSET, JSON.stringify(payload, null, 2) + "\n");

  const fb = seasons.filter((s) => s.sport === "football");
  const bb = seasons.filter((s) => s.sport === "mens_basketball");
  console.log(`\nWrote ${seasons.length} seasons -> seed_data/vault_seasons.json (+ asset)`);
  console.log(`  Football: ${fb.length} seasons (newest ${fb[0]?.seasonLabel} ${fb[0]?.record}, oldest ${fb.at(-1)?.seasonLabel})`);
  console.log(`  Men's BB: ${bb.length} seasons (newest ${bb[0]?.seasonLabel} ${bb[0]?.record}, oldest ${bb.at(-1)?.seasonLabel})`);
})();
