import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router';
import { toDisplayDate } from '../data/firestore';
import { listVaultLegends } from '../data/vault';
import type { VaultLegend, VaultLegendStatus } from '../data/types';
import { sportLabel, statusColor } from '../data/vaultGuards';
import {
  PageHeader, Button, Badge, Table, Thead, Th, Tbody, Tr, Td,
  LoadingState, EmptyState, ErrorState, Card, Select,
} from '../components/ui';

const STATUS_FILTERS: Array<VaultLegendStatus | 'all'> = ['all', 'draft', 'ready', 'published'];

export function VaultLegendsPage() {
  const navigate = useNavigate();
  const [legends, setLegends] = useState<VaultLegend[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [statusFilter, setStatusFilter] = useState<VaultLegendStatus | 'all'>('all');
  const [sportFilter, setSportFilter] = useState<string>('all');

  const load = async () => {
    setLoading(true);
    try {
      setLegends(await listVaultLegends());
      setError('');
    } catch (err: unknown) {
      setError((err as { message?: string }).message ?? 'Failed to load legends.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const sports = useMemo(
    () => Array.from(new Set(legends.map((l) => l.sport))).sort(),
    [legends],
  );

  const filtered = useMemo(
    () => legends.filter((l) =>
      (statusFilter === 'all' || l.status === statusFilter) &&
      (sportFilter === 'all' || l.sport === sportFilter)),
    [legends, statusFilter, sportFilter],
  );

  return (
    <div className="space-y-6">
      <PageHeader
        title="The Vault — Legends Editor"
        subtitle="AI drafts a Kentucky history feature from sourced facts. You edit it and publish."
      />

      <Card>
        <p className="text-xs text-[#1E5AA8] font-medium">
          Editor-in-chief workflow: every legend is grounded in a sourced fact-brief.
          Keep attribution intact, verify the numbers, and never publish betting language.
          Drafts are private; only published legends appear in the app.
        </p>
      </Card>

      {!loading && !error && legends.length > 0 && (
        <div className="flex flex-wrap items-end gap-4">
          <div>
            <label htmlFor="vault-status" className="block text-xs font-medium text-gray-500 mb-1">
              Status
            </label>
            <Select
              id="vault-status"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as VaultLegendStatus | 'all')}
              className="w-44"
            >
              {STATUS_FILTERS.map((s) => (
                <option key={s} value={s}>{s === 'all' ? 'All statuses' : s}</option>
              ))}
            </Select>
          </div>
          <div>
            <label htmlFor="vault-sport" className="block text-xs font-medium text-gray-500 mb-1">
              Sport
            </label>
            <Select
              id="vault-sport"
              value={sportFilter}
              onChange={(e) => setSportFilter(e.target.value)}
              className="w-48"
            >
              <option value="all">All sports</option>
              {sports.map((s) => <option key={s} value={s}>{sportLabel(s)}</option>)}
            </Select>
          </div>
          <span className="text-xs text-gray-400 pb-2">
            {filtered.length} of {legends.length}
          </span>
        </div>
      )}

      {loading && <LoadingState />}
      {error && <ErrorState message={error} />}

      {!loading && !error && (
        legends.length === 0
          ? <EmptyState label="No legends yet. Run the legend generator, then seed the emulator." />
          : filtered.length === 0
            ? <EmptyState label="No legends match these filters." />
            : (
              <Table>
                <Thead>
                  <tr>
                    <Th>Subject / Title</Th>
                    <Th>Sport</Th>
                    <Th>Era</Th>
                    <Th>Status</Th>
                    <Th>Updated</Th>
                    <Th>Actions</Th>
                  </tr>
                </Thead>
                <Tbody>
                  {filtered.map((l) => (
                    <Tr key={l.id} className="cursor-pointer" >
                      <Td className="max-w-sm" >
                        <button
                          onClick={() => navigate(`/vault/${l.id}`)}
                          className="text-left"
                        >
                          <span className="block font-semibold text-[#1E5AA8] hover:underline line-clamp-1">
                            {l.title}
                          </span>
                          <span className="block text-xs text-gray-500">{l.subject}</span>
                        </button>
                      </Td>
                      <Td><Badge color="blue">{sportLabel(l.sport)}</Badge></Td>
                      <Td className="text-xs text-gray-500">{l.era}</Td>
                      <Td><Badge color={statusColor(l.status)}>{l.status}</Badge></Td>
                      <Td className="text-xs text-gray-500">
                        {toDisplayDate(l.updatedAt ?? l.generatedAt)}
                      </Td>
                      <Td>
                        <Button size="sm" variant="ghost" onClick={() => navigate(`/vault/${l.id}`)}>
                          Edit
                        </Button>
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
