import React, { createContext, useContext, useEffect, useRef, useState } from 'react';
import {
  onIdTokenChanged,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  type User,
} from 'firebase/auth';
import { auth, useEmulator } from '../lib/firebase';
import { getUserDoc } from '../data/firestore';
import type { UserRole } from '../data/types';

interface AuthContextValue {
  user: User | null;
  role: UserRole | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  /** Dev-only: create + sign in with the demo admin account */
  devSignIn: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [role, setRole] = useState<UserRole | null>(null);
  const [loading, setLoading] = useState(true);

  // Force-refresh the ID token once per signed-in uid so a freshly granted
  // custom claim lands without a manual reload; subsequent onIdTokenChanged
  // callbacks read the cached token (a forced refresh mints a new token, which
  // re-fires the listener — refreshing every time would loop).
  const refreshedForUid = useRef<string | null>(null);

  useEffect(() => {
    // onIdTokenChanged (not onAuthStateChanged) so hourly token refreshes —
    // which is when server-granted claims actually arrive — update the role.
    const unsub = onIdTokenChanged(auth, async (firebaseUser) => {
      setUser(firebaseUser);

      if (firebaseUser) {
        // 1. The custom claim is authoritative — firestore.rules derives every
        //    role from request.auth.token.role, so the UI must match it.
        const force = refreshedForUid.current !== firebaseUser.uid;
        refreshedForUid.current = firebaseUser.uid;
        const tokenResult = await firebaseUser.getIdTokenResult(force);
        const claimRole = tokenResult.claims['role'] as UserRole | undefined;

        if (claimRole) {
          setRole(claimRole);
        } else {
          // 2. Fallback: read role from users/{uid} doc. This is a local-dev
          //    convenience (the emulator seed has no claims) — it cannot grant
          //    real access, since the rules only honor the claim.
          try {
            const userDoc = await getUserDoc(firebaseUser.uid);
            setRole(userDoc?.role ?? 'user');
          } catch {
            setRole('user');
          }
        }
      } else {
        refreshedForUid.current = null;
        setRole(null);
      }

      setLoading(false);
    });
    return unsub;
  }, []);

  const signIn = async (email: string, password: string) => {
    await signInWithEmailAndPassword(auth, email, password);
  };

  const signOut = async () => {
    await firebaseSignOut(auth);
    setRole(null);
  };

  /**
   * Dev sign-in helper (emulator only).
   * Creates admin@bluegrassgameday.dev if it doesn't exist, then signs in.
   * Role comes from the seeded users/{uid} doc (demo_admin has role: "admin").
   * Note: custom claims are normally set by a Cloud Function — this shortcut
   * relies on the Firestore role fallback for local development.
   */
  const devSignIn = async () => {
    if (!useEmulator) {
      // Hard guard: this helper creates a known-credential account, which must
      // never happen against the production Auth tenant. LoginPage hides the
      // button outside emulator mode; this throw covers any other caller.
      throw new Error('Dev sign-in is emulator-only. Set VITE_USE_EMULATOR=true and run the Auth emulator.');
    }
    const email = 'admin@bluegrassgameday.dev';
    const password = 'devpassword123';
    try {
      await signInWithEmailAndPassword(auth, email, password);
    } catch (err: unknown) {
      const e = err as { code?: string };
      if (e.code === 'auth/user-not-found' || e.code === 'auth/invalid-credential') {
        await createUserWithEmailAndPassword(auth, email, password);
        // After creation the onAuthStateChanged fires and reads the role from Firestore.
      } else {
        throw err;
      }
    }
  };

  return (
    <AuthContext.Provider value={{ user, role, loading, signIn, signOut, devSignIn }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
