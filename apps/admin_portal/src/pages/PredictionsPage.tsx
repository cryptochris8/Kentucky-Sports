import { useEffect, useState, type FormEvent } from 'react';
import {
  listPredictions,
  createPrediction,
  closePrediction,
  getPredictionEntryCount,
  toDisplayDate,
} from '../data/firestore';
import type { Prediction, PredictionType, Sport } from '../data/types';
import {
  PageHeader, Button, Badge, Table, Thead, Th, Tbody, Tr, Td,
  LoadingState, EmptyState, ErrorState, Modal, FormField, Input, Select, Card,
} from '../components/ui';

const SPORTS: Sport[] = ['football', 'mens_basketball', 'womens_basketball', 'baseball', 'volleyball'];
const TYPES: PredictionType[] = ['winner', 'margin_bucket', 'threes_range', 'total_points', 'custom'];

function statusColor(s: Prediction['status']): 'green' | 'gray' | 'blue' | 'red' {
  switch (s) {
    case 'open': return 'green';
    case 'closed': return 'gray';
    case 'scored': return 'blue';
    case 'cancelled': return 'red';
    default: return 'gray';
  }
}

type OptionRow = { id: string; label: string };

type PredForm = {
  gameId: string;
  sport: Sport;
  type: PredictionType;
  question: string;
  points: string;
  opensAt: string;
  closesAt: string;
  options: OptionRow[];
};

const EMPTY_FORM: PredForm = {
  gameId: '',
  sport: 'football',
  type: 'winner',
  question: '',
  points: '10',
  opensAt: '',
  closesAt: '',
  options: [
    { id: 'kentucky', label: 'Kentucky' },
    { id: 'opponent', label: 'Opponent' },
  ],
};

export function PredictionsPage() {
  const [predictions, setPredictions] = useState<Prediction[]>([]);
  const [entryCounts, setEntryCounts] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState<PredForm>(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const preds = await listPredictions();
      setPredictions(preds);
      // Fetch entry counts in parallel (best-effort)
      const counts: Record<string, number> = {};
      await Promise.allSettled(
        preds.map(async (p) => {
          counts[p.id] = await getPredictionEntryCount(p.id);
        })
      );
      setEntryCounts(counts);
    } catch (err: unknown) {
      setError((err as { message?: string }).message ?? 'Failed to load predictions.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const handleClose = async (id: string) => {
    if (!confirm('Close this prediction now? Users will no longer be able to submit entries.')) return;
    try {
      await closePrediction(id);
      await load();
    } catch (err: unknown) {
      alert((err as { message?: string }).message ?? 'Failed to close.');
    }
  };

  const handleSave = async (e: FormEvent) => {
    e.preventDefault();
    setSaveError('');
    setSaving(true);
    try {
      await createPrediction({
        gameId: form.gameId,
        sport: form.sport,
        type: form.type,
        question: form.question,
        points: parseInt(form.points, 10),
        opensAt: form.opensAt,
        closesAt: form.closesAt,
        options: form.options.filter((o) => o.id && o.label),
        status: 'open',
        createdBy: 'admin',
      });
      setShowModal(false);
      await load();
    } catch (err: unknown) {
      setSaveError((err as { message?: string }).message ?? 'Save failed.');
    } finally {
      setSaving(false);
    }
  };

  const updateOption = (i: number, field: keyof OptionRow, value: string) => {
    setForm((f) => {
      const opts = [...f.options];
      opts[i] = { ...opts[i], [field]: value };
      return { ...f, options: opts };
    });
  };

  const addOption = () => {
    setForm((f) => ({
      ...f,
      options: [...f.options, { id: `opt_${f.options.length + 1}`, label: '' }],
    }));
  };

  const removeOption = (i: number) => {
    setForm((f) => ({ ...f, options: f.options.filter((_, idx) => idx !== i) }));
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Predictions Manager"
        subtitle="Create prediction questions, manage status, and view entry counts."
        action={
          <Button onClick={() => { setForm(EMPTY_FORM); setSaveError(''); setShowModal(true); }}>
            + New Prediction
          </Button>
        }
      />

      <Card>
        <p className="text-xs text-gray-500">
          Predictions are free-to-play challenges. Never use betting language — use pick /
          prediction / confidence / points / XP.
        </p>
      </Card>

      {loading && <LoadingState />}
      {error && <ErrorState message={error} />}

      {!loading && !error && (
        predictions.length === 0
          ? <EmptyState label="No predictions yet." />
          : (
            <Table>
              <Thead>
                <tr>
                  <Th>Question</Th>
                  <Th>Type</Th>
                  <Th>Points</Th>
                  <Th>Closes</Th>
                  <Th>Status</Th>
                  <Th>Entries</Th>
                  <Th>Actions</Th>
                </tr>
              </Thead>
              <Tbody>
                {predictions.map((p) => (
                  <Tr key={p.id}>
                    <Td className="max-w-xs truncate font-medium">{p.question}</Td>
                    <Td><Badge color="gray">{p.type.replace(/_/g, ' ')}</Badge></Td>
                    <Td className="text-center">{p.points}</Td>
                    <Td className="text-xs text-gray-500">{toDisplayDate(p.closesAt)}</Td>
                    <Td><Badge color={statusColor(p.status)}>{p.status}</Badge></Td>
                    <Td className="text-center text-sm text-gray-600">
                      {entryCounts[p.id] ?? '—'}
                    </Td>
                    <Td>
                      {p.status === 'open' && (
                        <Button size="sm" variant="secondary" onClick={() => handleClose(p.id)}>
                          Close
                        </Button>
                      )}
                    </Td>
                  </Tr>
                ))}
              </Tbody>
            </Table>
          )
      )}

      {showModal && (
        <Modal title="Create Prediction" onClose={() => setShowModal(false)}>
          <form onSubmit={handleSave} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <FormField label="Sport" htmlFor="pred-sport" required>
                <Select
                  id="pred-sport"
                  value={form.sport}
                  onChange={(e) => setForm((f) => ({ ...f, sport: e.target.value as Sport }))}
                  required
                >
                  {SPORTS.map((s) => <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>)}
                </Select>
              </FormField>
              <FormField label="Type" htmlFor="pred-type" required>
                <Select
                  id="pred-type"
                  value={form.type}
                  onChange={(e) => setForm((f) => ({ ...f, type: e.target.value as PredictionType }))}
                  required
                >
                  {TYPES.map((t) => <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>)}
                </Select>
              </FormField>
            </div>

            <FormField label="Game ID" htmlFor="pred-gameId"
              note="Enter the Firestore game document ID, e.g. fb_2026_open_toledo">
              <Input
                id="pred-gameId"
                value={form.gameId}
                onChange={(e) => setForm((f) => ({ ...f, gameId: e.target.value }))}
                placeholder="fb_2026_open_toledo"
              />
            </FormField>

            <FormField label="Question" htmlFor="pred-question" required>
              <Input
                id="pred-question"
                value={form.question}
                onChange={(e) => setForm((f) => ({ ...f, question: e.target.value }))}
                placeholder="e.g. Who wins the season opener?"
                required
              />
            </FormField>

            <div className="grid grid-cols-3 gap-4">
              <FormField label="Points" htmlFor="pred-points" required>
                <Input
                  id="pred-points"
                  type="number"
                  value={form.points}
                  onChange={(e) => setForm((f) => ({ ...f, points: e.target.value }))}
                  min={1}
                  required
                />
              </FormField>
              <FormField label="Opens At" htmlFor="pred-opens" required>
                <Input
                  id="pred-opens"
                  type="datetime-local"
                  value={form.opensAt}
                  onChange={(e) => setForm((f) => ({ ...f, opensAt: e.target.value }))}
                  required
                />
              </FormField>
              <FormField label="Closes At" htmlFor="pred-closes" required>
                <Input
                  id="pred-closes"
                  type="datetime-local"
                  value={form.closesAt}
                  onChange={(e) => setForm((f) => ({ ...f, closesAt: e.target.value }))}
                  required
                />
              </FormField>
            </div>

            {/* Options */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="text-sm font-medium text-gray-700">Answer Options</label>
                <Button type="button" size="sm" variant="ghost" onClick={addOption}>
                  + Add option
                </Button>
              </div>
              <div className="space-y-2">
                {form.options.map((opt, i) => (
                  <div key={i} className="flex items-center gap-2">
                    <Input
                      value={opt.id}
                      onChange={(e) => updateOption(i, 'id', e.target.value)}
                      placeholder="id"
                      className="w-28"
                    />
                    <Input
                      value={opt.label}
                      onChange={(e) => updateOption(i, 'label', e.target.value)}
                      placeholder="Label"
                      className="flex-1"
                    />
                    {form.options.length > 2 && (
                      <Button
                        type="button"
                        size="sm"
                        variant="ghost"
                        onClick={() => removeOption(i)}
                        className="text-red-500 shrink-0"
                      >
                        ✕
                      </Button>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {saveError && (
              <p className="text-xs text-red-600 bg-red-50 rounded p-2">{saveError}</p>
            )}

            <div className="flex justify-end gap-3 pt-2">
              <Button type="button" variant="secondary" onClick={() => setShowModal(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={saving}>
                {saving ? 'Creating…' : 'Create Prediction'}
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
