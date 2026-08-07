/**
 * Scheduled Cloud Functions for data ingestion.
 *
 * Key-gated pattern:
 *   - When CFBD_API_KEY / CBBD_API_KEY is ABSENT: logs and records a sync_runs doc
 *     with status 'skipped' — a missing key must never look like a successful fetch.
 *   - When the key IS present: fetches from the provider, normalises, and updates the
 *     season-keyed Firestore collections, then writes a sync_runs doc.
 *
 * Keys are bound as Cloud Secrets (defineSecret) so deployed Gen-2 functions actually
 * receive them; locally the emulator falls back to functions/.env.local.
 *
 * Staleness check: skips the provider call when the latest successful sync_run for a
 * (provider, sport) pair is less than FRESHNESS_WINDOW_HOURS old (20 h — deliberately
 * shorter than the 24 h schedule period so a completed run never blocks the next night).
 * Skipped runs do NOT count as fresh — only real fetches do.
 *
 * Games are matched against EXISTING documents (first by sourceGameId, then by a
 * normalized sport/day/opponent key) so the sync updates the curated schedule in
 * place instead of minting duplicate docs — see persistLogic.ts.
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';
import { getDb, Timestamp } from '../core/admin';
import type { Game, NormalizedGame, NormalizedTeamStat, Sport, SyncRun } from '@bluegrass/shared-models';
import { createCfbdClient } from './providers/cfbdClient';
import { createCbbdClient } from './providers/cbbdClient';
import {
  deriveKentuckySide,
  gameMatchKey,
  hasAnyStatValue,
  opponentTeamId,
} from './persistLogic';

const CFBD_API_KEY = defineSecret('CFBD_API_KEY');
const CBBD_API_KEY = defineSecret('CBBD_API_KEY');

const CURRENT_SEASON_FOOTBALL = 2026;
const CURRENT_SEASON_BASKETBALL = 2026;

/**
 * Skip the provider call if a successful sync ran within this window.
 * MUST be < the 24 h schedule period: at exactly 24 h, last night's completed
 * run still counts as fresh when tonight's fires (scheduler jitter puts the
 * runs ~24 h apart), so every other night self-skips and the sync effectively
 * runs every ~48 h. 20 h leaves slack for jitter while still deduping ad-hoc
 * or manually triggered runs within the same day.
 */
export const FRESHNESS_WINDOW_HOURS = 20;

/** Max characters of an error message persisted into a sync_runs doc. */
const SYNC_ERROR_LIMIT = 1_000;

/**
 * Recorded outcome of a sync attempt. 'skipped' (no key / data fresh) is
 * distinct from 'success' so the freshness gate and the admin Sync page only
 * count runs that actually fetched data.
 */
type SyncOutcome = SyncRun['status'] | 'skipped';

/** Mutable counter threaded through the persist helpers so a mid-sync failure
 *  still reports how many records actually landed. */
interface SyncProgress {
  committed: number;
}

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
  status: SyncOutcome,
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
    error: error ? error.slice(0, SYNC_ERROR_LIMIT) : null,
  };
  if (note) doc['note'] = note;
  await db.collection('sync_runs').add(doc);
}

/**
 * Write normalised games into Firestore, updating existing docs in place.
 *
 * Matching order: stamped sourceGameId first, then the normalized
 * (sport, Eastern-time day, opponent) key. On a match only score/status/provenance are
 * stamped — curated fields (opponentName, isHome, homeTeamId, awayTeamId,
 * broadcast, featured) are preserved. On no match a COMPLETE doc is created so
 * the mobile client can render it.
 */
async function persistGames(
  games: NormalizedGame[],
  season: number,
  sport: Sport,
  progress: SyncProgress,
): Promise<number> {
  const db = getDb();
  if (games.length === 0) return 0;

  const existingSnap = await db
    .collection('games')
    .where('sport', '==', sport)
    .where('season', '==', season)
    .get();

  const refsBySourceId = new Map<string, FirebaseFirestore.DocumentReference>();
  const refsByMatchKey = new Map<string, FirebaseFirestore.DocumentReference>();
  for (const docSnap of existingSnap.docs) {
    const data = docSnap.data() as Game;
    if (data.sourceGameId) refsBySourceId.set(String(data.sourceGameId), docSnap.ref);
    const key = gameMatchKey(sport, data.startTime, data.opponentName ?? '');
    if (key) refsByMatchKey.set(key, docSnap.ref);
  }

  let count = 0;
  for (const g of games) {
    const side = deriveKentuckySide(g);
    if (!side) {
      console.warn(
        `[persistGames] Skipping ${g.source} game ${g.sourceGameId} — no Kentucky side detected ` +
          `(${g.homeTeamName} vs ${g.awayTeamName}).`,
      );
      continue;
    }

    const now = Timestamp.now();
    const matchRef =
      refsBySourceId.get(g.sourceGameId) ??
      refsByMatchKey.get(gameMatchKey(sport, g.startTime, side.opponentName) ?? '');

    if (matchRef) {
      // Update in place; preserve curated fields, stamp scores/status/provenance.
      await matchRef.update({
        status: g.status,
        homeScore: g.homeScore ?? null,
        awayScore: g.awayScore ?? null,
        sourceGameId: g.sourceGameId,
        source: g.source,
        confidence: 'official',
        updatedAt: now,
        lastFetched: now,
      });
      refsBySourceId.set(g.sourceGameId, matchRef);
    } else {
      const id = `${g.sport}_${season}_${g.sourceGameId}`;
      const docRef = db.collection('games').doc(id);
      const kentuckyTeamId = `kentucky_${sport}`;
      const oppTeamId = opponentTeamId(side.opponentName);
      await docRef.set(
        {
          id,
          season,
          sport: g.sport,
          homeTeamId: side.isHome ? kentuckyTeamId : oppTeamId,
          awayTeamId: side.isHome ? oppTeamId : kentuckyTeamId,
          opponentName: side.opponentName,
          isHome: side.isHome,
          startTime: g.startTime,
          venue: g.venue ?? null,
          status: g.status,
          homeScore: g.homeScore ?? null,
          awayScore: g.awayScore ?? null,
          broadcast: 'TBD',
          featured: false,
          source: g.source,
          sourceGameId: g.sourceGameId,
          confidence: 'official',
          updatedAt: now,
          lastFetched: now,
        },
        { merge: true },
      );
      refsBySourceId.set(g.sourceGameId, docRef);
    }

    count++;
    progress.committed++;
  }

  return count;
}

/** Merge-write normalised team stats into Firestore with provenance fields. */
async function persistTeamStats(
  stats: NormalizedTeamStat[],
  progress: SyncProgress,
): Promise<number> {
  const db = getDb();
  let count = 0;

  for (const s of stats) {
    // An all-null payload (provider shape change, empty response) must never
    // merge over previously-good values wearing an 'official' label.
    if (!hasAnyStatValue(s.stats)) {
      console.warn(`[persistTeamStats] Skipping all-null stat doc for ${s.teamId} ${s.season}.`);
      continue;
    }

    const id = `${s.teamId}_${s.season}_${s.scope}`;
    const docRef = db.collection('team_stats').doc(id);
    await docRef.set(
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
    progress.committed++;
  }

  return count;
}

// ── Scheduled Functions ───────────────────────────────────────────────────────

/**
 * Nightly football sync from CollegeFootballData.
 * Skipped when CFBD_API_KEY is absent; staleness-checked at FRESHNESS_WINDOW_HOURS.
 */
export const syncCollegeFootballNightly = onSchedule(
  { schedule: 'every day 03:00', timeZone: 'America/New_York', secrets: [CFBD_API_KEY] },
  async () => {
    const provider = 'cfbd' as const;
    const sport = 'football' as const;
    const apiKey = CFBD_API_KEY.value();

    if (!apiKey) {
      console.log('[syncCollegeFootballNightly] Skipped — CFBD_API_KEY not set.');
      await writeSyncRun(provider, sport, 'skipped', 0, null, 'skipped — no key');
      return;
    }

    const progress: SyncProgress = { committed: 0 };
    try {
      if (await isDataFresh(provider, sport)) {
        console.log('[syncCollegeFootballNightly] Data is fresh — skipping provider call.');
        await writeSyncRun(provider, sport, 'skipped', 0, null, 'skipped — data fresh');
        return;
      }

      const client = createCfbdClient(apiKey);
      const [games, teamStats] = await Promise.all([
        client.getKentuckyGames(CURRENT_SEASON_FOOTBALL),
        client.getKentuckyTeamStats(CURRENT_SEASON_FOOTBALL),
      ]);

      const gameCount = await persistGames(games, CURRENT_SEASON_FOOTBALL, sport, progress);
      const statCount = await persistTeamStats(teamStats, progress);

      const total = gameCount + statCount;
      console.log(`[syncCollegeFootballNightly] Synced ${total} records.`);
      await writeSyncRun(provider, sport, 'success', total, null);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error('[syncCollegeFootballNightly] Error:', msg);
      await writeSyncRun(provider, sport, 'error', progress.committed, msg);
    }
  },
);

/**
 * Nightly basketball sync from CollegeBasketballData.
 * Skipped when CBBD_API_KEY is absent; staleness-checked at FRESHNESS_WINDOW_HOURS.
 */
export const syncCollegeBasketballNightly = onSchedule(
  { schedule: 'every day 03:30', timeZone: 'America/New_York', secrets: [CBBD_API_KEY] },
  async () => {
    const provider = 'cbbd' as const;
    const sport = 'mens_basketball' as const;
    const apiKey = CBBD_API_KEY.value();

    if (!apiKey) {
      console.log('[syncCollegeBasketballNightly] Skipped — CBBD_API_KEY not set.');
      await writeSyncRun(provider, sport, 'skipped', 0, null, 'skipped — no key');
      return;
    }

    const progress: SyncProgress = { committed: 0 };
    try {
      if (await isDataFresh(provider, sport)) {
        console.log('[syncCollegeBasketballNightly] Data is fresh — skipping provider call.');
        await writeSyncRun(provider, sport, 'skipped', 0, null, 'skipped — data fresh');
        return;
      }

      const client = createCbbdClient(apiKey);
      const [games, teamStats] = await Promise.all([
        client.getKentuckyGames(CURRENT_SEASON_BASKETBALL),
        client.getKentuckyTeamStats(CURRENT_SEASON_BASKETBALL),
      ]);

      const gameCount = await persistGames(games, CURRENT_SEASON_BASKETBALL, sport, progress);
      const statCount = await persistTeamStats(teamStats, progress);

      const total = gameCount + statCount;
      console.log(`[syncCollegeBasketballNightly] Synced ${total} records.`);
      await writeSyncRun(provider, sport, 'success', total, null);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error('[syncCollegeBasketballNightly] Error:', msg);
      await writeSyncRun(provider, sport, 'error', progress.committed, msg);
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
