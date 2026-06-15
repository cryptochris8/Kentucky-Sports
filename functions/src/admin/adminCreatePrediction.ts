import { onCall } from 'firebase-functions/v2/https';
import { getDb, FieldValue } from '../core/admin';
import { assertRole } from '../core/auth';
import { requireString, requireEnum } from '../core/validate';
import { throwError } from '../core/errors';
import type { Prediction, PredictionType, Sport } from '@bluegrass/shared-models';

const VALID_TYPES: readonly PredictionType[] = [
  'winner', 'margin_bucket', 'exact_score', 'threes_range',
  'leading_scorer', 'stat_over_under', 'upset_pick',
];

interface CreatePredictionPayload {
  gameId: string;
  sport: Sport;
  type: PredictionType;
  question: string;
  options: Array<{ id: string; label: string }>;
  opensAt: string;
  closesAt: string;
  points: number;
}

export const adminCreatePrediction = onCall<CreatePredictionPayload>(async (request) => {
  const uid = assertRole(request, ['editor', 'admin']);

  const data = request.data;
  const gameId = requireString(data?.gameId, 'gameId');
  const question = requireString(data?.question, 'question');
  const type = requireEnum(data?.type, 'type', VALID_TYPES);

  const rawOptions = data?.options;
  if (!Array.isArray(rawOptions) || rawOptions.length < 2) {
    throwError('invalid-argument', 'options must be an array of at least 2 items.');
  }

  const rawPoints = data?.points;
  if (typeof rawPoints !== 'number' || rawPoints <= 0) {
    throwError('invalid-argument', 'points must be a positive number.');
  }

  const prediction: Omit<Prediction, 'id'> = {
    gameId,
    sport: data?.sport,
    type,
    question,
    // rawOptions is guaranteed array here (throwError is never), cast to satisfy TS
    options: (rawOptions as Array<{ id: string; label: string }>).map((o) => ({
      id: String(o.id),
      label: String(o.label),
    })),
    opensAt: requireString(data?.opensAt, 'opensAt'),
    closesAt: requireString(data?.closesAt, 'closesAt'),
    status: 'open',
    points: rawPoints as number, // guaranteed number > 0 above
    createdBy: uid,
    createdAt: new Date().toISOString(),
  };

  const ref = await getDb().collection('predictions').add({
    ...prediction,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { predictionId: ref.id, message: 'Prediction created.' };
});
