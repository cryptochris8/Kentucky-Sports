import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore';
import { isEmulatorFlagEnabled } from './emulatorFlag';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY ?? 'demo-key',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN ?? 'bluegrass-gameday-dev.firebaseapp.com',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID ?? 'bluegrass-gameday-dev',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET ?? 'bluegrass-gameday-dev.appspot.com',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID ?? '000000000000',
  appId: import.meta.env.VITE_FIREBASE_APP_ID ?? '1:000000000000:web:0000000000000000000000',
};

const app = initializeApp(firebaseConfig);

// TODO(pre-launch): wire initializeAppCheck + ReCaptchaEnterpriseProvider here
// as part of the first real deploy (see docs/13_TESTING_DEPLOYMENT.md). App
// Check is the documented compensating control for the public web config.
export const auth = getAuth(app);
export const db = getFirestore(app);

// Emulators are strictly OPT-IN: connect only when VITE_USE_EMULATOR === 'true'
// (.env.development sets it; production builds without the flag talk to the real
// project instead of dead localhost ports). Module-level flag prevents
// double-connection during Vite HMR. Exported so every dev-only surface
// (LoginPage's dev sign-in block, AuthContext's devSignIn) gates on the SAME
// strict opt-in predicate instead of re-deriving its own.
export const useEmulator = isEmulatorFlagEnabled(import.meta.env.VITE_USE_EMULATOR);

declare global {
  interface Window {
    __bgd_emulators_connected?: boolean;
  }
}

if (useEmulator && !window.__bgd_emulators_connected) {
  connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true });
  connectFirestoreEmulator(db, 'localhost', 8080);
  window.__bgd_emulators_connected = true;
}

export default app;
