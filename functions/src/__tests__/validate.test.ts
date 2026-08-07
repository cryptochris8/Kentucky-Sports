import { describe, it, expect } from 'vitest';
// Import the REAL validators — a dropped NaN check or changed message in
// core/validate.ts must fail this suite, not a private re-implementation.
// (firebase-functions' HttpsError is just a class; importing it needs no env.)
import { requireString, requireEnum, requireNonNegativeNumber } from '../core/validate';

describe('requireString', () => {
  it('returns trimmed string for valid input', () => {
    expect(requireString('  hello  ', 'field')).toBe('hello');
  });
  it('throws for empty string', () => {
    expect(() => requireString('', 'field')).toThrow('non-empty string');
  });
  it('throws for whitespace-only string', () => {
    expect(() => requireString('   ', 'field')).toThrow('non-empty string');
  });
  it('throws for number', () => {
    expect(() => requireString(42, 'field')).toThrow('non-empty string');
  });
  it('throws for null', () => {
    expect(() => requireString(null, 'field')).toThrow('non-empty string');
  });
  it('throws for undefined', () => {
    expect(() => requireString(undefined, 'field')).toThrow('non-empty string');
  });
});

describe('requireEnum', () => {
  const allowed = ['winner', 'margin_bucket', 'exact_score'] as const;

  it('returns the value when valid', () => {
    expect(requireEnum('winner', 'type', allowed)).toBe('winner');
  });
  it('throws for invalid value', () => {
    expect(() => requireEnum('invalid', 'type', allowed)).toThrow('must be one of');
  });
  it('throws for empty string', () => {
    expect(() => requireEnum('', 'type', allowed)).toThrow('must be one of');
  });
  it('throws for undefined', () => {
    expect(() => requireEnum(undefined, 'type', allowed)).toThrow('must be one of');
  });
});

describe('requireNonNegativeNumber', () => {
  it('accepts 0', () => {
    expect(requireNonNegativeNumber(0, 'field')).toBe(0);
  });
  it('accepts positive numbers', () => {
    expect(requireNonNegativeNumber(42, 'field')).toBe(42);
    expect(requireNonNegativeNumber(0.5, 'field')).toBe(0.5);
  });
  it('throws for negative', () => {
    expect(() => requireNonNegativeNumber(-1, 'field')).toThrow('non-negative number');
  });
  it('throws for NaN', () => {
    expect(() => requireNonNegativeNumber(NaN, 'field')).toThrow('non-negative number');
  });
  it('throws for string', () => {
    expect(() => requireNonNegativeNumber('5', 'field')).toThrow('non-negative number');
  });
});
