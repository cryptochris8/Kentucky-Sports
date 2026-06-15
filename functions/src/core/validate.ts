import { throwError } from './errors';

/** Assert a string is non-empty */
export function requireString(value: unknown, fieldName: string): string {
  if (typeof value !== 'string' || value.trim() === '') {
    throwError('invalid-argument', `${fieldName} must be a non-empty string.`);
  }
  // throwError above is `never`; cast is safe for the surviving branch
  return (value as string).trim();
}

/** Assert a value is a non-negative number */
export function requireNonNegativeNumber(value: unknown, fieldName: string): number {
  if (typeof value !== 'number' || isNaN(value) || value < 0) {
    throwError('invalid-argument', `${fieldName} must be a non-negative number.`);
  }
  return value as number;
}

/** Assert a value is a boolean */
export function requireBoolean(value: unknown, fieldName: string): boolean {
  if (typeof value !== 'boolean') {
    throwError('invalid-argument', `${fieldName} must be a boolean.`);
  }
  return value as boolean;
}

/** Assert a value is one of the allowed string values */
export function requireEnum<T extends string>(
  value: unknown,
  fieldName: string,
  allowedValues: readonly T[],
): T {
  if (!allowedValues.includes(value as T)) {
    throwError(
      'invalid-argument',
      `${fieldName} must be one of: ${allowedValues.join(', ')}. Got: ${String(value)}`,
    );
  }
  return value as T;
}

/** Assert an object key is present and not null */
export function requirePresent<T>(value: T | null | undefined, fieldName: string): T {
  if (value === null || value === undefined) {
    throwError('invalid-argument', `${fieldName} is required.`);
  }
  return value as T;
}
