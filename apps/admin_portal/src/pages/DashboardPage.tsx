import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { getDashboardCounts, listSyncRuns, toDisplayDate } from '../data/firestore';
import type { SyncRun } from '../data/types';
import { Card, LoadingState, ErrorState, Badge, PageHeader } from '../components/ui';

interface Counts {
  games: number;
  predictions: number;
  news: number;
  posts: number;
}

function syncStatusColor(status: SyncRun['status']): 'green' | 'red' | 'blue' | 'yellow' {
  switch (status) {
    case 'success': return 'green';
    case 'error': return 'red';
    case 'running': return 'blue';
    default: return 'yellow';
  }
}

export function DashboardPage() {
  const [counts, setCounts] = useState<Counts | null>(null);
  const [syncRuns, setSyncRuns] = useState<SyncRun[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      try {
        const [c, runs] = await Promise.all([
          getDashboardCounts(),
          listSyncRuns(5),
        ]);
        setCounts(c);
        setSyncRuns(runs);
      } catch (err: unknown) {
        const e = err as { message?: string };
        setError(e.message ?? 'Failed to load dashboard data.');
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  if (loading) return <LoadingState label="Loading dashboard…" />;
  if (error) return <ErrorState message={error} />;

  const statCards = [
    { label: 'Games', count: counts?.games ?? 0, to: '/games', icon: '🏟', color: 'text-[#1E5AA8]' },
    { label: 'Predictions', count: counts?.predictions ?? 0, to: '/predictions', icon: '🎯', color: 'text-purple-600' },
    { label: 'News Cards', count: counts?.news ?? 0, to: '/news', icon: '📰', color: 'text-green-600' },
    { label: 'Community Posts', count: counts?.posts ?? 0, to: '/moderation', icon: '💬', color: 'text-orange-600' },
  ];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        subtitle="Overview of content, predictions, and sync health."
      />

      {/* Stat cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((s) => (
          <Link key={s.label} to={s.to}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer">
              <div className="flex items-start justify-between mb-2">
                <span className="text-2xl">{s.icon}</span>
                <span className={`text-3xl font-bold ${s.color}`}>{s.count}</span>
              </div>
              <p className="text-sm text-gray-500 font-medium">{s.label}</p>
            </Card>
          </Link>
        ))}
      </div>

      {/* Quick links */}
      <Card>
        <h3 className="font-semibold text-gray-800 mb-3">Quick Links</h3>
        <div className="flex flex-wrap gap-3">
          {[
            { to: '/games', label: '+ Add Game' },
            { to: '/predictions', label: '+ Create Prediction' },
            { to: '/news', label: '+ Add News Card' },
            { to: '/moderation', label: 'Review Posts' },
            { to: '/sync', label: 'Sync Health' },
          ].map((l) => (
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

      {/* Recent sync runs */}
      <Card>
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-gray-800">Recent Sync Runs</h3>
          <Link to="/sync" className="text-xs text-[#1E5AA8] hover:underline">
            View all →
          </Link>
        </div>
        {syncRuns.length === 0 ? (
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
