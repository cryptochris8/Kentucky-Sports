/**
 * Seed the Firestore emulator (or a real dev project) with development data.
 *
 * Usage:
 *   1. Start emulators:  npm run emulators   (from repo root)
 *   2. In another shell: npm run seed        (from repo root)
 *
 * Safety: refuses to run against production unless SEED_ALLOW_PROD=true is set.
 * ISO-8601 datetime strings in the seed are converted to Firestore Timestamps.
 *
 * Editor-work protection: vault_legends docs whose stored status is no longer
 * "draft" (an editor readied/published them in the admin portal) are SKIPPED so
 * a routine re-seed never reverts human edits to the AI draft. Pass --force to
 * overwrite them anyway.
 *
 * user_badges are written into users/{uid}/user_badges subcollections — the
 * path the security rules cover — not a dead top-level collection.
 */
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve, join } from "node:path";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp, type Firestore } from "firebase-admin/firestore";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SEED_DIR = resolve(__dirname, "../seed_data");
const SEED_PATH = resolve(SEED_DIR, "dev_seed.json");
const VAULT_LEGENDS_PATH = resolve(SEED_DIR, "vault_legends.json");
const VAULT_SEASONS_PATH = resolve(SEED_DIR, "vault_seasons.json");
const LEGEND_BRIEFS_DIR = resolve(SEED_DIR, "legend_briefs");
const PROJECT_ID = process.env.GCLOUD_PROJECT ?? "bluegrass-gameday-dev";
const FORCE = process.argv.includes("--force");

const usingEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
if (!usingEmulator && process.env.SEED_ALLOW_PROD !== "true") {
  console.error(
    "Refusing to seed: FIRESTORE_EMULATOR_HOST is not set.\n" +
      "Start the emulator first (npm run emulators) or set SEED_ALLOW_PROD=true to target a real dev project."
  );
  process.exit(1);
}

const ISO_DATETIME = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?([+-]\d{2}:\d{2}|Z)$/;

/** Recursively convert ISO-8601 datetime strings into Firestore Timestamps. */
function convertTimestamps(value: unknown): unknown {
  if (typeof value === "string" && ISO_DATETIME.test(value)) {
    return Timestamp.fromDate(new Date(value));
  }
  if (Array.isArray(value)) return value.map(convertTimestamps);
  if (value && typeof value === "object") {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value)) out[k] = convertTimestamps(v);
    return out;
  }
  return value;
}

/**
 * Write an array of docs (each must carry an `id`) into a Firestore collection,
 * converting ISO timestamps and batching in chunks. Returns the number written.
 */
async function loadCollection(
  db: Firestore,
  collection: string,
  docs: unknown[]
): Promise<number> {
  let batch = db.batch();
  let opCount = 0;
  let written = 0;
  for (const doc of docs) {
    const { id, ...data } = (doc ?? {}) as Record<string, any>;
    if (!id) {
      console.warn(`  ! ${collection}: skipping a doc with no "id" field`);
      continue;
    }
    batch.set(
      db.collection(collection).doc(String(id)),
      { ...(convertTimestamps(data) as object), seedLoadedAt: Timestamp.now() },
      { merge: true }
    );
    opCount++;
    written++;
    if (opCount >= 400) {
      await batch.commit();
      batch = db.batch();
      opCount = 0;
    }
  }
  if (opCount > 0) await batch.commit();
  console.log(`  ✓ ${collection.padEnd(20)} ${written} docs`);
  return written;
}

/**
 * Write user_badges into users/{uid}/user_badges subcollections — the path the
 * security rules cover. (A top-level user_badges collection is unreadable dead
 * data.) Each doc must carry `id` and `userId`.
 */
async function loadUserBadges(db: Firestore, docs: unknown[]): Promise<number> {
  let batch = db.batch();
  let opCount = 0;
  let written = 0;
  for (const doc of docs) {
    const { id, userId, ...data } = (doc ?? {}) as Record<string, any>;
    if (!id || !userId) {
      console.warn(`  ! user_badges: skipping a doc with no "id"/"userId" field`);
      continue;
    }
    batch.set(
      db.collection("users").doc(String(userId)).collection("user_badges").doc(String(id)),
      { userId, ...(convertTimestamps(data) as object), seedLoadedAt: Timestamp.now() },
      { merge: true }
    );
    opCount++;
    written++;
    if (opCount >= 400) {
      await batch.commit();
      batch = db.batch();
      opCount = 0;
    }
  }
  if (opCount > 0) await batch.commit();
  console.log(`  ✓ ${"users/*/user_badges".padEnd(20)} ${written} docs`);
  return written;
}

/**
 * Write vault_legends, skipping any doc whose stored status is no longer
 * "draft" — an editor has readied/published it in the admin portal and a
 * re-seed must never revert those edits to the AI draft. --force overrides.
 */
async function loadVaultLegends(db: Firestore, docs: unknown[], force: boolean): Promise<number> {
  let written = 0;
  for (const doc of docs) {
    const { id, ...data } = (doc ?? {}) as Record<string, any>;
    if (!id) {
      console.warn(`  ! vault_legends: skipping a doc with no "id" field`);
      continue;
    }
    const ref = db.collection("vault_legends").doc(String(id));
    const existing = await ref.get();
    const existingStatus = existing.exists ? (existing.data()?.status as string | undefined) : undefined;
    if (!force && existingStatus && existingStatus !== "draft") {
      console.log(`  - vault_legends/${id}: skipped (status "${existingStatus}" — editor work preserved; --force to overwrite)`);
      continue;
    }
    await ref.set(
      { ...(convertTimestamps(data) as object), seedLoadedAt: Timestamp.now() },
      { merge: true }
    );
    written++;
  }
  console.log(`  ✓ ${"vault_legends".padEnd(20)} ${written} docs`);
  return written;
}

/** Read an array of docs from a JSON file under a given key (e.g. `.vault_legends`). */
function readArrayFile(path: string, key: string): unknown[] {
  if (!existsSync(path)) {
    console.warn(`  ! ${key}: file not found, skipping (${path})`);
    return [];
  }
  const raw = JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
  const arr = raw[key];
  return Array.isArray(arr) ? arr : [];
}

/** Read every *.json file in a directory; each file is a single doc carrying an `id`. */
function readDocsDir(dir: string): unknown[] {
  if (!existsSync(dir)) {
    console.warn(`  ! legend_briefs: directory not found, skipping (${dir})`);
    return [];
  }
  return readdirSync(dir)
    .filter((f) => f.endsWith(".json"))
    .map((f) => JSON.parse(readFileSync(join(dir, f), "utf8")) as unknown);
}

async function main() {
  initializeApp({ projectId: PROJECT_ID });
  const db = getFirestore();

  console.log(`Seeding project "${PROJECT_ID}" (${usingEmulator ? "emulator" : "REAL PROJECT"})`);

  let totalDocs = 0;
  let collectionCount = 0;

  // ── dev_seed.json (existing behavior, unchanged) ──────────────────────────
  const raw = JSON.parse(readFileSync(SEED_PATH, "utf8")) as Record<string, any>;
  const collections = Object.keys(raw).filter((k) => k !== "_meta");
  for (const collection of collections) {
    const docs = raw[collection];
    if (!Array.isArray(docs)) continue;
    if (collection === "user_badges") {
      totalDocs += await loadUserBadges(db, docs);
    } else {
      totalDocs += await loadCollection(db, collection, docs);
    }
    collectionCount++;
  }

  // ── The Vault — legends, season records, and sourced briefs ───────────────
  const vaultLegends = readArrayFile(VAULT_LEGENDS_PATH, "vault_legends");
  if (vaultLegends.length) {
    totalDocs += await loadVaultLegends(db, vaultLegends, FORCE);
    collectionCount++;
  }

  const vaultSeasons = readArrayFile(VAULT_SEASONS_PATH, "vault_seasons");
  if (vaultSeasons.length) {
    totalDocs += await loadCollection(db, "vault_seasons", vaultSeasons);
    collectionCount++;
  }

  const legendBriefs = readDocsDir(LEGEND_BRIEFS_DIR);
  if (legendBriefs.length) {
    totalDocs += await loadCollection(db, "legend_briefs", legendBriefs);
    collectionCount++;
  }

  console.log(`\nDone. Wrote ${totalDocs} documents across ${collectionCount} collections.`);
  process.exit(0);
}

main().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
