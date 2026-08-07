// Pins the role-list contract that App.tsx (route guards), AppShell.tsx (nav)
// and DashboardPage (quick links) all consume. Sync Health must stay
// admin-only — firestore.rules restricts sync_runs reads to isAdmin(), so any
// wider list advertises a page the backend will refuse.

import { describe, it, expect } from 'vitest';
import { ADMIN_ROLES, EDITOR_ROLES, MOD_ROLES } from './roles';

describe('portal role lists', () => {
  it('ADMIN_ROLES is exactly the admin role (mirrors sync_runs isAdmin() rule)', () => {
    expect(ADMIN_ROLES).toEqual(['admin']);
  });

  it('lists nest: every admin is an editor, every editor is a mod-tier user', () => {
    for (const r of ADMIN_ROLES) expect(EDITOR_ROLES).toContain(r);
    for (const r of EDITOR_ROLES) expect(MOD_ROLES).toContain(r);
  });

  it('editors are not admins (Sync Health stays hidden from them)', () => {
    expect(ADMIN_ROLES).not.toContain('editor');
    expect(ADMIN_ROLES).not.toContain('moderator');
  });
});
