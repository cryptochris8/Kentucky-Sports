// Unit tests for the Vault pre-publish guards — the last line of defence for
// the free-to-play hard rule (no betting language) and the fact-check rule
// (numbers must trace to the sourced brief).

import { describe, it, expect } from 'vitest';
import {
  extractNumbers,
  untraceableNumbers,
  findBettingTerms,
  findCautionTerms,
  checkPublishReady,
} from './vaultGuards';
import type { LegendBrief } from './types';

/** Minimal publish-ready legend whose first section body we vary per case. */
function legendWith(body: string) {
  return {
    title: 'The Baron of the Bluegrass',
    subtitle: '',
    sections: [{ heading: 'Era', body }],
    byTheNumbers: [] as string[],
    pullQuote: '',
    closingLine: '',
    sources: ['https://example.com/source'],
  };
}

const BRIEF: LegendBrief = {
  id: 'brief_rupp',
  subject: 'Adolph Rupp',
  sport: 'mens_basketball',
  era: '1930-1972',
  facts: ['876-190 career record', 'Scored 1000 points across the era', 'Retired in 1972'],
  sources: ['https://example.com/source'],
};

// ─── Block tier: unambiguous betting language, inflection-aware ───────────────

describe('findBettingTerms (block tier)', () => {
  it.each([
    ['Vegas betting lines heavily favored Kentucky', 'betting'],
    ['Fans placed bets all week long', 'bets'],
    ['Wagering on the Final Four was rampant', 'wagering'],
    ['He wagered his season on one shot', 'wagered'],
    ['Parlays paid out for the faithful', 'parlays'],
    ['Sportsbooks lit up after the buzzer', 'sportsbooks'],
    ['The bettors never saw it coming', 'bettors'],
    ['A bookie in Louisville kept a ledger', 'bookie'],
    ['The moneyline told one story', 'moneyline'],
    ['The money line told the story', 'money line'],
    ['A money-line hunch, nothing more', 'money-line'],
    ['Kentucky covered the point spread', 'point spread'],
    ['The over/under was irrelevant that night', 'over/under'],
    ['The over / under that night was 145', 'over / under'],
    ['The over-under never mattered to Rupp', 'over-under'],
    ['The vig ate every profit', 'vig'],
  ])('flags %j', (text, term) => {
    expect(findBettingTerms(legendWith(text))).toContain(term);
  });

  it.each([
    'Rupp ran a spread offense long before it was fashionable',
    'Against all odds, Kentucky won the title',
    'The Wildcats rallied in the second half',
    'Kentucky beat Alabama by twelve',
    'They cut over and under the screens all night', // words between over/under — not the betting term
    'Money lined the pockets of every promoter', // "money lined" is not "money line"
  ])('does NOT flag %j', (text) => {
    expect(findBettingTerms(legendWith(text))).toEqual([]);
  });

  it('scans every text surface, not just section bodies', () => {
    const l = { ...legendWith('Clean body.'), pullQuote: 'The sportsbook never sleeps' };
    expect(findBettingTerms(l)).toContain('sportsbook');
  });
});

// ─── Warn tier: standalone "odds" / "spread" ──────────────────────────────────

describe('findCautionTerms (warn tier)', () => {
  it('warns on standalone "odds" and "spread"', () => {
    expect(findCautionTerms(legendWith('Against all odds, they won'))).toContain('odds');
    expect(findCautionTerms(legendWith('The spread offense changed everything'))).toContain('spread');
  });

  it('does not double-report "spread" when "point spread" already blocked', () => {
    const l = legendWith('Kentucky covered the point spread');
    expect(findBettingTerms(l)).toContain('point spread');
    expect(findCautionTerms(l)).toEqual([]);
  });

  it('stays quiet on plain prose', () => {
    expect(findCautionTerms(legendWith('The Wildcats rallied late'))).toEqual([]);
  });
});

// ─── checkPublishReady ─────────────────────────────────────────────────────────

describe('checkPublishReady', () => {
  it('passes a complete, clean legend', () => {
    const check = checkPublishReady(legendWith('A clean history of the program.'));
    expect(check.ok).toBe(true);
    expect(check.failures).toEqual([]);
  });

  it('blocks betting language', () => {
    const check = checkPublishReady(legendWith('Sportsbooks lit up after the buzzer'));
    expect(check.ok).toBe(false);
    expect(check.failures.join(' ')).toMatch(/betting language/i);
  });

  it('does NOT block warn-tier prose, but surfaces a warning', () => {
    const check = checkPublishReady(legendWith('Against all odds, the spread offense won out'));
    expect(check.ok).toBe(true);
    expect(check.warnings.join(' ')).toMatch(/odds/);
    expect(check.warnings.join(' ')).toMatch(/spread/);
  });

  it('requires title, at least one section, and at least one source', () => {
    const empty = {
      title: '', subtitle: '', sections: [], byTheNumbers: [],
      pullQuote: '', closingLine: '', sources: [],
    };
    const check = checkPublishReady(empty);
    expect(check.ok).toBe(false);
    expect(check.failures).toContain('Title is required.');
    expect(check.failures).toContain('At least one section is required.');
    expect(check.failures).toContain('At least one source is required.');
  });

  it('warns about numbers that do not trace to the brief', () => {
    const l = { ...legendWith('Body.'), byTheNumbers: ['876-190 record', '4 titles in 7 years'] };
    const check = checkPublishReady(l, BRIEF);
    expect(check.ok).toBe(true); // advisory, not blocking
    expect(check.warnings.join(' ')).toMatch(/4, 7|4/);
    expect(check.warnings.join(' ')).not.toMatch(/876/);
  });

  it('warns when stats exist but no brief is on file', () => {
    const l = { ...legendWith('Body.'), byTheNumbers: ['876-190 record'] };
    const check = checkPublishReady(l, null);
    expect(check.ok).toBe(true);
    expect(check.warnings.join(' ')).toMatch(/no brief/i);
  });
});

// ─── Fact-check number matching ───────────────────────────────────────────────

describe('extractNumbers / untraceableNumbers', () => {
  it('normalizes thousands separators so "1,000" matches "1000"', () => {
    expect(extractNumbers('He scored 1,000 points')).toContain('1000');
    expect(untraceableNumbers('1,000 points scored', BRIEF)).toEqual([]);
  });

  it('does not treat digits inside larger numbers as matches', () => {
    // Brief contains 1972 — a bare "48" must still be flagged.
    expect(untraceableNumbers('48 wins that season', BRIEF)).toEqual(['48']);
  });

  it('flags only the numbers missing from the brief', () => {
    expect(untraceableNumbers('876-190 record over 42 seasons', BRIEF)).toEqual(['42']);
  });

  it('returns [] when there is no brief (checkPublishReady warns separately)', () => {
    expect(untraceableNumbers('99 wins', null)).toEqual([]);
  });
});
