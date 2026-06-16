/**
 * Apply generated articles into the app.
 *
 * Merges every seed_data/generated/*.json article into seed_data/dev_seed.json
 * (replace-by-id, add if new), then copies the seed into the Flutter app asset so
 * the running app renders the real Claude-written articles instead of templates.
 *
 * Run after `npm run generate`:
 *   npm --prefix scripts run apply-articles
 *
 * Note: assumes the `articles` array is the last top-level key in dev_seed.json
 * (it is) so the rest of the file's formatting is preserved. The output is
 * JSON.parse-validated before writing.
 */
import { readFileSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SEED = resolve(__dirname, "../seed_data/dev_seed.json");
const GEN_DIR = resolve(__dirname, "../seed_data/generated");
const ASSET = resolve(__dirname, "../apps/mobile_flutter/assets/seed/dev_seed.json");

interface Article {
  id: string;
  [k: string]: unknown;
}

const text = readFileSync(SEED, "utf8");
const seed = JSON.parse(text) as { articles?: Article[]; games?: { id: string }[] };
const existing: Article[] = Array.isArray(seed.articles) ? seed.articles : [];

const genFiles = existsSync(GEN_DIR)
  ? readdirSync(GEN_DIR).filter((f) => f.endsWith(".json"))
  : [];
if (genFiles.length === 0) {
  console.log("No generated articles found in seed_data/generated/. Run `npm run generate` first.");
  process.exit(0);
}

const generated: Article[] = genFiles.map(
  (f) => JSON.parse(readFileSync(resolve(GEN_DIR, f), "utf8")) as Article
);

// Only include articles whose game still exists in the seed — drops orphans such as
// a stale generated file for a game that was later renamed or removed.
const gameIds = new Set((seed.games ?? []).map((g) => g.id));
const isValid = (a: Article) => typeof a.gameId === "string" && gameIds.has(a.gameId as string);
// Generated (real Claude previews) first; keep any existing valid article not overwritten
// (e.g. the template recap).
const generatedValid = generated.filter(isValid);
const genIds = new Set(generatedValid.map((a) => a.id));
const merged = [...generatedValid, ...existing.filter((a) => !genIds.has(a.id) && isValid(a))];

// Surgically replace only the articles array to preserve the rest of the file.
const marker = '  "articles": [';
const idx = text.indexOf(marker);
let out: string;
if (idx >= 0) {
  const before = text.slice(0, idx);
  const body = '  "articles": ' + JSON.stringify(merged, null, 2).replace(/\n/g, "\n  ") + "\n}\n";
  out = before + body;
} else {
  out = text.replace(/\}\s*$/, `  "articles": ${JSON.stringify(merged, null, 2)}\n}\n`);
}

JSON.parse(out); // validate before writing — throws on any malformed result
writeFileSync(SEED, out);
if (existsSync(dirname(ASSET))) {
  writeFileSync(ASSET, out);
}

console.log(
  `Applied ${generated.length} generated article(s) [${generated.map((a) => a.id).join(", ")}].\n` +
    `Seed now has ${merged.length} articles. Synced Flutter asset.`
);
