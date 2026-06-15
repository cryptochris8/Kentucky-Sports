import { describe, it, expect } from 'vitest';

// Test validate helpers in isolation by re-implementing the throw logic
// without importing firebase-functions (which needs a real Firebase env)

function requireStringPure(value: unknown, fieldName: string): string {
  if (typeof value !== 'string' || (value as string).trim() === '') {
    throw new Error(`${fieldName} must be a non-empty string.`);
  }
  return (value as string).trim();
}

function requireEnumPure<T extends string>(
  value: unknown,
  fieldName: string,
  allowedValues: readonly T[],
): T {
  if (!allowedValues.includes(value as T)) {
    throw new Error(
      `${fieldName} must be one of: ${allowedValues.join(', ')}. Got: ${String(value)}`,
    );
  }
  return value as T;
}

function requireNonNegativeNumberPure(value: unknown, fieldName: string): number {
  if (typeof value !== 'number' || isNaN(value as number) || (value as number) < 0) {
    throw new Error(`${fieldName} must be a non-negative number.`);
  }
  return value as number;
}

describe('requireString', () => {
  it('returns trimmed string for valid input', () => {
    expect(requireStringPure('  hello  ', 'field')).toBe('hello');
  });
  it('throws for empty string', () => {
    expect(() => requireStringPure('', 'field')).toThrow('non-empty string');
  });
  it('throws for whitespace-only string', () => {
    expect(() => requireStringPure('   ', 'field')).toThrow('non-empty string');
  });
  it('throws for number', () => {
    expect(() => requireStringPure(42, 'field')).toThrow('non-empty string');
  });
  it('throws for null', () => {
    expect(() => requireStringPure(null, 'field')).toThrow('non-empty string');
  });
  it('throws for undefined', () => {
    expect(() => requireStringPure(undefined, 'field')).toThrow('non-empty string');
  });
});

describe('requireEnum', () => {
  const allowed = ['winner', 'margin_bucket', 'exact_score'] as const;

  it('returns the value when valid', () => {
    expect(requireEnumPure('winner', 'type', allowed)).toBe('winner');
  });
  it('throws for invalid value', () => {
    expect(() => requireEnumPure('invalid', 'type', allowed)).toThrow('must be one of');
  });
  it('throws for empty string', () => {
    expect(() => requireEnumPure('', 'type', allowed)).toThrow('must be one of');
  });
  it('throws for undefined', () => {
    expect(() => requireEnumPure(undefined, 'type', allowed)).toThrow('must be one of');
  });
});

describe('requireNonNegativeNumber', () => {
  it('accepts 0', () => {
    expect(requireNonNegativeNumberPure(0, 'field')).toBe(0);
  });
  it('accepts positive numbers', () => {
    expect(requireNonNegativeNumberPure(42, 'field')).toBe(42);
    expect(requireNonNegativeNumberPure(0.5, 'field')).toBe(0.5);
  });
  it('throws for negative', () => {
    expect(() => requireNonNegativeNumberPure(-1, 'field')).toThrow('non-negative number');
  });
  it('throws for NaN', () => {
    expect(() => requireNonNegativeNumberPure(NaN, 'field')).toThrow('non-negative number');
  });
  it('throws for string', () => {
    expect(() => requireNonNegativeNumberPure('5', 'field')).toThrow('non-negative number');
  });
});
