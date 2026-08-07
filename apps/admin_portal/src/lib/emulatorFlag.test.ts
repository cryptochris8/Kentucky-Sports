// The emulator gate must be strictly OPT-IN: only the literal string 'true'
// may enable dev-only surfaces (emulator connection, dev sign-in). An opt-out
// check (`!== 'false'`) once let the dev sign-in button render against the
// production Auth tenant on any build that never set the var — these tests pin
// the strict predicate so that cannot regress.

import { describe, it, expect } from 'vitest';
import { isEmulatorFlagEnabled } from './emulatorFlag';

describe('isEmulatorFlagEnabled', () => {
  it("enables ONLY on the literal string 'true'", () => {
    expect(isEmulatorFlagEnabled('true')).toBe(true);
  });

  it.each([
    ['undefined (fresh clone, var never set)', undefined],
    ["'false'", 'false'],
    ['empty string', ''],
    ["'TRUE' (case matters — no loose coercion)", 'TRUE'],
    ["'1'", '1'],
    ["'yes'", 'yes'],
    ["' true ' (no trimming)", ' true '],
  ])('stays disabled for %s', (_label, value) => {
    expect(isEmulatorFlagEnabled(value as string | undefined)).toBe(false);
  });
});
