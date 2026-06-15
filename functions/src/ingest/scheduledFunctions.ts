import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getDb, Timestamp } from '../core/admin';
import type { SyncRun } from '@bluegrass/shared-models';

const CURRENT_SEASON_FOOTBALL = 2026;
const CURRENT_SEASON_BASKETBALL = 2026;

async function writeSyncRunStub(
  provider: SyncRun['provider'],
  sport: SyncRun['sport'],
  note: string,
): Promise<void> {
  const db = getDb();
  const now = Timestamp.now();
  await db.collection('sync_runs').add({
    provider,
    sport,
    startedAt: now,
    completedAt: now,
    status: 'success' as const,
    recordsProcessed: 0,
    error: null,
    note, // extra observability field, not in the SyncRun type
  });
}

/**
 * Phase 1 stub — no real HTTP calls made.
 * Logs intent and writes a sync_runs record for observability.
 */
export const syncCollegeFootballNightly = onSchedule(
  { schedule: 'every day 03:00', timeZone: 'America/New_York' },
  async () => {
    console.log(
      `[syncCollegeFootballNightly] Phase 2 — not implemented. ` +
      `Would sync season ${CURRENT_SEASON_FOOTBALL} football from CFBD. No external call made.`,
    );
    await writeSyncRunStub(
      'cfbd',
      'football',
      'Phase 1 stub — no external call made',
    );
  },
);

export const syncCollegeBasketballNightly = onSchedule(
  { schedule: 'every day 03:30', timeZone: 'America/New_York' },
  async () => {
    console.log(
      `[syncCollegeBasketballNightly] Phase 2 — not implemented. ` +
      `Would sync season ${CURRENT_SEASON_BASKETBALL} basketball from CBBD. No external call made.`,
    );
    await writeSyncRunStub(
      'cbbd',
      'mens_basketball',
      'Phase 1 stub — no external call made',
    );
  },
);

export const syncGamedayScoreboard = onSchedule(
  { schedule: 'every 30 minutes', timeZone: 'America/New_York' },
  async () => {
    console.log(
      `[syncGamedayScoreboard] Phase 2 — not implemented. ` +
      `Would fetch live scoreboard. No external call made.`,
    );
    // No sync_run write for frequent stubs to avoid noise
  },
);
