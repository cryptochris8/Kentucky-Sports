import { useEffect, useState } from 'react';
import { listSyncRuns, toDisplayDate } from '../data/firestore';
import type { SyncRun } from '../data/types';
import {
  PageHeader, Button, Badge, Table, Thead, Th, Tbody, Tr, Td,
  LoadingState, EmptyState, ErrorState, Card,
} from '../components/ui';

function statusColor(s: SyncRun['status']): 'green' | 'red' | 'blue' | 'yellow' {
  switch (s) {
    case 'success': return 'green';
    case 'error': return 'red';
    case 'running': return 'blue';
    case 'skipped': return 'yellow'; // no-op run: no key configured, or data fresh
    default: return 'yellow';
  }
}

export function SyncHealthPage() {
  const [runs, setRuns] = useState<SyncRun[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      try {
        setRuns(await listSyncRuns(50));
      } catch (err: unknown) {
        setError((err as { message?: string }).message ?? 'Failed to load sync runs.');
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Sync Health"
        subtitle="Monitor data-provider sync runs (Cloud Functions write these records)."
        action={
          <Button
            disabled
            title="Manual triggers are a Phase 2 feature"
          >
            Trigger Sync (Phase 2)
          </Button>
        }
      />

      <Card>
        <p className="text-xs text-gray-500">
          Sync runs are created by Firebase Cloud Functions (Phase 2 — CollegeFootballData,
          CollegeBasketballData). The manual trigger button above is stubbed and will be wired
          up in Phase 2. Runs appear here automatically as Functions execute.
        </p>
      </Card>

      {loading && <LoadingState />}
      {error && <ErrorState message={error} />}

      {!loading && !error && (
        runs.length === 0
          ? (
            <EmptyState
              label="No sync runs found. Sync runs are written here by Cloud Functions (Phase 2)."
            />
          )
          : (
            <Table>
              <Thead>
                <tr>
                  <Th>Provider</Th>
                  <Th>Status</Th>
                  <Th>Records</Th>
                  <Th>Failures</Th>
                  <Th>Started</Th>
                  <Th>Completed</Th>
                  <Th>Error</Th>
                </tr>
              </Thead>
              <Tbody>
                {runs.map((r) => (
                  <Tr key={r.id}>
                    <Td className="font-medium">{r.provider}</Td>
                    <Td><Badge color={statusColor(r.status)}>{r.status}</Badge></Td>
                    <Td className="text-center text-gray-600">
                      {r.recordsProcessed ?? '—'}
                    </Td>
                    <Td className="text-center text-gray-600">
                      {r.recordsFailed ?? '—'}
                    </Td>
                    <Td className="text-xs text-gray-500">{toDisplayDate(r.startedAt)}</Td>
                    <Td className="text-xs text-gray-500">
                      {r.completedAt ? toDisplayDate(r.completedAt) : '—'}
                    </Td>
                    <Td className="text-xs text-red-500 max-w-xs truncate">
                      {r.errorMessage ?? '—'}
                    </Td>
                  </Tr>
                ))}
              </Tbody>
            </Table>
          )
      )}
    </div>
  );
}
