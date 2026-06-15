import React, { createContext, useContext, useEffect, useState } from 'react';
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut as firebaseSignOut,
  type User,
} from 'firebase/auth';
import { auth } from '../lib/firebase';
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

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (firebaseUser) => {
      setUser(firebaseUser);

      if (firebaseUser) {
        // 1. Try to read role from custom claims (set by Cloud Functions in production)
        const tokenResult = await firebaseUser.getIdTokenResult(/* forceRefresh */ true);
        const claimRole = tokenResult.claims['role'] as UserRole | undefined;

        if (claimRole) {
          setRole(claimRole);
        } else {
          // 2. Fallback: read role from users/{uid} doc (works for local dev / emulator)
          try {
            const userDoc = await getUserDoc(firebaseUser.uid);
            setRole(userDoc?.role ?? 'user');
          } catch {
            setRole('user');
          }
        }
      } else {
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
