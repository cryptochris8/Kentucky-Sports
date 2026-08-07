/**
 * Writer-layer tests for scorePredictionEntries (predictions/scoring.ts)
 * against the in-memory Firestore fake — no emulator, no network.
 *
 * Pinned behaviors:
 *   1. Happy path: entries score, XP lands, prediction flips to 'scored'.
 *   2. Badge-evaluation failures are collected and rethrown AFTER every entry
 *      has been attempted, and the prediction is NOT marked 'scored'.
 *   3. A retry after a badge failure re-runs evaluateBadges for the
 *      already-scored entries WITHOUT double-awarding XP, then marks the
 *      prediction 'scored'.
 */
import { describe, it, expect, beforeEach, vi } from 'vitest';

vi.mock('../core/admin', async () => {
  const { fakeDb, FieldValueMock, TimestampMock } = await import('./helpers/fakeFirestore');
  return { getDb: () => fakeDb, FieldValue: FieldValueMock, Timestamp: TimestampMock };
});

vi.mock('../rewards/badges', () => ({
  evaluateBadges: vi.fn(async () => [] as string[]),
}));

import { scorePredictionEntries } from '../predictions/scoring';
import { evaluateBadges } from '../rewards/badges';
import { fakeDb } from './helpers/fakeFirestore';

const evaluateBadgesMock = vi.mocked(evaluateBadges);

/** Winner prediction with two entries: user1 picked right, user2 picked wrong. */
function seedScoringFixture(): void {
  fakeDb.reset();
  fakeDb.seed('predictions/pred1', {
    id: 'pred1',
    gameId: 'game1',
    type: 'winner',
    status: 'closed',
    correctOptionId: 'kentucky',
    options: [
      { id: 'kentucky', label: 'Kentucky' },
      { id: 'opponent', label: 'Opponent' },
    ],
  });
  fakeDb.seed('prediction_entries/entry1', {
    id: 'entry1',
    predictionId: 'pred1',
    userId: 'user1',
    selectedOptionId: 'kentucky',
    numericValue: null,
    isCorrect: null,
    pointsAwarded: 0,
    locked: true,
  });
  fakeDb.seed('prediction_entries/entry2', {
    id: 'entry2',
    predictionId: 'pred1',
    userId: 'user2',
    selectedOptionId: 'opponent',
    numericValue: null,
    isCorrect: null,
    pointsAwarded: 0,
    locked: true,
  });
  fakeDb.seed('users/user1', {
    id: 'user1',
    xp: 100,
    level: 1,
    predictionRecord: { total: 3, correct: 2, streak: 2 },
  });
  fakeDb.seed('users/user2', {
    id: 'user2',
    xp: 40,
    level: 1,
    predictionRecord: { total: 1, correct: 0, streak: 0 },
  });
}

beforeEach(() => {
  seedScoringFixture();
  evaluateBadgesMock.mockClear();
});

describe('scorePredictionEntries — happy path', () => {
  it('scores every entry, awards XP, and marks the prediction scored', async () => {
    const processed = await scorePredictionEntries('pred1');
    expect(processed).toBe(2);

    // Entries locked with their outcome.
    expect(fakeDb.read('prediction_entries/entry1')).toMatchObject({
      isCorrect: true,
      pointsAwarded: 10, // BASE_POINTS.winner
    });
    expect(fakeDb.read('prediction_entries/entry2')).toMatchObject({
      isCorrect: false,
      pointsAwarded: 0,
    });

    // XP: correct_prediction = 20 (XP_TABLE); incorrect picks earn nothing.
    expect(fakeDb.read('users/user1')).toMatchObject({
      xp: 120,
      predictionRecord: { total: 4, correct: 3, streak: 3 },
    });
    expect(fakeDb.read('users/user2')).toMatchObject({
      xp: 40,
      predictionRecord: { total: 2, correct: 0, streak: 0 },
    });

    // Badges evaluated for both users, with the post-entry record.
    expect(evaluateBadgesMock).toHaveBeenCalledTimes(2);
    expect(evaluateBadgesMock).toHaveBeenCalledWith('user1', {
      predictionCount: 4,
      correctPredictions: 3,
      predictionStreak: 3,
      hasExactScore: false,
      hasUpsetCorrect: false,
    });

    expect(fakeDb.read('predictions/pred1')).toMatchObject({ status: 'scored' });
  });
});

describe('scorePredictionEntries — badge failures must not vanish', () => {
  it('attempts every entry, rethrows the badge failure, and does NOT mark the prediction scored', async () => {
    evaluateBadgesMock.mockRejectedValueOnce(new Error('badge backend down'));

    await expect(scorePredictionEntries('pred1')).rejects.toThrow(
      /Badge evaluation failed for user\(s\) user1 on prediction pred1/,
    );

    // Both entries were still scored before the rethrow — scoring is
    // transaction-committed per entry and idempotent-safe on retry.
    expect(fakeDb.read('prediction_entries/entry1')).toMatchObject({ isCorrect: true });
    expect(fakeDb.read('prediction_entries/entry2')).toMatchObject({ isCorrect: false });
    expect(evaluateBadgesMock).toHaveBeenCalledTimes(2);

    // The run had errors, so the prediction must stay un-scored for the retry.
    expect(fakeDb.read('predictions/pred1')).toMatchObject({ status: 'closed' });
  });

  it('a retry re-runs evaluateBadges for already-scored entries without double-awarding XP', async () => {
    evaluateBadgesMock.mockRejectedValueOnce(new Error('badge backend down'));
    await scorePredictionEntries('pred1').catch(() => undefined);
    evaluateBadgesMock.mockClear();

    // Retry (e.g. the onGameUpdated re-fire with retry: true).
    const processed = await scorePredictionEntries('pred1');
    expect(processed).toBe(0); // nothing newly scored

    // No double XP / record increment on the retry.
    expect(fakeDb.read('users/user1')).toMatchObject({
      xp: 120,
      predictionRecord: { total: 4, correct: 3, streak: 3 },
    });
    expect(fakeDb.read('users/user2')).toMatchObject({
      xp: 40,
      predictionRecord: { total: 2, correct: 0, streak: 0 },
    });

    // But badges DID get a second chance — create() makes re-award impossible.
    expect(evaluateBadgesMock).toHaveBeenCalledTimes(2);
    expect(evaluateBadgesMock).toHaveBeenCalledWith('user1', {
      predictionCount: 4,
      correctPredictions: 3,
      predictionStreak: 3,
      hasExactScore: false,
      hasUpsetCorrect: false,
    });

    // Clean run — now the prediction may flip to scored.
    expect(fakeDb.read('predictions/pred1')).toMatchObject({ status: 'scored' });
  });
});
