import { useEffect, useState, type FormEvent } from 'react';
import { listNewsCards, createNewsCard, updateNewsCard, toDisplayDate } from '../data/firestore';
import { useAuth } from '../auth/AuthContext';
import type { NewsCard, Sport } from '../data/types';
import {
  PageHeader, Button, Badge, Table, Thead, Th, Tbody, Tr, Td,
  LoadingState, EmptyState, ErrorState, Modal, FormField, Input, Select, Textarea, Card,
} from '../components/ui';

const SPORTS = ['football', 'mens_basketball', 'womens_basketball', 'baseball', 'volleyball', 'high_school', 'general'];

type NewsForm = {
  title: string;
  sourceName: string;
  url: string;
  summary: string;
  sport: string;
  featured: boolean;
};

const EMPTY_FORM: NewsForm = {
  title: '',
  sourceName: '',
  url: '',
  summary: '',
  sport: 'football',
  featured: false,
};

export function NewsPage() {
  const { user } = useAuth();
  const [cards, setCards] = useState<NewsCard[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [editCard, setEditCard] = useState<NewsCard | null>(null);
  const [form, setForm] = useState<NewsForm>(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState('');
  // Failures from table-row actions (e.g. the featured toggle) — shown above
  // the table without hiding it.
  const [actionError, setActionError] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      setCards(await listNewsCards());
      setError('');
    } catch (err: unknown) {
      setError((err as { message?: string }).message ?? 'Failed to load news cards.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const openCreate = () => {
    setEditCard(null);
    setForm(EMPTY_FORM);
    setSaveError('');
    setShowModal(true);
  };

  const openEdit = (c: NewsCard) => {
    setEditCard(c);
    setForm({
      title: c.title,
      sourceName: c.sourceName,
      url: c.url,
      summary: c.summary,
      sport: c.sport,
      featured: c.featured,
    });
    setSaveError('');
    setShowModal(true);
  };

  const handleSave = async (e: FormEvent) => {
    e.preventDefault();
    setSaveError('');
    setSaving(true);
    try {
      if (editCard) {
        await updateNewsCard(editCard.id, {
          title: form.title,
          sourceName: form.sourceName,
          url: form.url,
          summary: form.summary,
          sport: form.sport,
          featured: form.featured,
        });
      } else {
        // publishedAt/createdAt are stamped with serverTimestamp() in the data layer.
        await createNewsCard({
          title: form.title,
          sourceName: form.sourceName,
          url: form.url,
          summary: form.summary,
          sport: form.sport as Sport,
          featured: form.featured,
          createdBy: user?.uid ?? 'unknown',
          tags: [],
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

  const toggleFeatured = async (c: NewsCard) => {
    setActionError('');
    try {
      await updateNewsCard(c.id, { featured: !c.featured });
      await load();
    } catch (err: unknown) {
      // A silent failure here reads as "the click didn't register" — surface it.
      setActionError(
        (err as { message?: string }).message ?? `Failed to update "${c.title}".`,
      );
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="News Cards CMS"
        subtitle="Curate link cards to external articles. Write your own summary — never paste article text."
        action={<Button onClick={openCreate}>+ Add News Card</Button>}
      />

      <Card>
        <p className="text-xs text-[#1E5AA8] font-medium">
          Content policy: Write your own short summary of the story. Link to the original
          source. Do not reproduce paywalled or copyrighted article text. Do not scrape
          restricted content (KSR+, On3, 247, Rivals, ESPN, MaxPreps).
        </p>
      </Card>

      {loading && <LoadingState />}
      {error && <ErrorState message={error} />}
      {actionError && (
        <p className="text-xs text-red-600 bg-red-50 rounded p-2">{actionError}</p>
      )}

      {!loading && !error && (
        cards.length === 0
          ? <EmptyState label="No news cards yet. Add the first one." />
          : (
            <Table>
              <Thead>
                <tr>
                  <Th>Title</Th>
                  <Th>Source</Th>
                  <Th>Sport</Th>
                  <Th>Published</Th>
                  <Th>Featured</Th>
                  <Th>Actions</Th>
                </tr>
              </Thead>
              <Tbody>
                {cards.map((c) => (
                  <Tr key={c.id}>
                    <Td className="max-w-xs">
                      <a
                        href={c.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="font-medium text-[#1E5AA8] hover:underline line-clamp-2"
                      >
                        {c.title}
                      </a>
                    </Td>
                    <Td className="text-gray-500">{c.sourceName}</Td>
                    <Td><Badge color="blue">{c.sport.replace(/_/g, ' ')}</Badge></Td>
                    <Td className="text-xs text-gray-500">{toDisplayDate(c.publishedAt)}</Td>
                    <Td>
                      <button
                        onClick={() => toggleFeatured(c)}
                        className="text-xs"
                        title="Toggle featured"
                      >
                        {c.featured
                          ? <Badge color="gold">Featured</Badge>
                          : <span className="text-gray-400">—</span>}
                      </button>
                    </Td>
                    <Td>
                      <Button size="sm" variant="ghost" onClick={() => openEdit(c)}>Edit</Button>
                    </Td>
                  </Tr>
                ))}
              </Tbody>
            </Table>
          )
      )}

      {showModal && (
        <Modal
          title={editCard ? 'Edit News Card' : 'Add News Card'}
          onClose={() => setShowModal(false)}
        >
          <form onSubmit={handleSave} className="space-y-4">
            <FormField label="Title" htmlFor="news-title" required>
              <Input
                id="news-title"
                value={form.title}
                onChange={(e) => setForm((f) => ({ ...f, title: e.target.value }))}
                placeholder="Headline text"
                required
              />
            </FormField>

            <div className="grid grid-cols-2 gap-4">
              <FormField label="Source Name" htmlFor="news-source" required>
                <Input
                  id="news-source"
                  value={form.sourceName}
                  onChange={(e) => setForm((f) => ({ ...f, sourceName: e.target.value }))}
                  placeholder="e.g. KSR, ESPN"
                  required
                />
              </FormField>
              <FormField label="Sport" htmlFor="news-sport" required>
                <Select
                  id="news-sport"
                  value={form.sport}
                  onChange={(e) => setForm((f) => ({ ...f, sport: e.target.value }))}
                  required
                >
                  {SPORTS.map((s) => <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>)}
                </Select>
              </FormField>
            </div>

            <FormField label="URL" htmlFor="news-url" required>
              <Input
                id="news-url"
                type="url"
                value={form.url}
                onChange={(e) => setForm((f) => ({ ...f, url: e.target.value }))}
                placeholder="https://…"
                required
              />
            </FormField>

            <FormField
              label="Admin-Written Summary"
              htmlFor="news-summary"
              required
              note="Write your own summary — do not paste article text. Keep it 1-3 sentences."
            >
              <Textarea
                id="news-summary"
                value={form.summary}
                onChange={(e) => setForm((f) => ({ ...f, summary: e.target.value }))}
                placeholder="Short admin-written summary of the story. Do not copy article text."
                rows={3}
                required
              />
            </FormField>

            <div className="flex items-center gap-2">
              <input
                id="news-featured"
                type="checkbox"
                checked={form.featured}
                onChange={(e) => setForm((f) => ({ ...f, featured: e.target.checked }))}
                className="rounded border-gray-300 text-[#1E5AA8]"
              />
              <label htmlFor="news-featured" className="text-sm text-gray-700">
                Feature this card (shows prominently in mobile app)
              </label>
            </div>

            {saveError && (
              <p className="text-xs text-red-600 bg-red-50 rounded p-2">{saveError}</p>
            )}

            <div className="flex justify-end gap-3 pt-2">
              <Button type="button" variant="secondary" onClick={() => setShowModal(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={saving}>
                {saving ? 'Saving…' : editCard ? 'Save Changes' : 'Add Card'}
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
