// Unit tests for the Games Manager form logic: deliberate score clearing
// (blanked pre-filled fields / status reverts) vs. the no-touch default, and
// the shared homeTeamId/awayTeamId derivation that keeps isHome and the stored
// team ids from contradicting each other on edit.

import { describe, it, expect } from 'vitest';
import {
  parseScore,
  deriveTeamIds,
  orientationChanged,
  decideScoreUpdates,
} from './gameFormLogic';

describe('parseScore', () => {
  it('parses integers and treats blank/whitespace as null', () => {
    expect(parseScore('48')).toBe(48);
    expect(parseScore(' 7 ')).toBe(7);
    expect(parseScore('')).toBeNull();
    expect(parseScore('   ')).toBeNull();
  });
});

describe('deriveTeamIds', () => {
  it('puts Kentucky at home when isHome is true', () => {
    expect(deriveTeamIds('football', 'Youngstown State', true)).toEqual({
      homeTeamId: 'kentucky_football',
      awayTeamId: 'opp_youngstown_state',
    });
  });

  it('puts Kentucky away when isHome is false', () => {
    expect(deriveTeamIds('mens_basketball', 'Louisville', false)).toEqual({
      homeTeamId: 'opp_louisville',
      awayTeamId: 'kentucky_mens_basketball',
    });
  });
});

describe('orientationChanged', () => {
  const existing = { sport: 'football' as const, opponentName: 'Louisville', isHome: true };

  it('is false when nothing feeding the derivation changed', () => {
    expect(
      orientationChanged(existing, { sport: 'football', opponentName: 'Louisville', isHome: true }),
    ).toBe(false);
  });

  it('is true when isHome flips', () => {
    expect(
      orientationChanged(existing, { sport: 'football', opponentName: 'Louisville', isHome: false }),
    ).toBe(true);
  });

  it('is true when sport or opponent changes', () => {
    expect(
      orientationChanged(existing, { sport: 'mens_basketball', opponentName: 'Louisville', isHome: true }),
    ).toBe(true);
    expect(
      orientationChanged(existing, { sport: 'football', opponentName: 'Vanderbilt', isHome: true }),
    ).toBe(true);
  });

  it('treats a missing isHome on the doc as home (mirrors the form default)', () => {
    const noFlag = { sport: 'football' as const, opponentName: 'Louisville', isHome: undefined };
    expect(
      orientationChanged(noFlag, { sport: 'football', opponentName: 'Louisville', isHome: true }),
    ).toBe(false);
    expect(
      orientationChanged(noFlag, { sport: 'football', opponentName: 'Louisville', isHome: false }),
    ).toBe(true);
  });
});

describe('decideScoreUpdates', () => {
  const finalWithScores = { status: 'final' as const, homeScore: 48, awayScore: 23 };
  const finalNoScores = { status: 'final' as const, homeScore: null, awayScore: null };
  const scheduled = { status: 'scheduled' as const, homeScore: null, awayScore: null };

  it('writes deliberately entered scores on a final game', () => {
    const d = decideScoreUpdates(finalNoScores, { status: 'final', homeScore: '48', awayScore: '23' });
    expect(d.updates).toEqual({ homeScore: 48, awayScore: 23 });
    expect(d.clearReason).toBeNull();
  });

  it('untouched blank inputs mean no-touch (nothing stored, nothing written)', () => {
    const d = decideScoreUpdates(finalNoScores, { status: 'final', homeScore: '', awayScore: '' });
    expect(d.updates).toEqual({});
    expect(d.clearReason).toBeNull();
  });

  it('a pre-filled field blanked by the admin is an explicit clear', () => {
    const d = decideScoreUpdates(finalWithScores, { status: 'final', homeScore: '', awayScore: '' });
    expect(d.updates).toEqual({ homeScore: null, awayScore: null });
    expect(d.clearReason).toBe('blanked');
  });

  it('can clear one side while keeping (rewriting) the other', () => {
    const d = decideScoreUpdates(finalWithScores, { status: 'final', homeScore: '48', awayScore: '' });
    expect(d.updates).toEqual({ homeScore: 48, awayScore: null });
    expect(d.clearReason).toBe('blanked');
  });

  it('status moving away from final clears the stored scores', () => {
    const d = decideScoreUpdates(finalWithScores, { status: 'scheduled', homeScore: '48', awayScore: '23' });
    expect(d.updates).toEqual({ homeScore: null, awayScore: null });
    expect(d.clearReason).toBe('left_final');
  });

  it('status moving away from final with no stored scores writes nothing', () => {
    const d = decideScoreUpdates(finalNoScores, { status: 'postponed', homeScore: '', awayScore: '' });
    expect(d.updates).toEqual({});
    expect(d.clearReason).toBeNull();
  });

  it('never writes scores while the game is not final', () => {
    const d = decideScoreUpdates(scheduled, { status: 'scheduled', homeScore: '', awayScore: '' });
    expect(d.updates).toEqual({});
    expect(d.clearReason).toBeNull();
  });
});
