import { onCall } from 'firebase-functions/v2/https';
import { getDb, FieldValue } from '../core/admin';
import { assertAuth } from '../core/auth';
import { requireString } from '../core/validate';
import { throwError } from '../core/errors';
import type { CommunityPost } from '@bluegrass/shared-models';

const ALLOWED_REACTIONS = ['like', 'fire', 'mindblown', 'cat', 'heart'] as const;
type ReactionType = (typeof ALLOWED_REACTIONS)[number];

interface ReactToPostPayload {
  postId: string;
  reactionType: ReactionType;
}

export const reactToPost = onCall<ReactToPostPayload>(async (request) => {
  const uid = assertAuth(request);
  const postId = requireString(request.data?.postId, 'postId');
  const reactionType = requireString(request.data?.reactionType, 'reactionType') as ReactionType;

  if (!ALLOWED_REACTIONS.includes(reactionType)) {
    throwError('invalid-argument', `Reaction must be one of: ${ALLOWED_REACTIONS.join(', ')}`);
  }

  const db = getDb();
  const postRef = db.collection('community_posts').doc(postId);
  const postSnap = await postRef.get();

  if (!postSnap.exists) {
    throwError('not-found', 'Post not found.');
  }

  const post = postSnap.data() as CommunityPost;
  if (post.status !== 'visible') {
    throwError('not-found', 'Post not found.');
  }

  // Idempotency: one reaction per user per type per post
  const reactionRef = db
    .collection('community_posts')
    .doc(postId)
    .collection('reactions')
    .doc(`${uid}_${reactionType}`);

  const reactionSnap = await reactionRef.get();
  if (reactionSnap.exists) {
    return { message: 'Reaction already recorded.' };
  }

  const batch = db.batch();
  batch.update(postRef, {
    [`reactionCounts.${reactionType}`]: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  });
  batch.set(reactionRef, {
    uid,
    reactionType,
    createdAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();

  return { message: 'Reaction recorded.' };
});
