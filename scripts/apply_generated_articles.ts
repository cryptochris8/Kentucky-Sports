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
 * Published-work guard (mirrors seed_firestore.ts's vault-legend skip): a
 * generated article never replaces an existing status:"published" article with
 * a draft, and a model:"seed_template" regeneration never replaces a
 * model:"claude-*" article. Skips are logged; pass --force to overwrite anyway.
 *
 * Note: the whole seed document is parsed, mutated, and re-serialized — no
 * string splicing — so every top-level key survives regardless of key order.
 * (The old marker-splice approach silently dropped any collection added after
 * "articles".) The output is key-count-checked before writing as a belt-and-
 * braces guard.
 */
import { readFileSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { protectedArticleReplacement } from "./generate_articles";

const FORCE = process.argv.includes("--force");
const __dirname = dirname(fileURLToPath(import.meta.url));
const SEED = resolve(__dirname, "../seed_data/dev_seed.json");
const GEN_DIR = resolve(__dirname, "../seed_data/generated");
const ASSET = resolve(__dirname, "../apps/mobile_flutter/assets/seed/dev_seed.json");

interface Article {
  id: string;
  status?: unknown;
  model?: unknown;
  [k: string]: unknown;
}

const text = readFileSync(SEED, "utf8");
const seed = JSON.parse(text) as Record<string, unknown> & {
  articles?: Article[];
  games?: { id: string }[];
};
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
const generatedValid = generated.filter(isValid);

// Published-work guard: never demote an existing published article to a draft,
// or replace a claude-* article with a seed_template regeneration, without
// --force. Skipped articles keep their existing seed version.
const existingById = new Map(existing.map((a) => [a.id, a]));
const applied: Article[] = [];
const skipped: string[] = [];
for (const gen of generatedValid) {
  const prior = existingById.get(gen.id);
  const reason = prior && !FORCE ? protectedArticleReplacement(prior, gen) : null;
  if (reason) {
    console.log(`  - ${gen.id}: skipped (${reason} — pass --force to overwrite)`);
    skipped.push(gen.id);
    continue;
  }
  applied.push(gen);
}

if (applied.length === 0) {
  console.log(
    `Nothing to apply — all ${skipped.length} generated article(s) were protected. Seed left untouched.`
  );
  process.exit(0);
}

// Applied articles first; keep any existing valid article not overwritten
// (e.g. the template recap, or a protected article that was skipped above).
const appliedIds = new Set(applied.map((a) => a.id));
const merged = [...applied, ...existing.filter((a) => !appliedIds.has(a.id) && isValid(a))];

// Replace only the articles array; every other top-level key passes through
// untouched because we re-serialize the parsed document.
const keysBefore = Object.keys(seed);
seed.articles = merged;
const out = JSON.stringify(seed, null, 2) + "\n";

const reparsed = JSON.parse(out) as Record<string, unknown>;
const keysAfter = Object.keys(reparsed);
if (keysAfter.length < keysBefore.length) {
  throw new Error(
    `apply-articles would drop top-level seed keys (${keysBefore.length} -> ${keysAfter.length}) — aborting.`
  );
}

writeFileSync(SEED, out);
if (existsSync(dirname(ASSET))) {
  writeFileSync(ASSET, out);
}

console.log(
  `Applied ${applied.length} generated article(s) [${applied.map((a) => a.id).join(", ")}]` +
    (skipped.length ? `; skipped ${skipped.length} protected [${skipped.join(", ")}]` : "") +
    `.\nSeed now has ${merged.length} articles. Synced Flutter asset.`
);
