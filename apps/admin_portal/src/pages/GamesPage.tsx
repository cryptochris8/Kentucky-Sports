import { useEffect, useState, type FormEvent } from 'react';
import { listGames, createGame, updateGame, toDisplayDate, timestampToLocalInput } from '../data/firestore';
import { parseScore, deriveTeamIds, orientationChanged, decideScoreUpdates } from '../data/gameFormLogic';
import { useAuth } from '../auth/AuthContext';
import type { Game, GameStatus, Sport } from '../data/types';
import {
  PageHeader, Button, Badge, Table, Thead, Th, Tbody, Tr, Td,
  LoadingState, EmptyState, ErrorState, Modal, FormField, Input, Select,
} from '../components/ui';

const SPORTS: Sport[] = ['football', 'mens_basketball', 'womens_basketball', 'baseball', 'volleyball'];
const STATUSES: GameStatus[] = ['scheduled', 'live', 'final', 'canceled', 'postponed'];

const TZ_HINT = `Local time — ${Intl.DateTimeFormat().resolvedOptions().timeZone}.`;

function statusColor(s: GameStatus): 'blue' | 'green' | 'red' | 'gray' {
  switch (s) {
    case 'scheduled': return 'blue';
    case 'live': return 'green';
    case 'final': return 'gray';
    case 'canceled': case 'postponed': return 'red';
    default: return 'gray';
  }
}

type FormData = {
  sport: Sport;
  opponentName: string;
  startTime: string;
  venue: string;
  status: GameStatus;
  featured: boolean;
  season: string;
  broadcast: string;
  isHome: boolean;
  homeScore: string;
  awayScore: string;
};

const EMPTY_FORM: FormData = {
  sport: 'football',
  opponentName: '',
  startTime: '',
  venue: '',
  status: 'scheduled',
  featured: false,
  season: new Date().getFullYear().toString(),
  broadcast: '',
  isHome: true,
  homeScore: '',
  awayScore: '',
};

export function GamesPage() {
  const { user } = useAuth();
  const [games, setGames] = useState<Game[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editGame, setEditGame] = useState<Game | null>(null);
  const [form, setForm] = useState<FormData>(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      setGames(await listGames());
      setError('');
    } catch (err: unknown) {
      setError((err as { message?: string }).message ?? 'Failed to load games.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const openCreate = () => {
    setEditGame(null);
    setForm(EMPTY_FORM);
    setSaveError('');
    setShowModal(true);
  };

  const openEdit = (g: Game) => {
    setEditGame(g);
    setForm({
      sport: g.sport,
      opponentName: g.opponentName,
      startTime: timestampToLocalInput(g.startTime),
      venue: g.venue,
      status: g.status,
      featured: g.featured,
      season: String(g.season),
      broadcast: g.broadcast ?? '',
      isHome: g.isHome ?? true,
      homeScore: g.homeScore != null ? String(g.homeScore) : '',
      awayScore: g.awayScore != null ? String(g.awayScore) : '',
    });
    setSaveError('');
    setShowModal(true);
  };

  const handleSave = async (e: FormEvent) => {
    e.preventDefault();
    setSaveError('');
    setSaving(true);
    try {
      // Fields the form actually binds — shared by create and update.
      const bound = {
        sport: form.sport,
        opponentName: form.opponentName,
        startTime: form.startTime, // converted to a Timestamp in the data layer
        venue: form.venue,
        status: form.status,
        featured: form.featured,
        season: parseInt(form.season, 10),
        broadcast: form.broadcast,
        isHome: form.isHome,
      };
      if (editGame) {
        // Update: ONLY form-bound fields (never overwrite `source` provenance —
        // cfbd / seed_demo stays intact). Scores are written when deliberately
        // entered, and cleared only on explicit intent (a pre-filled field
        // blanked, or status moving away from 'final') after a confirm.
        const payload: Partial<Omit<Game, 'id'>> = {
          ...bound,
          lastEditedBy: user?.uid ?? 'unknown',
        };
        // Keep the three orientation signals (isHome, homeTeamId, awayTeamId)
        // agreeing: recompute the team ids with the same derivation the create
        // path uses whenever a field that feeds it changed.
        if (orientationChanged(editGame, form)) {
          Object.assign(payload, deriveTeamIds(form.sport, form.opponentName, form.isHome));
        }
        const { updates, clearReason } = decideScoreUpdates(editGame, form);
        if (clearReason) {
          const message =
            clearReason === 'left_final'
              ? 'Status is moving away from "final" — the stored final score will be cleared. Continue?'
              : 'You cleared a previously saved score — it will be removed from the game. Continue?';
          if (!window.confirm(message)) {
            setSaveError('Save cancelled — the stored score was left unchanged.');
            return;
          }
        }
        Object.assign(payload, updates);
        await updateGame(editGame.id, payload);
      } else {
        await createGame({
          ...bound,
          ...deriveTeamIds(form.sport, form.opponentName, form.isHome),
          homeScore: form.status === 'final' ? parseScore(form.homeScore) : null,
          awayScore: form.status === 'final' ? parseScore(form.awayScore) : null,
          source: 'admin',
        });
      }
      setShowModal(false);
      await load();
    } catch (err: unknown) {
      setSaveError((err as { message?: string }).message ?? 'Save failed.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Games Manager"
        subtitle="Create and manage scheduled games."
        action={<Button onClick={openCreate}>+ New Game</Button>}
      />

      {loading && <LoadingState />}
      {error && <ErrorState message={error} />}

      {!loading && !error && (
        games.length === 0
          ? <EmptyState label="No games yet. Create the first one." />
          : (
            <Table>
              <Thead>
                <tr>
                  <Th>Sport</Th>
                  <Th>Opponent</Th>
                  <Th>Start Time</Th>
                  <Th>Venue</Th>
                  <Th>Status</Th>
                  <Th>Featured</Th>
                  <Th>Actions</Th>
                </tr>
              </Thead>
              <Tbody>
                {games.map((g) => (
                  <Tr key={g.id}>
                    <Td><Badge color="blue">{g.sport.replace('_', ' ')}</Badge></Td>
                    <Td className="font-medium">
                      {g.isHome === false ? 'at' : 'vs'} {g.opponentName}
                    </Td>
                    <Td className="text-gray-500 text-xs">{toDisplayDate(g.startTime)}</Td>
                    <Td className="text-gray-500">{g.venue}</Td>
                    <Td><Badge color={statusColor(g.status)}>{g.status}</Badge></Td>
                    <Td>
                      {g.featured
                        ? <Badge color="gold">Featured</Badge>
                        : <span className="text-gray-400 text-xs">—</span>}
                    </Td>
                    <Td>
                      <Button size="sm" variant="ghost" onClick={() => openEdit(g)}>Edit</Button>
                    </Td>
                  </Tr>
                ))}
              </Tbody>
            </Table>
          )
      )}

      {showModal && (
        <Modal
          title={editGame ? `Edit: ${editGame.isHome === false ? 'at' : 'vs'} ${editGame.opponentName}` : 'Create Game'}
          onClose={() => setShowModal(false)}
        >
          <form onSubmit={handleSave} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <FormField label="Sport" htmlFor="sport" required>
                <Select
                  id="sport"
                  value={form.sport}
                  onChange={(e) => setForm((f) => ({ ...f, sport: e.target.value as Sport }))}
                  required
                >
                  {SPORTS.map((s) => <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>)}
                </Select>
              </FormField>
              <FormField label="Season" htmlFor="season" required>
                <Input
                  id="season"
                  type="number"
                  value={form.season}
                  onChange={(e) => setForm((f) => ({ ...f, season: e.target.value }))}
                  required
                  min={2020}
                  max={2035}
                />
              </FormField>
            </div>

            <FormField label="Opponent Name" htmlFor="opponent" required>
              <Input
                id="opponent"
                value={form.opponentName}
                onChange={(e) => setForm((f) => ({ ...f, opponentName: e.target.value }))}
                placeholder="e.g. Louisville"
                required
              />
            </FormField>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Start Time" htmlFor="startTime" required note={TZ_HINT}>
                <Input
                  id="startTime"
                  type="datetime-local"
                  value={form.startTime}
                  onChange={(e) => setForm((f) => ({ ...f, startTime: e.target.value }))}
                  required
                />
              </FormField>
              <FormField label="Status" htmlFor="status">
                <Select
                  id="status"
                  value={form.status}
                  onChange={(e) => setForm((f) => ({ ...f, status: e.target.value as GameStatus }))}
                >
                  {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
                </Select>
              </FormField>
            </div>

            {/* Final score — only entered deliberately, never defaulted */}
            {form.status === 'final' && (
              <div className="grid grid-cols-2 gap-4">
                <FormField label="Home Score" htmlFor="homeScore"
                  note="Real final score only — leave blank if not yet known. Blanking a saved score clears it (with confirmation).">
                  <Input
                    id="homeScore"
                    type="number"
                    min={0}
                    value={form.homeScore}
                    onChange={(e) => setForm((f) => ({ ...f, homeScore: e.target.value }))}
                  />
                </FormField>
                <FormField label="Away Score" htmlFor="awayScore">
                  <Input
                    id="awayScore"
                    type="number"
                    min={0}
                    value={form.awayScore}
                    onChange={(e) => setForm((f) => ({ ...f, awayScore: e.target.value }))}
                  />
                </FormField>
              </div>
            )}

            <FormField label="Venue" htmlFor="venue" required>
              <Input
                id="venue"
                value={form.venue}
                onChange={(e) => setForm((f) => ({ ...f, venue: e.target.value }))}
                placeholder="e.g. Kroger Field"
                required
              />
            </FormField>

            <FormField label="Broadcast" htmlFor="broadcast">
              <Input
                id="broadcast"
                value={form.broadcast}
                onChange={(e) => setForm((f) => ({ ...f, broadcast: e.target.value }))}
                placeholder="e.g. ESPN"
              />
            </FormField>

            <div className="flex items-center gap-6">
              <div className="flex items-center gap-2">
                <input
                  id="isHome"
                  type="checkbox"
                  checked={form.isHome}
                  onChange={(e) => setForm((f) => ({ ...f, isHome: e.target.checked }))}
                  className="rounded border-gray-300 text-[#1E5AA8]"
                />
                <label htmlFor="isHome" className="text-sm text-gray-700">
                  Kentucky home game
                </label>
              </div>
              <div className="flex items-center gap-2">
                <input
                  id="featured"
                  type="checkbox"
                  checked={form.featured}
                  onChange={(e) => setForm((f) => ({ ...f, featured: e.target.checked }))}
                  className="rounded border-gray-300 text-[#1E5AA8]"
                />
                <label htmlFor="featured" className="text-sm text-gray-700">Featured game</label>
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
                {saving ? 'Saving…' : editGame ? 'Save Changes' : 'Create Game'}
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
