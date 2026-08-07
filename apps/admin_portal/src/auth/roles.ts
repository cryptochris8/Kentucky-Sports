// Single source of truth for which roles may open which portal areas.
// App.tsx (route guards) and AppShell.tsx (sidebar filtering) both consume
// these so the nav never shows a link the router would bounce to /unauthorized.

import type { UserRole } from '../data/types';

/** Roles allowed into admin-only areas (Sync Health — firestore.rules restricts sync_runs reads to admins). */
export const ADMIN_ROLES: UserRole[] = ['admin'];

/** Roles allowed into the content-editing areas (games, predictions, news, vault). */
export const EDITOR_ROLES: UserRole[] = ['admin', 'editor'];

/** Roles allowed into the shell at all (adds moderation-only access). */
export const MOD_ROLES: UserRole[] = ['admin', 'editor', 'moderator'];
