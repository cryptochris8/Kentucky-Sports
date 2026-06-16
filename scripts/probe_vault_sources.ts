/**
 * Probe how far back CFBD (football) and CBBD (basketball) have real Kentucky data,
 * to ground The Vault's design. Reads keys from .env.local; never prints them.
 * Run: NODE_TLS_REJECT_UNAUTHORIZED=0 npx tsx probe_vault_sources.ts
 */
import { existsSync, readFileSync } from "node:fs";
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
const CFBD = process.env.CFBD_API_KEY!;
const CBBD = process.env.CBBD_API_KEY!;

async function probe(label: string, url: string, key: string) {
  try {
    const res = await fetch(url, { headers: { Authorization: `Bearer ${key}` } });
    if (res.status !== 200) return console.log(`  ${label.padEnd(34)} -> HTTP ${res.status}`);
    const data = (await res.json()) as unknown;
    const n = Array.isArray(data) ? data.length : data ? 1 : 0;
    // surface a tiny hint of the shape for the first record
    let hint = "";
    if (Array.isArray(data) && data.length > 0 && typeof data[0] === "object") {
      hint = " keys: " + Object.keys(data[0] as object).slice(0, 8).join(",");
    }
    console.log(`  ${label.padEnd(34)} -> ${n} record(s)${n ? hint : ""}`);
  } catch (e) {
    console.log(`  ${label.padEnd(34)} -> ERR ${(e as { message?: string })?.message ?? e}`);
  }
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

(async () => {
  console.log("=== CFBD (football) — Kentucky ===");
  for (const y of [1950, 1970, 1985, 1996, 2010, 2025]) {
    await probe(`records ${y}`, `https://api.collegefootballdata.com/records?year=${y}&team=Kentucky`, CFBD);
    await sleep(150);
  }
  for (const y of [1985, 2025]) {
    await probe(`stats/season ${y}`, `https://api.collegefootballdata.com/stats/season?year=${y}&team=Kentucky`, CFBD);
    await sleep(150);
  }
  for (const y of [1985, 2004, 2025]) {
    await probe(`roster ${y}`, `https://api.collegefootballdata.com/roster?team=Kentucky&year=${y}`, CFBD);
    await sleep(150);
  }
  await probe(`player/season 1985`, `https://api.collegefootballdata.com/stats/player/season?year=1985&team=Kentucky`, CFBD);

  console.log("\n=== CBBD (men's basketball) — Kentucky ===");
  for (const y of [1985, 2000, 2003, 2008, 2015, 2025]) {
    await probe(`team/season ${y}`, `https://api.collegebasketballdata.com/stats/team/season?season=${y}&team=Kentucky`, CBBD);
    await sleep(150);
  }
  for (const y of [2003, 2025]) {
    await probe(`player/season ${y}`, `https://api.collegebasketballdata.com/stats/player/season?season=${y}&team=Kentucky`, CBBD);
    await sleep(150);
  }
  await probe(`games 2003`, `https://api.collegebasketballdata.com/games?season=2003&team=Kentucky`, CBBD);
})();
