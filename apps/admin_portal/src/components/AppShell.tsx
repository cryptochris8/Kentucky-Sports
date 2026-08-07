import { useState } from 'react';
import { NavLink, useNavigate, Outlet } from 'react-router';
import { useAuth } from '../auth/AuthContext';
import { ADMIN_ROLES, EDITOR_ROLES, MOD_ROLES } from '../auth/roles';
import type { UserRole } from '../data/types';

// `roles` mirrors the RoleGuard arrays in App.tsx (via auth/roles.ts) — a
// moderator only sees links the router will actually let them open.
const NAV_ITEMS: Array<{ to: string; label: string; icon: string; roles: UserRole[] }> = [
  { to: '/', label: 'Dashboard', icon: '⬛', roles: MOD_ROLES },
  { to: '/games', label: 'Games', icon: '🏟', roles: EDITOR_ROLES },
  { to: '/predictions', label: 'Predictions', icon: '🎯', roles: EDITOR_ROLES },
  { to: '/news', label: 'News CMS', icon: '📰', roles: EDITOR_ROLES },
  { to: '/vault', label: 'Vault', icon: '📜', roles: EDITOR_ROLES },
  { to: '/moderation', label: 'Moderation', icon: '🛡', roles: MOD_ROLES },
  { to: '/sync', label: 'Sync Health', icon: '🔄', roles: ADMIN_ROLES },
];

export function AppShell() {
  const { user, role, signOut } = useAuth();
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const visibleNavItems = NAV_ITEMS.filter((item) => role && item.roles.includes(role));

  const handleSignOut = async () => {
    await signOut();
    navigate('/login');
  };

  return (
    <div className="flex h-screen overflow-hidden bg-gray-50">
      {/* Sidebar */}
      <aside
        className={`flex flex-col bg-[#1E3A5F] text-white transition-all duration-200 ${
          sidebarOpen ? 'w-56' : 'w-14'
        } flex-shrink-0`}
      >
        {/* Logo / brand */}
        <div className="flex items-center gap-2 px-4 py-4 border-b border-white/10 min-h-[56px]">
          <span className="text-[#C8B273] font-bold text-lg leading-none shrink-0">BG</span>
          {sidebarOpen && (
            <span className="text-white font-semibold text-sm leading-tight">
              Bluegrass<br />
              <span className="text-[#C8B273]">Gameday</span> Admin
            </span>
          )}
        </div>

        {/* Nav */}
        <nav className="flex-1 py-4 overflow-y-auto">
          {visibleNavItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-2.5 text-sm transition-colors ${
                  isActive
                    ? 'bg-[#1E5AA8] text-white font-semibold border-l-4 border-[#C8B273]'
                    : 'text-white/70 hover:bg-white/10 hover:text-white border-l-4 border-transparent'
                }`
              }
            >
              <span className="text-base shrink-0">{item.icon}</span>
              {sidebarOpen && <span>{item.label}</span>}
            </NavLink>
          ))}
        </nav>

        {/* Collapse toggle */}
        <button
          onClick={() => setSidebarOpen((v) => !v)}
          className="px-4 py-3 text-white/50 hover:text-white text-xs border-t border-white/10 text-left"
        >
          {sidebarOpen ? '← Collapse' : '→'}
        </button>
      </aside>

      {/* Main area */}
      <div className="flex flex-col flex-1 overflow-hidden">
        {/* Topbar */}
        <header className="flex items-center justify-between bg-white border-b border-gray-200 px-6 h-14 shrink-0 shadow-sm">
          <h1 className="text-sm font-semibold text-gray-700 tracking-wide uppercase">
            Bluegrass Gameday — Admin Portal
          </h1>
          <div className="flex items-center gap-4">
            <span className="text-xs text-gray-500">
              {user?.email}{' '}
              {role && (
                <span className="ml-1 inline-block bg-[#1E5AA8] text-white rounded px-1.5 py-0.5 text-[10px] font-semibold uppercase">
                  {role}
                </span>
              )}
            </span>
            <button
              onClick={handleSignOut}
              className="text-xs text-gray-500 hover:text-red-600 transition-colors"
            >
              Sign out
            </button>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
