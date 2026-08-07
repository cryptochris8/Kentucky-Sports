import { useEffect, useState } from 'react';
import { Link } from 'react-router';
import { getDashboardCounts, listSyncRuns, toDisplayDate, type DashboardCounts } from '../data/firestore';
import type { SyncRun, UserRole } from '../data/types';
import { useAuth } from '../auth/AuthContext';
import { ADMIN_ROLES, EDITOR_ROLES, MOD_ROLES } from '../auth/roles';
import { Card, LoadingState, Badge, PageHeader } from '../components/ui';

function syncStatusColor(status: SyncRun['status']): 'green' | 'red' | 'blue' | 'yellow' {
  switch (status) {
    case 'success': return 'green';
    case 'error': return 'red';
    case 'running': return 'blue';
    default: return 'yellow';
  }
}

export function DashboardPage() {
  const { role } = useAuth();
  const [counts, setCounts] = useState<DashboardCounts | null>(null);
  const [syncRuns, setSyncRuns] = useState<SyncRun[]>([]);
  // Per-panel error tolerance: one failed read degrades that panel, never the
  // whole page — moderators (who can't read sync_runs) still get a dashboard.
  const [syncError, setSyncError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      const [countsResult, runsResult] = await Promise.allSettled([
        getDashboardCounts(),
        listSyncRuns(5),
      ]);
      if (countsResult.status === 'fulfilled') {
        setCounts(countsResult.value);
      } else {
        setCounts({ games: null, predictions: null, news: null, posts: null });
      }
      if (runsResult.status === 'fulfilled') {
        setSyncRuns(runsResult.value);
      } else {
        const e = runsResult.reason as { code?: string; message?: string };
        setSyncError(
          e.code === 'permission-denied'
            ? 'Sync history is restricted to admins.'
            : e.message ?? 'Failed to load sync runs.',
        );
      }
      setLoading(false);
    })();
  }, []);

  if (loading) return <LoadingState label="Loading dashboard…" />;

  const statCards = [
    { label: 'Games', count: counts?.games ?? null, to: '/games', icon: '🏟', color: 'text-[#1E5AA8]' },
    { label: 'Predictions', count: counts?.predictions ?? null, to: '/predictions', icon: '🎯', color: 'text-purple-600' },
    { label: 'News Cards', count: counts?.news ?? null, to: '/news', icon: '📰', color: 'text-green-600' },
    { label: 'Visible Posts', count: counts?.posts ?? null, to: '/moderation', icon: '💬', color: 'text-orange-600' },
  ];

  const quickLinks: Array<{ to: string; label: string; roles: UserRole[] }> = [
    { to: '/games', label: '+ Add Game', roles: EDITOR_ROLES },
    { to: '/predictions', label: '+ Create Prediction', roles: EDITOR_ROLES },
    { to: '/news', label: '+ Add News Card', roles: EDITOR_ROLES },
    { to: '/moderation', label: 'Review Posts', roles: MOD_ROLES },
    { to: '/sync', label: 'Sync Health', roles: ADMIN_ROLES },
  ];
  const visibleLinks = quickLinks.filter((l) => role && l.roles.includes(role));

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        subtitle="Overview of content, predictions, and sync health."
      />

      {/* Stat cards — a count the role can't read shows as restricted, not a dead page */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((s) => (
          <Link key={s.label} to={s.to}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer">
              <div className="flex items-start justify-between mb-2">
                <span className="text-2xl">{s.icon}</span>
                {s.count === null
                  ? <span className="text-3xl font-bold text-gray-300" title="Not available for your role">—</span>
                  : <span className={`text-3xl font-bold ${s.color}`}>{s.count}</span>}
              </div>
              <p className="text-sm text-gray-500 font-medium">{s.label}</p>
              {s.count === null && (
                <p className="text-[11px] text-gray-400 mt-0.5">Not available for your role</p>
              )}
            </Card>
          </Link>
        ))}
      </div>

      {/* Quick links */}
      {visibleLinks.length > 0 && (
        <Card>
          <h3 className="font-semibold text-gray-800 mb-3">Quick Links</h3>
          <div className="flex flex-wrap gap-3">
            {visibleLinks.map((l) => (
              <Link
                key={l.to}
                to={l.to}
                className="text-sm text-[#1E5AA8] underline underline-offset-2 hover:text-[#1a4d94]"
              >
                {l.label}
              </Link>
            ))}
          </div>
        </Card>
      )}

      {/* Recent sync runs */}
      <Card>
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-gray-800">Recent Sync Runs</h3>
          {!syncError && (
            <Link to="/sync" className="text-xs text-[#1E5AA8] hover:underline">
              View all →
            </Link>
          )}
        </div>
        {syncError ? (
          <p className="text-sm text-gray-400 py-4 text-center">{syncError}</p>
        ) : syncRuns.length === 0 ? (
          <p className="text-sm text-gray-400 py-4 text-center">
            No sync runs yet. Sync runs are written by Cloud Functions (Phase 2).
          </p>
        ) : (
          <div className="space-y-2">
            {syncRuns.map((run) => (
              <div
                key={run.id}
                className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0"
              >
                <div>
                  <span className="text-sm font-medium text-gray-700">{run.provider}</span>
                  {run.errorMessage && (
                    <p className="text-xs text-red-500 mt-0.5 truncate max-w-xs">
                      {run.errorMessage}
                    </p>
                  )}
                </div>
                <div className="flex items-center gap-3 shrink-0">
                  {run.recordsProcessed !== undefined && (
                    <span className="text-xs text-gray-400">{run.recordsProcessed} records</span>
                  )}
                  <Badge color={syncStatusColor(run.status)}>{run.status}</Badge>
                  <span className="text-xs text-gray-400 hidden sm:inline">
                    {toDisplayDate(run.startedAt)}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>

      <p className="text-xs text-gray-400 text-center">
        Bluegrass Gameday is an independent fan app — not affiliated with UK Athletics, the NCAA, or the SEC.
      </p>
    </div>
  );
}
