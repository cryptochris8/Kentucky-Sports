import { onCall } from 'firebase-functions/v2/https';
import { getDb } from '../core/admin';
import { assertAuth } from '../core/auth';
import { requireString } from '../core/validate';
import { throwError } from '../core/errors';
import type { Poll } from '@bluegrass/shared-models';

interface VotePollPayload {
  pollId: string;
  optionId: string;
}

export const votePoll = onCall<VotePollPayload>(async (request) => {
  const uid = assertAuth(request);
  const pollId = requireString(request.data?.pollId, 'pollId');
  const optionId = requireString(request.data?.optionId, 'optionId');

  const db = getDb();
  const pollRef = db.collection('polls').doc(pollId);
  const pollSnap = await pollRef.get();

  if (!pollSnap.exists) {
    throwError('not-found', 'Poll not found.');
  }

  const poll = pollSnap.data() as Poll;

  if (poll.status !== 'open') {
    throwError('failed-precondition', 'This poll is closed.');
  }

  const closesAtRaw = poll.closesAt as unknown;
  let closesAt: Date;
  if (
    typeof closesAtRaw === 'object' &&
    closesAtRaw !== null &&
    typeof (closesAtRaw as Record<string, unknown>)['toMillis'] === 'function'
  ) {
    closesAt = new Date((closesAtRaw as { toMillis: () => number }).toMillis());
  } else if (typeof closesAtRaw === 'object' && closesAtRaw !== null && 'seconds' in closesAtRaw) {
    closesAt = new Date((closesAtRaw as { seconds: number }).seconds * 1000);
  } else {
    closesAt = new Date(closesAtRaw as string);
  }

  if (new Date() >= closesAt) {
    throwError('failed-precondition', 'This poll has closed.');
  }

  // Validate optionId
  const validOption = poll.options.find((o) => o.id === optionId);
  if (!validOption) {
    throwError('invalid-argument', 'Invalid poll option.');
  }

  // Idempotency: check if user already voted
  const voteRef = db
    .collection('polls')
    .doc(pollId)
    .collection('votes')
    .doc(uid);
  const voteSnap = await voteRef.get();

  if (voteSnap.exists) {
    throwError('already-exists', 'You have already voted in this poll.');
  }

  // Use a transaction: Firestore cannot atomically increment a field inside an array element,
  // so we read-modify-write the options array atomically and also record the vote doc.
  await db.runTransaction(async (tx) => {
    // Re-read inside transaction for consistency
    const pollSnapTx = await tx.get(pollRef);
    if (!pollSnapTx.exists) throwError('not-found', 'Poll not found.');

    const pollTx = pollSnapTx.data() as Poll;
    const updatedOptions = pollTx.options.map((o) =>
      o.id === optionId ? { ...o, votes: (o.votes ?? 0) + 1 } : o,
    );

    tx.update(pollRef, { options: updatedOptions });
    tx.set(voteRef, { optionId, votedAt: new Date().toISOString(), uid });
  });

  return { message: 'Vote recorded.' };
});
