/**
 * Tests for the adminScorePrediction callable (predictions/adminScorePrediction.ts)
 * against the in-memory Firestore fake — no emulator, no network.
 *
 * Pinned behaviors:
 *   - the already-scored guard and the correctOptionId write happen inside ONE
 *     transaction (TOCTOU fix: two concurrent admin calls cannot both pass the
 *     status read and grade entries against different correct answers)
 *   - already-scored predictions are refused with nothing written
 *   - option validation still runs, and a rejected call writes nothing
 *
 * scorePredictionEntries is mocked: the scoring engine has its own writer-layer
 * suite (scoringWriter.test.ts); here it only matters whether it was invoked.
 */
import { describe, it, expect, beforeEach, vi } from 'vitest';
import type { CallableRequest } from 'firebase-functions/v2/https';

vi.mock('../core/admin', async () => {
  const { fakeDb, FieldValueMock, TimestampMock } = await import('./helpers/fakeFirestore');
  return { getDb: () => fakeDb, FieldValue: FieldValueMock, Timestamp: TimestampMock };
});

vi.mock('../predictions/scoring', () => ({
  scorePredictionEntries: vi.fn(async () => 2),
}));

import { adminScorePrediction } from '../predictions/adminScorePrediction';
import { scorePredictionEntries } from '../predictions/scoring';
import { fakeDb } from './helpers/fakeFirestore';

const scoreMock = vi.mocked(scorePredictionEntries);

interface Payload {
  predictionId?: unknown;
  correctOptionId?: unknown;
}

function req(data: Payload, role: string = 'admin') {
  return {
    data,
    auth: { uid: 'admin_user', token: { role } },
  } as unknown as CallableRequest<{ predictionId: string; correctOptionId: string }>;
}

beforeEach(() => {
  fakeDb.reset();
  scoreMock.mockClear();
  fakeDb.seed('predictions/pred1', {
    id: 'pred1',
    gameId: 'game1',
    type: 'winner',
    status: 'open',
    correctOptionId: null,
    options: [
      { id: 'kentucky', label: 'Kentucky' },
      { id: 'opponent', label: 'Opponent' },
    ],
  });
});

describe('adminScorePrediction', () => {
  it('writes correctOptionId + closed status transactionally, then scores', async () => {
    const res = await adminScorePrediction.run(
      req({ predictionId: 'pred1', correctOptionId: 'kentucky' }),
    );

    expect(res).toEqual({ message: 'Scored 2 entries.', processed: 2 });
    expect(fakeDb.read('predictions/pred1')).toMatchObject({
      correctOptionId: 'kentucky',
      status: 'closed',
    });
    expect(scoreMock).toHaveBeenCalledWith('pred1');

    // The answer write must go through the transaction (op 'tx.update'), not a
    // bare ref.update — that is the whole TOCTOU fix.
    const predWrites = fakeDb.writeLog.filter((w) => w.path === 'predictions/pred1');
    expect(predWrites).toHaveLength(1);
    expect(predWrites[0].op).toBe('tx.update');
  });

  it('refuses an already-scored prediction inside the transaction and writes nothing', async () => {
    fakeDb.seed('predictions/pred1', {
      id: 'pred1',
      gameId: 'game1',
      type: 'winner',
      status: 'scored',
      correctOptionId: 'kentucky',
      options: [
        { id: 'kentucky', label: 'Kentucky' },
        { id: 'opponent', label: 'Opponent' },
      ],
    });

    await expect(
      adminScorePrediction.run(req({ predictionId: 'pred1', correctOptionId: 'opponent' })),
    ).rejects.toThrow('This prediction has already been scored.');

    // The original answer survives untouched and no re-grade was attempted.
    expect(fakeDb.read('predictions/pred1')).toMatchObject({
      correctOptionId: 'kentucky',
      status: 'scored',
    });
    expect(fakeDb.writeLog).toHaveLength(0);
    expect(scoreMock).not.toHaveBeenCalled();
  });

  it('still validates the option id and writes nothing on a typo', async () => {
    await expect(
      adminScorePrediction.run(req({ predictionId: 'pred1', correctOptionId: 'not_an_option' })),
    ).rejects.toThrow(/correctOptionId must be one of/);

    expect(fakeDb.read('predictions/pred1')).toMatchObject({
      correctOptionId: null,
      status: 'open',
    });
    expect(fakeDb.writeLog).toHaveLength(0);
    expect(scoreMock).not.toHaveBeenCalled();
  });

  it('rejects unknown predictions', async () => {
    await expect(
      adminScorePrediction.run(req({ predictionId: 'missing', correctOptionId: 'kentucky' })),
    ).rejects.toThrow('Prediction not found.');
    expect(scoreMock).not.toHaveBeenCalled();
  });

  it('rejects callers without the editor/admin role', async () => {
    await expect(
      adminScorePrediction.run(req({ predictionId: 'pred1', correctOptionId: 'kentucky' }, 'user')),
    ).rejects.toThrow('Required role: editor or admin');
    expect(fakeDb.writeLog).toHaveLength(0);
    expect(scoreMock).not.toHaveBeenCalled();
  });
});
