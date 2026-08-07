// The single strict opt-in predicate for emulator mode: ONLY the literal
// string 'true' enables it. Shared by firebase.ts (emulator connection),
// LoginPage (dev sign-in visibility) and AuthContext (devSignIn guard) so no
// surface can drift back to an `!== 'false'` opt-out check.

export function isEmulatorFlagEnabled(value: string | undefined): boolean {
  return value === 'true';
}
