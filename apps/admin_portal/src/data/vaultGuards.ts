// Pure helpers for The Vault editor: sport labels, status badge colors, the
// fact-check guard (numbers must be traceable to the brief), and the enforced
// pre-publish checklist (house rules: traceable stats + NO betting language).

import type { VaultLegend, VaultLegendStatus, LegendBrief } from './types';

// ─── Display ─────────────────────────────────────────────────────────────────

export function sportLabel(sport: string): string {
  switch (sport) {
    case 'mens_basketball': return "Men's Basketball";
    case 'womens_basketball': return "Women's Basketball";
    case 'football': return 'Football';
    case 'baseball': return 'Baseball';
    case 'volleyball': return 'Volleyball';
    case 'high_school': return 'High School';
    default: return sport.replace(/_/g, ' ');
  }
}

export function statusColor(s: VaultLegendStatus): 'gray' | 'yellow' | 'green' {
  switch (s) {
    case 'draft': return 'gray';
    case 'ready': return 'yellow';
    case 'published': return 'green';
    default: return 'gray';
  }
}

// ─── Fact-check guard ──────────────────────────────────────────────────────────
// House rule: every published stat must be traceable to a sourced brief fact.
// We extract the numeric tokens from a "By the Numbers" entry and flag it when a
// number does not appear in ANY brief fact. Non-blocking (a ⚠ chip in the UI).

/** Pull comparable numeric tokens out of a string (digits only, e.g. "876", "1948"). */
export function extractNumbers(text: string): string[] {
  const matches = text.match(/\d+/g);
  return matches ? Array.from(new Set(matches)) : [];
}

/**
 * Returns the numbers in `entry` that are NOT found in any brief fact.
 * Empty array => fully traceable (or the entry has no numbers).
 * If there is no brief, we can't verify, so we return [] (no false alarms).
 */
export function untraceableNumbers(entry: string, brief: LegendBrief | null): string[] {
  if (!brief) return [];
  const factBlob = brief.facts.join(' ');
  const factNums = new Set(extractNumbers(factBlob));
  return extractNumbers(entry).filter((n) => !factNums.has(n));
}

// ─── Pre-publish checklist (enforced) ──────────────────────────────────────────

// Predictions are free-to-play: betting language is a hard product violation and
// must never reach a published feature.
const BETTING_TERMS = ['bet', 'wager', 'odds', 'spread', 'parlay', 'over/under', 'sportsbook'];
const BETTING_RE = new RegExp(
  `\\b(?:${BETTING_TERMS.map((t) => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace('/', '\\/')).join('|')})\\b`,
  'i',
);

/** Every text surface of the legend, concatenated, for term scanning. */
function legendText(l: Pick<VaultLegend,
  'title' | 'subtitle' | 'sections' | 'byTheNumbers' | 'pullQuote' | 'closingLine'>): string {
  return [
    l.title,
    l.subtitle,
    l.pullQuote,
    l.closingLine,
    ...l.sections.flatMap((s) => [s.heading, s.body]),
    ...l.byTheNumbers,
  ].join('\n');
}

/** Returns the first betting term found anywhere in the legend, or null. */
export function findBettingTerm(l: Parameters<typeof legendText>[0]): string | null {
  const m = legendText(l).match(BETTING_RE);
  return m ? m[0].toLowerCase() : null;
}

export interface PublishCheck {
  ok: boolean;
  failures: string[];
}

/**
 * Enforced pre-publish gate. Blocks publish unless title, ≥1 section and ≥1
 * source are present, AND no betting term appears anywhere in the copy.
 */
export function checkPublishReady(l: Parameters<typeof legendText>[0] & {
  sources: string[];
}): PublishCheck {
  const failures: string[] = [];
  if (!l.title.trim()) failures.push('Title is required.');
  if (l.sections.filter((s) => s.heading.trim() || s.body.trim()).length === 0) {
    failures.push('At least one section is required.');
  }
  if (l.sources.filter((s) => s.trim()).length === 0) {
    failures.push('At least one source is required.');
  }
  const term = findBettingTerm(l);
  if (term) failures.push(`Betting language is not allowed (found "${term}").`);
  return { ok: failures.length === 0, failures };
}

export const STATUS_OPTIONS: VaultLegendStatus[] = ['draft', 'ready', 'published'];
