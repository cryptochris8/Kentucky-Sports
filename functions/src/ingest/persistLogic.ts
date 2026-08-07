// Pure ingest persistence logic — no I/O, no Firebase imports.
// Imported by scheduledFunctions.ts (Firestore writer) and by unit tests.
//
// Provider payloads (CFBD/CBBD) key games on the provider's own ID, while the
// curated/seeded games use editorial IDs like "fb_2026_youngstown". These
// helpers let the sync find and update the EXISTING document — first by the
// stamped sourceGameId, then by a normalized (sport, Eastern-time day, opponent)
// key — instead of minting a duplicate parallel schedule.

import type { NormalizedGame, Sport } from '@bluegrass/shared-models';

/** How the normalized game looks from Kentucky's side of the scoreboard. */
export interface KentuckySide {
  isHome: boolean;
  opponentName: string;
}

/** Exact-name match so "Western Kentucky" / "Eastern Kentucky" never count. */
export function isKentuckyTeamName(name: string): boolean {
  return name.trim().toLowerCase() === 'kentucky';
}

/**
 * Detects which side of a provider game is Kentucky.
 * Returns null when neither (or both) sides are Kentucky — such a row cannot
 * be represented in the Kentucky-centric games schema and must be skipped.
 */
export function deriveKentuckySide(
  game: Pick<NormalizedGame, 'homeTeamName' | 'awayTeamName'>,
): KentuckySide | null {
  const home = isKentuckyTeamName(game.homeTeamName);
  const away = isKentuckyTeamName(game.awayTeamName);
  if (home === away) return null;
  return home
    ? { isHome: true, opponentName: game.awayTeamName }
    : { isHome: false, opponentName: game.homeTeamName };
}

/**
 * The America/New_York day (YYYY-MM-DD) of a game's start time — same approach
 * as dailyCapKey. NOT UTC: a 7pm+ ET kickoff is already the next day in UTC,
 * which would mismatch curated timeTbd docs dated on the ET calendar day and
 * mint a permanent duplicate game.
 * Accepts ISO strings (seed + provider docs) and Firestore Timestamps.
 * Returns null when the value cannot be parsed.
 */
export function gameDayKey(startTime: unknown): string | null {
  let date: Date | null = null;
  if (typeof startTime === 'string') {
    date = new Date(startTime);
  } else if (
    startTime !== null &&
    typeof startTime === 'object' &&
    typeof (startTime as { toDate?: unknown }).toDate === 'function'
  ) {
    date = (startTime as { toDate(): Date }).toDate();
  }
  if (!date || Number.isNaN(date.getTime())) return null;
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'America/New_York' }).format(date);
}

/**
 * Fallback match key for games that have no sourceGameId stamped yet:
 * sport + Eastern-time day + lowercased opponent school.
 */
export function gameMatchKey(sport: Sport, startTime: unknown, opponentName: string): string | null {
  const day = gameDayKey(startTime);
  if (!day) return null;
  return `${sport}|${day}|${opponentName.trim().toLowerCase()}`;
}

/**
 * Opponent team-ID slug matching the seed convention:
 * "Youngstown State" -> "opp_youngstown_state", "Texas A&M" -> "opp_texas_am".
 */
export function opponentTeamId(opponentName: string): string {
  const slug = opponentName
    .toLowerCase()
    .replace(/[^a-z0-9 ]+/g, '')
    .trim()
    .replace(/ +/g, '_');
  return `opp_${slug}`;
}

/** True when at least one stat value is present (not null/undefined). */
export function hasAnyStatValue(stats: Record<string, number | string | null>): boolean {
  return Object.values(stats).some((v) => v !== null && v !== undefined);
}
