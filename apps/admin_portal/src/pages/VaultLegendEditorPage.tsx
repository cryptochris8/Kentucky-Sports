import { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  getVaultLegend,
  saveVaultLegend,
  setLegendStatus,
  getLegendBrief,
} from '../data/vault';
import { toDisplayDate } from '../data/firestore';
import type { VaultLegend, VaultLegendSection, LegendBrief } from '../data/types';
import {
  sportLabel,
  statusColor,
  untraceableNumbers,
  checkPublishReady,
} from '../data/vaultGuards';
import {
  PageHeader, Button, Badge, Card, Input, Textarea, FormField,
  LoadingState, ErrorState,
} from '../components/ui';

// Editable shape: the subset of fields the editor form binds to.
interface LegendForm {
  title: string;
  subtitle: string;
  sections: VaultLegendSection[];
  byTheNumbers: string[];
  pullQuote: string;
  closingLine: string;
  sources: string[];
}

function toForm(l: VaultLegend): LegendForm {
  return {
    title: l.title ?? '',
    subtitle: l.subtitle ?? '',
    sections: (l.sections ?? []).map((s) => ({ heading: s.heading, body: s.body })),
    byTheNumbers: [...(l.byTheNumbers ?? [])],
    pullQuote: l.pullQuote ?? '',
    closingLine: l.closingLine ?? '',
    sources: [...(l.sources ?? [])],
  };
}

type Feedback = { kind: 'success' | 'error'; text: string } | null;

export function VaultLegendEditorPage() {
  const { id = '' } = useParams<{ id: string }>();
  const navigate = useNavigate();

  const [legend, setLegend] = useState<VaultLegend | null>(null);
  const [brief, setBrief] = useState<LegendBrief | null>(null);
  const [form, setForm] = useState<LegendForm | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [feedback, setFeedback] = useState<Feedback>(null);
  const [blockers, setBlockers] = useState<string[]>([]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const l = await getVaultLegend(id);
      if (!l) { setError('Legend not found.'); return; }
      setLegend(l);
      setForm(toForm(l));
      setError('');
      // Brief is best-effort context for the fact-check guard.
      try { setBrief(await getLegendBrief(id)); } catch { setBrief(null); }
    } catch (err: unknown) {
      setError((err as { message?: string }).message ?? 'Failed to load legend.');
    } finally {
      setLoading(false);
    }
  }, [id]);

  useEffect(() => { load(); }, [load]);

  // ─── Form mutators ──────────────────────────────────────────────────────────
  const patch = (p: Partial<LegendForm>) => setForm((f) => (f ? { ...f, ...p } : f));

  const setSection = (i: number, key: keyof VaultLegendSection, value: string) =>
    setForm((f) => {
      if (!f) return f;
      const sections = [...f.sections];
      sections[i] = { ...sections[i], [key]: value };
      return { ...f, sections };
    });
  const addSection = () =>
    setForm((f) => (f ? { ...f, sections: [...f.sections, { heading: '', body: '' }] } : f));
  const removeSection = (i: number) =>
    setForm((f) => (f ? { ...f, sections: f.sections.filter((_, idx) => idx !== i) } : f));
  const moveSection = (i: number, dir: -1 | 1) =>
    setForm((f) => {
      if (!f) return f;
      const j = i + dir;
      if (j < 0 || j >= f.sections.length) return f;
      const sections = [...f.sections];
      [sections[i], sections[j]] = [sections[j], sections[i]];
      return { ...f, sections };
    });

  // Generic string-list editors (byTheNumbers, sources).
  const setListItem = (key: 'byTheNumbers' | 'sources', i: number, value: string) =>
    setForm((f) => {
      if (!f) return f;
      const list = [...f[key]];
      list[i] = value;
      return { ...f, [key]: list };
    });
  const addListItem = (key: 'byTheNumbers' | 'sources') =>
    setForm((f) => (f ? { ...f, [key]: [...f[key], ''] } : f));
  const removeListItem = (key: 'byTheNumbers' | 'sources', i: number) =>
    setForm((f) => (f ? { ...f, [key]: f[key].filter((_, idx) => idx !== i) } : f));

  // ─── Derived: clean payload + guards ────────────────────────────────────────
  const cleanForm = useMemo(() => {
    if (!form) return null;
    return {
      title: form.title.trim(),
      subtitle: form.subtitle.trim(),
      sections: form.sections
        .map((s) => ({ heading: s.heading.trim(), body: s.body.trim() }))
        .filter((s) => s.heading || s.body),
      byTheNumbers: form.byTheNumbers.map((s) => s.trim()).filter(Boolean),
      pullQuote: form.pullQuote.trim(),
      closingLine: form.closingLine.trim(),
      sources: form.sources.map((s) => s.trim()).filter(Boolean),
    };
  }, [form]);

  const publishCheck = useMemo(
    () => (cleanForm ? checkPublishReady(cleanForm) : { ok: false, failures: [] }),
    [cleanForm],
  );

  // ─── Actions ────────────────────────────────────────────────────────────────
  const persist = async (): Promise<boolean> => {
    if (!cleanForm) return false;
    await saveVaultLegend(id, cleanForm);
    return true;
  };

  const onSave = async () => {
    setBusy(true); setFeedback(null); setBlockers([]);
    try {
      await persist();
      await load();
      setFeedback({ kind: 'success', text: 'Draft saved.' });
    } catch (err: unknown) {
      setFeedback({ kind: 'error', text: (err as { message?: string }).message ?? 'Save failed.' });
    } finally {
      setBusy(false);
    }
  };

  const onMarkReady = async () => {
    setBusy(true); setFeedback(null); setBlockers([]);
    try {
      await persist();
      await setLegendStatus(id, 'ready');
      await load();
      setFeedback({ kind: 'success', text: 'Saved and marked ready for review.' });
    } catch (err: unknown) {
      setFeedback({ kind: 'error', text: (err as { message?: string }).message ?? 'Update failed.' });
    } finally {
      setBusy(false);
    }
  };

  const onPublish = async () => {
    setFeedback(null);
    const check = cleanForm ? checkPublishReady(cleanForm) : { ok: false, failures: ['Nothing to publish.'] };
    if (!check.ok) {
      setBlockers(check.failures);
      setFeedback({ kind: 'error', text: 'Cannot publish — resolve the blockers below.' });
      return;
    }
    setBusy(true); setBlockers([]);
    try {
      await persist();
      await setLegendStatus(id, 'published');
      await load();
      setFeedback({ kind: 'success', text: 'Published. This legend is now live in the app.' });
    } catch (err: unknown) {
      setFeedback({ kind: 'error', text: (err as { message?: string }).message ?? 'Publish failed.' });
    } finally {
      setBusy(false);
    }
  };

  const onUnpublish = async () => {
    setBusy(true); setFeedback(null); setBlockers([]);
    try {
      await setLegendStatus(id, 'draft');
      await load();
      setFeedback({ kind: 'success', text: 'Unpublished. Back to draft (hidden from the app).' });
    } catch (err: unknown) {
      setFeedback({ kind: 'error', text: (err as { message?: string }).message ?? 'Unpublish failed.' });
    } finally {
      setBusy(false);
    }
  };

  // ─── Render ─────────────────────────────────────────────────────────────────
  if (loading) return <LoadingState label="Opening the Vault…" />;
  if (error) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" size="sm" onClick={() => navigate('/vault')}>← Back to legends</Button>
        <ErrorState message={error} />
      </div>
    );
  }
  if (!legend || !form || !cleanForm) return <ErrorState message="Legend unavailable." />;

  return (
    <div className="space-y-5">
      <PageHeader
        title={legend.subject}
        subtitle={`${sportLabel(legend.sport)} · ${legend.era}`}
        action={
          <div className="flex items-center gap-2">
            <Badge color={statusColor(legend.status)}>{legend.status}</Badge>
            <Button variant="ghost" size="sm" onClick={() => navigate('/vault')}>
              ← Back
            </Button>
          </div>
        }
      />

      {/* Action bar */}
      <Card className="!p-3">
        <div className="flex flex-wrap items-center gap-2">
          <Button onClick={onSave} disabled={busy}>{busy ? 'Working…' : 'Save'}</Button>
          <Button variant="secondary" onClick={onMarkReady} disabled={busy}>Mark ready</Button>
          <Button
            variant="primary"
            onClick={onPublish}
            disabled={busy || !publishCheck.ok}
            title={publishCheck.ok ? 'Publish to the app' : 'Resolve pre-publish blockers first'}
            className="!bg-green-700 hover:!bg-green-800 focus:!ring-green-700"
          >
            Publish
          </Button>
          {legend.status === 'published' && (
            <Button variant="danger" onClick={onUnpublish} disabled={busy}>Unpublish</Button>
          )}
          <span className="ml-auto" />
          {feedback && (
            <span
              className={`text-xs font-medium rounded px-2 py-1 ${
                feedback.kind === 'success'
                  ? 'text-green-700 bg-green-50'
                  : 'text-red-700 bg-red-50'
              }`}
            >
              {feedback.text}
            </span>
          )}
        </div>
        {blockers.length > 0 && (
          <ul className="mt-2 list-disc list-inside text-xs text-red-700 bg-red-50 rounded p-2 space-y-0.5">
            {blockers.map((b, i) => <li key={i}>{b}</li>)}
          </ul>
        )}
        {!publishCheck.ok && publishCheck.failures.length > 0 && blockers.length === 0 && (
          <p className="mt-2 text-[11px] text-gray-400">
            Publish is disabled: {publishCheck.failures.join(' ')}
          </p>
        )}
      </Card>

      {/* Two-pane layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5 items-start">
        <LegendForm
          form={form}
          legend={legend}
          brief={brief}
          patch={patch}
          setSection={setSection}
          addSection={addSection}
          removeSection={removeSection}
          moveSection={moveSection}
          setListItem={setListItem}
          addListItem={addListItem}
          removeListItem={removeListItem}
        />
        <div className="lg:sticky lg:top-4">
          <LegendPreview legend={legend} form={cleanForm} />
        </div>
      </div>
    </div>
  );
}

// ─── Left pane: structured form ─────────────────────────────────────────────────

interface FormPaneProps {
  form: LegendForm;
  legend: VaultLegend;
  brief: LegendBrief | null;
  patch: (p: Partial<LegendForm>) => void;
  setSection: (i: number, key: keyof VaultLegendSection, value: string) => void;
  addSection: () => void;
  removeSection: (i: number) => void;
  moveSection: (i: number, dir: -1 | 1) => void;
  setListItem: (key: 'byTheNumbers' | 'sources', i: number, value: string) => void;
  addListItem: (key: 'byTheNumbers' | 'sources') => void;
  removeListItem: (key: 'byTheNumbers' | 'sources', i: number) => void;
}

function LegendForm(p: FormPaneProps) {
  const { form, legend, brief } = p;
  return (
    <div className="space-y-5">
      {/* Provenance (read-only) */}
      <Card>
        <h3 className="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-3">
          Provenance
        </h3>
        <dl className="grid grid-cols-2 gap-x-4 gap-y-2 text-xs">
          <Prov label="Model" value={legend.model} />
          <Prov label="Confidence" value={legend.confidence} />
          <Prov label="Status" value={legend.status} />
          <Prov label="Brief" value={brief ? brief.id : 'none found'} />
          <Prov label="Generated" value={toDisplayDate(legend.generatedAt)} />
          <Prov label="Updated" value={toDisplayDate(legend.updatedAt)} />
        </dl>
        {!brief && (
          <p className="mt-3 text-[11px] text-amber-700 bg-amber-50 rounded p-2">
            No matching brief — the fact-check guard can't verify numbers for this legend.
          </p>
        )}
      </Card>

      {/* Headline */}
      <Card className="space-y-4">
        <FormField label="Title" htmlFor="vf-title" required>
          <Input id="vf-title" value={form.title}
            onChange={(e) => p.patch({ title: e.target.value })} placeholder="Feature headline" />
        </FormField>
        <FormField label="Subtitle" htmlFor="vf-subtitle">
          <Textarea id="vf-subtitle" rows={2} value={form.subtitle}
            onChange={(e) => p.patch({ subtitle: e.target.value })} placeholder="Standfirst / deck" />
        </FormField>
        <FormField label="Pull quote" htmlFor="vf-pull"
          note="A short, striking line surfaced near the top of the feature.">
          <Textarea id="vf-pull" rows={2} value={form.pullQuote}
            onChange={(e) => p.patch({ pullQuote: e.target.value })} />
        </FormField>
      </Card>

      {/* Sections */}
      <Card>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-sm font-semibold text-gray-800">Sections</h3>
          <Button size="sm" variant="ghost" onClick={p.addSection}>+ Add section</Button>
        </div>
        <div className="space-y-4">
          {form.sections.length === 0 && (
            <p className="text-xs text-gray-400">No sections yet. Add at least one to publish.</p>
          )}
          {form.sections.map((s, i) => (
            <div key={i} className="rounded-lg border border-gray-200 p-3 space-y-2 bg-gray-50/50">
              <div className="flex items-center gap-2">
                <span className="text-[11px] font-semibold text-gray-400 w-10">#{i + 1}</span>
                <Input
                  value={s.heading}
                  onChange={(e) => p.setSection(i, 'heading', e.target.value)}
                  placeholder="Section heading"
                  className="flex-1"
                />
                <div className="flex items-center gap-1 shrink-0">
                  <Button size="sm" variant="ghost" onClick={() => p.moveSection(i, -1)}
                    disabled={i === 0} title="Move up">↑</Button>
                  <Button size="sm" variant="ghost" onClick={() => p.moveSection(i, 1)}
                    disabled={i === form.sections.length - 1} title="Move down">↓</Button>
                  <Button size="sm" variant="ghost" className="text-red-500"
                    onClick={() => p.removeSection(i)} title="Delete section">✕</Button>
                </div>
              </div>
              <Textarea
                value={s.body}
                onChange={(e) => p.setSection(i, 'body', e.target.value)}
                placeholder="Section body"
                rows={4}
              />
            </div>
          ))}
        </div>
      </Card>

      {/* By the Numbers (with fact-check) */}
      <Card>
        <div className="flex items-center justify-between mb-1">
          <h3 className="text-sm font-semibold text-gray-800">By the Numbers</h3>
          <Button size="sm" variant="ghost" onClick={() => p.addListItem('byTheNumbers')}>
            + Add stat
          </Button>
        </div>
        <p className="text-[11px] text-gray-400 mb-3">
          Each figure should trace to the brief. A ⚠ chip flags a number not found in any brief fact.
        </p>
        <div className="space-y-2">
          {form.byTheNumbers.length === 0 && (
            <p className="text-xs text-gray-400">No stats listed.</p>
          )}
          {form.byTheNumbers.map((item, i) => {
            const missing = untraceableNumbers(item, brief);
            return (
              <div key={i} className="space-y-1">
                <div className="flex items-start gap-2">
                  <Textarea
                    value={item}
                    onChange={(e) => p.setListItem('byTheNumbers', i, e.target.value)}
                    placeholder="e.g. 876-190 career record (.822)"
                    rows={2}
                    className="flex-1"
                  />
                  <Button size="sm" variant="ghost" className="text-red-500 shrink-0 mt-1"
                    onClick={() => p.removeListItem('byTheNumbers', i)} title="Delete">✕</Button>
                </div>
                {missing.length > 0 && (
                  <span className="inline-flex items-center gap-1 rounded bg-amber-100 text-amber-800 text-[11px] font-medium px-2 py-0.5">
                    ⚠ not in brief: {missing.join(', ')}
                  </span>
                )}
              </div>
            );
          })}
        </div>
      </Card>

      {/* Closing line */}
      <Card>
        <FormField label="Closing line" htmlFor="vf-closing"
          note="An italic editorial sign-off at the foot of the piece.">
          <Textarea id="vf-closing" rows={2} value={form.closingLine}
            onChange={(e) => p.patch({ closingLine: e.target.value })} />
        </FormField>
      </Card>

      {/* Sources */}
      <Card>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-sm font-semibold text-gray-800">
            Sources <span className="text-red-500">*</span>
          </h3>
          <Button size="sm" variant="ghost" onClick={() => p.addListItem('sources')}>
            + Add source
          </Button>
        </div>
        <div className="space-y-2">
          {form.sources.length === 0 && (
            <p className="text-xs text-gray-400">At least one source is required to publish.</p>
          )}
          {form.sources.map((src, i) => (
            <div key={i} className="flex items-center gap-2">
              <Input
                type="url"
                value={src}
                onChange={(e) => p.setListItem('sources', i, e.target.value)}
                placeholder="https://…"
                className="flex-1"
              />
              <Button size="sm" variant="ghost" className="text-red-500 shrink-0"
                onClick={() => p.removeListItem('sources', i)} title="Delete">✕</Button>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

function Prov({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-gray-400">{label}</dt>
      <dd className="text-gray-700 font-medium break-words">{value || '—'}</dd>
    </div>
  );
}

// ─── Right pane: live Editorial-reader preview ──────────────────────────────────

interface PreviewForm {
  title: string;
  subtitle: string;
  sections: VaultLegendSection[];
  byTheNumbers: string[];
  pullQuote: string;
  closingLine: string;
  sources: string[];
}

function LegendPreview({ legend, form }: { legend: VaultLegend; form: PreviewForm }) {
  return (
    <Card className="!p-0 overflow-hidden">
      <div className="bg-gray-50 border-b border-gray-200 px-4 py-2 text-[11px] font-semibold uppercase tracking-wide text-gray-400">
        Live preview · Editorial reader
      </div>
      <article className="px-6 py-7 max-w-prose">
        {/* Eyebrow */}
        <p className="text-[11px] font-semibold uppercase tracking-[0.15em] text-[#1E5AA8]">
          {sportLabel(legend.sport)} · {legend.era}
        </p>
        {/* Title */}
        <h1 className="mt-2 text-3xl font-extrabold leading-tight text-gray-900">
          {form.title || 'Untitled feature'}
        </h1>
        {/* Gold rule under the headline */}
        <div className="mt-3 h-1 w-20 rounded bg-[#C8B273]" />
        {form.subtitle && (
          <p className="mt-4 text-lg text-gray-600 leading-relaxed">{form.subtitle}</p>
        )}
        <p className="mt-3 text-xs text-gray-400">By {legend.subject}</p>

        {/* Pull quote */}
        {form.pullQuote && (
          <blockquote className="mt-7 border-l-4 border-[#C8B273] pl-4 text-xl font-semibold italic text-gray-800 leading-snug">
            “{form.pullQuote}”
          </blockquote>
        )}

        {/* Sections */}
        {form.sections.map((s, i) => (
          <section key={i} className="mt-7">
            {s.heading && (
              <h2 className="text-xl font-bold text-gray-900 mb-2">{s.heading}</h2>
            )}
            {s.body && (
              <p className={`text-gray-700 leading-[1.8] ${i === 0 ? 'text-[17px]' : 'text-base'}`}>
                {s.body}
              </p>
            )}
          </section>
        ))}

        {/* By the Numbers box */}
        {form.byTheNumbers.length > 0 && (
          <div className="mt-8 rounded-xl border border-[#1E3A5F]/15 bg-[#1E3A5F]/[0.03] p-5">
            <h3 className="text-xs font-bold uppercase tracking-[0.15em] text-[#1E3A5F] mb-3">
              By the Numbers
            </h3>
            <ul className="space-y-2">
              {form.byTheNumbers.map((n, i) => (
                <li key={i} className="flex gap-2 text-sm text-gray-700">
                  <span className="text-[#C8B273] font-bold leading-6">›</span>
                  <span>{n}</span>
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* Closing line */}
        {form.closingLine && (
          <p className="mt-7 text-base italic text-gray-500 leading-relaxed">{form.closingLine}</p>
        )}

        {/* Sources colophon + status badge — attribution must always show */}
        <footer className="mt-8 pt-5 border-t border-gray-200">
          <div className="flex items-center justify-between flex-wrap gap-2 mb-2">
            <h4 className="text-[11px] font-semibold uppercase tracking-wide text-gray-400">
              Sources &amp; attribution
            </h4>
            <Badge color={statusColor(legend.status)}>{legend.status}</Badge>
          </div>
          {form.sources.length > 0 ? (
            <ul className="space-y-1">
              {form.sources.map((src, i) => (
                <li key={i} className="text-xs text-[#1E5AA8] break-all">
                  <a href={src} target="_blank" rel="noopener noreferrer" className="hover:underline">
                    {src}
                  </a>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-xs text-red-500">No sources — required before publishing.</p>
          )}
          <p className="mt-3 text-[11px] text-gray-400">
            {legend.model} · confidence: {legend.confidence} · Independent fan feature, not
            affiliated with the University of Kentucky.
          </p>
        </footer>
      </article>
    </Card>
  );
}
