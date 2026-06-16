/**
 * Scheduled Cloud Functions for data ingestion.
 *
 * Key-gated pattern:
 *   - When CFBD_API_KEY / CBBD_API_KEY is ABSENT: logs "skipped — no key" and writes a
 *     sync_runs doc (keeps stub behavior for local dev / emulator runs with no key).
 *   - When the key IS present: fetches from the provider, normalises, and merge-writes into
 *     the season-keyed Firestore collections, then writes a sync_runs doc.
 *
 * Staleness check: skips the provider call when the latest successful sync_run for a
 * (provider, sport) pair is less than FRESHNESS_WINDOW_HOURS old (default 24 h).
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getDb, Timestamp } from '../core/admin';
import type { SyncRun, NormalizedGame, NormalizedTeamStat } from '@bluegrass/shared-models';
import { createCfbdClient } from './providers/cfbdClient';
import { createCbbdClient } from './providers/cbbdClient';

const CURRENT_SEASON_FOOTBALL = 2026;
const CURRENT_SEASON_BASKETBALL = 2026;

/** Skip the provider call if a successful sync ran within this window. */
const FRESHNESS_WINDOW_HOURS = 24;

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Returns true if the most recent successful sync_run for this provider+sport is still fresh. */
async function isDataFresh(
  provider: SyncRun['provider'],
  sport: SyncRun['sport'],
): Promise<boolean> {
  const db = getDb();
  const cutoff = new Date(Date.now() - FRESHNESS_WINDOW_HOURS * 60 * 60 * 1000);
  const snap = await db
    .collection('sync_runs')
    .where('provider', '==', provider)
    .where('sport', '==', sport)
    .where('status', '==', 'success')
    .orderBy('completedAt', 'desc')
    .limit(1)
    .get();

  if (snap.empty) return false;
  const lastRun = snap.docs[0].data() as SyncRun;
  const completedAt = lastRun.completedAt;
  if (!completedAt) return false;

  // Handle both Firestore Timestamp objects and ISO strings
  const completedDate =
    typeof completedAt === 'object' && 'toDate' in (completedAt as object)
      ? (completedAt as unknown as { toDate(): Date }).toDate()
      : new Date(completedAt as string);

  return completedDate > cutoff;
}

/** Write a sync_runs document recording the outcome of a sync attempt. */
async function writeSyncRun(
  provider: SyncRun['provider'],
  sport: SyncRun['sport'],
  status: SyncRun['status'],
  recordsProcessed: number,
  error: string | null,
  note?: string,
): Promise<void> {
  const db = getDb();
  const now = Timestamp.now();
  const doc: Record<string, unknown> = {
    provider,
    sport,
    startedAt: now,
    completedAt: now,
    status,
    recordsProcessed,
    error,
  };
  if (note) doc['note'] = note;
  await db.collection('sync_runs').add(doc);
}

/** Merge-write normalised games into Firestore with provenance fields. */
async function persistGames(games: NormalizedGame[], season: number): Promise<number> {
  const db = getDb();
  let batch = db.batch();
  let count = 0;

  for (const g of games) {
    const id = `${g.sport}_${season}_${g.sourceGameId}`;
    const docRef = db.collection('games').doc(id);
    batch.set(
      docRef,
      {
        ...g,
        id,
        updatedAt: Timestamp.now(),
        lastFetched: Timestamp.now(),
        source: g.source,
      },
      { merge: true },
    );
    count++;

    // Firestore batch limit is 500 writes
    if (count % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }

  if (count % 400 !== 0) await batch.commit();
  return count;
}

/** Merge-write normalised team stats into Firestore with provenance fields. */
async function persistTeamStats(stats: NormalizedTeamStat[]): Promise<number> {
  const db = getDb();
  let batch = db.batch();
  let count = 0;

  for (const s of stats) {
    const id = `${s.teamId}_${s.season}_${s.scope}`;
    const docRef = db.collection('team_stats').doc(id);
    batch.set(
      docRef,
      {
        ...s,
        id,
        updatedAt: Timestamp.now(),
        lastFetched: Timestamp.now(),
        confidence: 'official',
      },
      { merge: true },
    );
    count++;

    if (count % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }

  if (count % 400 !== 0) await batch.commit();
  return count;
}

// ── Scheduled Functions ───────────────────────────────────────────────────────

/**
 * Nightly football sync from CollegeFootballData.
 * Skipped when CFBD_API_KEY is absent; staleness-checked at 24 h.
 */
export const syncCollegeFootballNightly = onSchedule(
  { schedule: 'every day 03:00', timeZone: 'America/New_York' },
  async () => {
    const provider = 'cfbd' as const;
    const sport = 'football' as const;
    const apiKey = process.env.CFBD_API_KEY ?? '';

    if (!apiKey) {
      console.log('[syncCollegeFootballNightly] Skipped — CFBD_API_KEY not set.');
      await writeSyncRun(provider, sport, 'success', 0, null, 'skipped — no key');
      return;
    }

    const fresh = await isDataFresh(provider, sport);
    if (fresh) {
      console.log('[syncCollegeFootballNightly] Data is fresh — skipping provider call.');
      await writeSyncRun(provider, sport, 'success', 0, null, 'skipped — data fresh');
      return;
    }

    try {
      const client = createCfbdClient();
      const [games, teamStats] = await Promise.all([
        client.getKentuckyGames(CURRENT_SEASON_FOOTBALL),
        client.getKentuckyTeamStats(CURRENT_SEASON_FOOTBALL),
      ]);

      const gameCount = await persistGames(games, CURRENT_SEASON_FOOTBALL);
      const statCount = await persistTeamStats(teamStats);

      const total = gameCount + statCount;
      console.log(`[syncCollegeFootballNightly] Synced ${total} records.`);
      await writeSyncRun(provider, sport, 'success', total, null);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error('[syncCollegeFootballNightly] Error:', msg);
      await writeSyncRun(provider, sport, 'error', 0, msg);
    }
  },
);

/**
 * Nightly basketball sync from CollegeBasketballData.
 * Skipped when CBBD_API_KEY is absent; staleness-checked at 24 h.
 */
export const syncCollegeBasketballNightly = onSchedule(
  { schedule: 'every day 03:30', timeZone: 'America/New_York' },
  async () => {
    const provider = 'cbbd' as const;
    const sport = 'mens_basketball' as const;
    const apiKey = process.env.CBBD_API_KEY ?? '';

    if (!apiKey) {
      console.log('[syncCollegeBasketballNightly] Skipped — CBBD_API_KEY not set.');
      await writeSyncRun(provider, sport, 'success', 0, null, 'skipped — no key');
      return;
    }

    const fresh = await isDataFresh(provider, sport);
    if (fresh) {
      console.log('[syncCollegeBasketballNightly] Data is fresh — skipping provider call.');
      await writeSyncRun(provider, sport, 'success', 0, null, 'skipped — data fresh');
      return;
    }

    try {
      const client = createCbbdClient();
      const [games, teamStats] = await Promise.all([
        client.getKentuckyGames(CURRENT_SEASON_BASKETBALL),
        client.getKentuckyTeamStats(CURRENT_SEASON_BASKETBALL),
      ]);

      const gameCount = await persistGames(games, CURRENT_SEASON_BASKETBALL);
      const statCount = await persistTeamStats(teamStats);

      const total = gameCount + statCount;
      console.log(`[syncCollegeBasketballNightly] Synced ${total} records.`);
      await writeSyncRun(provider, sport, 'success', total, null);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error('[syncCollegeBasketballNightly] Error:', msg);
      await writeSyncRun(provider, sport, 'error', 0, msg);
    }
  },
);

/**
 * Live scoreboard poll (every 30 minutes).
 * Currently a no-op outside of game days; full implementation in Phase 3.
 */
export const syncGamedayScoreboard = onSchedule(
  { schedule: 'every 30 minutes', timeZone: 'America/New_York' },
  async () => {
    // TODO Phase 3: detect game-day window, then poll live endpoint only when active
    console.log('[syncGamedayScoreboard] Phase 2 — live scoreboard not yet implemented.');
  },
);
