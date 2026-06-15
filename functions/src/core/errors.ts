import { HttpsError } from 'firebase-functions/v2/https';

// Re-export for convenience; callers import from here instead of firebase-functions
export { HttpsError };

// HttpsError is a class — use ConstructorParameters to get the first arg type (error code)
export type ErrorCode = ConstructorParameters<typeof HttpsError>[0];

/** Throw a well-typed HTTPS error */
export function throwError(code: ErrorCode, message: string): never {
  throw new HttpsError(code, message);
}

/** Throw if condition is falsy */
export function assert(condition: unknown, code: ErrorCode, message: string): asserts condition {
  if (!condition) throwError(code, message);
}
