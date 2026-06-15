import { useState } from 'react';
import { NavLink, useNavigate, Outlet } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

const NAV_ITEMS = [
  { to: '/', label: 'Dashboard', icon: '⬛' },
  { to: '/games', label: 'Games', icon: '🏟' },
  { to: '/predictions', label: 'Predictions', icon: '🎯' },
  { to: '/news', label: 'News CMS', icon: '📰' },
  { to: '/moderation', label: 'Moderation', icon: '🛡' },
  { to: '/sync', label: 'Sync Health', icon: '🔄' },
];

export function AppShell() {
  const { user, role, signOut } = useAuth();
  const navigate = useNavigate();
  const [sidebarOpen, setSidebarOpen] = useState(true);

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
          {NAV_ITEMS.map((item) => (
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
