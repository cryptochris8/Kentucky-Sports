import { onCall } from 'firebase-functions/v2/https';
import { getDb, FieldValue } from '../core/admin';
import { assertRole } from '../core/auth';
import { requireString, requireEnum } from '../core/validate';
import { throwError } from '../core/errors';
import type { PostStatus, ModerationAction } from '@bluegrass/shared-models';

const VALID_STATUSES: PostStatus[] = ['visible', 'hidden', 'removed', 'pending'];

interface ModeratePostPayload {
  postId: string;
  status: PostStatus;
  reason: string;
}

export const adminModeratePost = onCall<ModeratePostPayload>(async (request) => {
  const uid = assertRole(request, ['moderator', 'editor', 'admin']);
  const { data } = request;

  const postId = requireString(data?.postId, 'postId');
  const status = requireEnum(data?.status, 'status', VALID_STATUSES);
  const reason = requireString(data?.reason, 'reason');

  const db = getDb();
  const postRef = db.collection('community_posts').doc(postId);
  const postSnap = await postRef.get();

  if (!postSnap.exists) {
    throwError('not-found', 'Post not found.');
  }

  const batch = db.batch();

  batch.update(postRef, {
    status,
    updatedAt: FieldValue.serverTimestamp(),
  });

  const action: Omit<ModerationAction, 'id'> = {
    postId,
    moderatorId: uid,
    status,
    reason,
    createdAt: new Date().toISOString(),
  };

  const actionRef = db.collection('moderation_actions').doc();
  batch.set(actionRef, {
    ...action,
    createdAt: FieldValue.serverTimestamp(),
  });

  await batch.commit();

  return { message: `Post ${postId} status set to "${status}".`, actionId: actionRef.id };
});
