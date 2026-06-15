import type { CallableRequest } from 'firebase-functions/v2/https';
import { throwError } from './errors';
import type { Role } from '@bluegrass/shared-models';

/** Assert the caller is authenticated; returns uid */
export function assertAuth(request: CallableRequest): string {
  if (!request.auth?.uid) {
    throwError('unauthenticated', 'You must be signed in.');
  }
  // throwError above throws, so request.auth.uid is guaranteed defined here
  return request.auth!.uid;
}

/** Assert the caller has one of the allowed roles (via custom claim) */
export function assertRole(request: CallableRequest, allowedRoles: Role[]): string {
  const uid = assertAuth(request);
  const role = (request.auth?.token?.role as Role | undefined) ?? 'user';
  if (!allowedRoles.includes(role)) {
    throwError('permission-denied', `Required role: ${allowedRoles.join(' or ')}`);
  }
  return uid;
}
