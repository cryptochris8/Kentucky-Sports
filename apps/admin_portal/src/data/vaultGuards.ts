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
// number does not appear in ANY brief fact. Non-blocking (a ⚠ chip in the UI),
// but untraceable numbers are surfaced prominently again at publish time.

/**
 * Pull comparable numeric tokens out of a string (digits only, e.g. "876", "1948").
 * Thousands separators are normalized first so "1,000" and "1000" compare equal.
 */
export function extractNumbers(text: string): string[] {
  const normalized = text.replace(/,(?=\d{3}(?!\d))/g, '');
  const matches = normalized.match(/\d+/g);
  return matches ? Array.from(new Set(matches)) : [];
}

/**
 * Returns the numbers in `entry` that are NOT found in any brief fact.
 * Empty array => fully traceable (or the entry has no numbers).
 * If there is no brief, we can't verify, so we return [] (no false alarms) —
 * checkPublishReady separately warns when a legend has stats but no brief.
 */
export function untraceableNumbers(entry: string, brief: LegendBrief | null): string[] {
  if (!brief) return [];
  const factBlob = brief.facts.join(' ');
  const factNums = new Set(extractNumbers(factBlob));
  return extractNumbers(entry).filter((n) => !factNums.has(n));
}

// ─── Pre-publish checklist (enforced) ──────────────────────────────────────────

// Predictions are free-to-play: betting language is a hard product violation and
// must never reach a published feature. Two tiers:
//
//   BLOCK — unambiguous gambling vocabulary, matched inflection-aware
//   (bet/bets/betting/bettor(s), wagered/wagering, …). A hit disables Publish.
//
//   WARN — standalone "odds" and "spread", which are legitimate sports prose
//   ("spread offense", "against all odds") but worth an editor's eye. Surfaced
//   as a warning, never blocking.
// "over/under" and "money line" tolerate spacing/hyphen/dash variants — the
// spaced forms are exactly as much a betting reference as the joined ones.
const BLOCK_RE =
  /\b(?:bet(?:s|ting|tors?)?|wager(?:s|ed|ing)?|parlays?|sportsbooks?|bookies?|money[ -]?lines?|point[ -]spreads?|over\s*[/–-]\s*under|vig)\b/gi;
const WARN_RE = /\b(?:odds|spreads?)\b/gi;

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

function uniqueMatches(text: string, re: RegExp): string[] {
  const matches = text.match(re) ?? [];
  return Array.from(new Set(matches.map((m) => m.toLowerCase())));
}

/** All publish-blocking betting terms found anywhere in the legend (unique, lowercased). */
export function findBettingTerms(l: Parameters<typeof legendText>[0]): string[] {
  return uniqueMatches(legendText(l), BLOCK_RE);
}

/**
 * Warn-tier terms (standalone "odds"/"spread") found in the legend. Blocked
 * matches are removed first so "point spread" doesn't double-report as "spread".
 */
export function findCautionTerms(l: Parameters<typeof legendText>[0]): string[] {
  return uniqueMatches(legendText(l).replace(BLOCK_RE, ' '), WARN_RE);
}

export interface PublishCheck {
  ok: boolean;
  failures: string[];
  /** Non-blocking editorial cautions — surfaced to the editor at publish time. */
  warnings: string[];
}

/**
 * Enforced pre-publish gate. Blocks publish unless title, ≥1 section and ≥1
 * source are present, AND no block-tier betting term appears anywhere in the
 * copy. Warn-tier terms and untraceable By-the-Numbers figures come back as
 * `warnings` (advisory — the editor decides, but must see them).
 */
export function checkPublishReady(
  l: Parameters<typeof legendText>[0] & { sources: string[] },
  brief?: LegendBrief | null,
): PublishCheck {
  const failures: string[] = [];
  const warnings: string[] = [];

  if (!l.title.trim()) failures.push('Title is required.');
  if (l.sections.filter((s) => s.heading.trim() || s.body.trim()).length === 0) {
    failures.push('At least one section is required.');
  }
  if (l.sources.filter((s) => s.trim()).length === 0) {
    failures.push('At least one source is required.');
  }

  const blocked = findBettingTerms(l);
  if (blocked.length > 0) {
    failures.push(`Betting language is not allowed (found "${blocked.join('", "')}").`);
  }

  const caution = findCautionTerms(l);
  if (caution.length > 0) {
    warnings.push(
      `Double-check the wording around "${caution.join('", "')}" — fine in sports prose, but never in a betting sense.`,
    );
  }

  // Fact-check: advisory, but every unverifiable figure is listed here so the
  // editor sees the full picture at publish time (hard rule: never present
  // invented numbers as sourced).
  if (brief) {
    const missing = Array.from(
      new Set(l.byTheNumbers.flatMap((entry) => untraceableNumbers(entry, brief))),
    );
    if (missing.length > 0) {
      warnings.push(
        `Numbers not found in the brief: ${missing.join(', ')} — verify each against the sources before publishing.`,
      );
    }
  } else if (l.byTheNumbers.length > 0) {
    warnings.push(
      'No brief on file — the By the Numbers figures could not be automatically verified. Check them by hand.',
    );
  }

  return { ok: failures.length === 0, failures, warnings };
}

export const STATUS_OPTIONS: VaultLegendStatus[] = ['draft', 'ready', 'published'];
