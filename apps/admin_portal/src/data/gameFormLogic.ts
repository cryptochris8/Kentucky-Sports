// Pure decision helpers for the Games Manager form (pages/GamesPage.tsx).
// Split out of the page so the score-clearing and home/away-orientation rules
// — both honest-data hard rules — are unit-testable without rendering React.

import type { Game, GameStatus, Sport } from './types';

/** '' -> null; otherwise a parsed integer. */
export function parseScore(v: string): number | null {
  const trimmed = v.trim();
  return trimmed === '' ? null : parseInt(trimmed, 10);
}

/**
 * The one derivation of homeTeamId/awayTeamId from the form fields — used by
 * BOTH the create and update paths so isHome and the stored team ids can never
 * disagree about which side is home.
 */
export function deriveTeamIds(
  sport: Sport,
  opponentName: string,
  isHome: boolean,
): { homeTeamId: string; awayTeamId: string } {
  const kentuckyId = `kentucky_${sport}`;
  const opponentId = `opp_${opponentName.toLowerCase().replace(/\s+/g, '_')}`;
  return {
    homeTeamId: isHome ? kentuckyId : opponentId,
    awayTeamId: isHome ? opponentId : kentuckyId,
  };
}

/**
 * True when a field feeding the team-id derivation changed on an edit — the
 * update must then recompute homeTeamId/awayTeamId, or teamId-first consumers
 * (article generator, score attribution) keep the OLD orientation while
 * isHome-first consumers show the new one.
 */
export function orientationChanged(
  existing: Pick<Game, 'sport' | 'opponentName' | 'isHome'>,
  form: { sport: Sport; opponentName: string; isHome: boolean },
): boolean {
  return (
    form.sport !== existing.sport ||
    form.opponentName !== existing.opponentName ||
    form.isHome !== (existing.isHome ?? true)
  );
}

export interface ScoreDecision {
  /** Score fields to merge into the update payload; empty = untouched inputs, no-touch. */
  updates: { homeScore?: number | null; awayScore?: number | null };
  /** Set when the updates null out a stored score — the UI must confirm before saving. */
  clearReason: 'blanked' | 'left_final' | null;
}

/**
 * Decide what (if anything) to write for homeScore/awayScore on update:
 *   - status 'final' + a value entered            -> write the value
 *   - status 'final' + a pre-filled field blanked -> explicit clear (null, confirmed)
 *   - status moved away from 'final'              -> stored scores cleared (null, confirmed)
 *   - a blank field that was never filled         -> untouched, write nothing
 * The no-touch default protects real scores from accidental wipes; the two
 * clear paths keep a deliberately wrong score removable through the portal.
 */
export function decideScoreUpdates(
  existing: Pick<Game, 'status' | 'homeScore' | 'awayScore'>,
  form: { status: GameStatus; homeScore: string; awayScore: string },
): ScoreDecision {
  const updates: ScoreDecision['updates'] = {};
  let clearReason: ScoreDecision['clearReason'] = null;

  if (existing.status === 'final' && form.status !== 'final') {
    // Status revert: a final score must not survive on a game that is no
    // longer final — it would read as a fabricated result on an unplayed game.
    if (existing.homeScore != null) updates.homeScore = null;
    if (existing.awayScore != null) updates.awayScore = null;
    if ('homeScore' in updates || 'awayScore' in updates) clearReason = 'left_final';
    return { updates, clearReason };
  }

  if (form.status === 'final') {
    const hs = parseScore(form.homeScore);
    const as = parseScore(form.awayScore);
    if (hs !== null) {
      updates.homeScore = hs;
    } else if (existing.homeScore != null) {
      updates.homeScore = null; // pre-filled from the doc, deliberately blanked
      clearReason = 'blanked';
    }
    if (as !== null) {
      updates.awayScore = as;
    } else if (existing.awayScore != null) {
      updates.awayScore = null;
      clearReason = 'blanked';
    }
  }

  return { updates, clearReason };
}
