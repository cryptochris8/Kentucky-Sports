/**
 * Seed the Firestore emulator (or a real dev project) with development data.
 *
 * Usage:
 *   1. Start emulators:  npm run emulators   (from repo root)
 *   2. In another shell: npm run seed        (from repo root)
 *
 * Safety: refuses to run against production unless SEED_ALLOW_PROD=true is set.
 * ISO-8601 datetime strings in the seed are converted to Firestore Timestamps.
 */
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SEED_PATH = resolve(__dirname, "../seed_data/dev_seed.json");
const PROJECT_ID = process.env.GCLOUD_PROJECT ?? "bluegrass-gameday-dev";

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

async function main() {
  initializeApp({ projectId: PROJECT_ID });
  const db = getFirestore();

  const raw = JSON.parse(readFileSync(SEED_PATH, "utf8")) as Record<string, any>;
  const collections = Object.keys(raw).filter((k) => k !== "_meta");

  console.log(`Seeding project "${PROJECT_ID}" (${usingEmulator ? "emulator" : "REAL PROJECT"})`);

  let totalDocs = 0;
  for (const collection of collections) {
    const docs = raw[collection];
    if (!Array.isArray(docs)) continue;
    let batch = db.batch();
    let opCount = 0;
    for (const doc of docs) {
      const { id, ...data } = doc;
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
      totalDocs++;
      if (opCount >= 400) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }
    if (opCount > 0) await batch.commit();
    console.log(`  ✓ ${collection.padEnd(20)} ${docs.length} docs`);
  }

  console.log(`\nDone. Wrote ${totalDocs} documents across ${collections.length} collections.`);
  process.exit(0);
}

main().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
