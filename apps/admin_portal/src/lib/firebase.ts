import { initializeApp } from 'firebase/app';
import { getAuth, connectAuthEmulator } from 'firebase/auth';
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY ?? 'demo-key',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN ?? 'bluegrass-gameday-dev.firebaseapp.com',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID ?? 'bluegrass-gameday-dev',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET ?? 'bluegrass-gameday-dev.appspot.com',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID ?? '000000000000',
  appId: import.meta.env.VITE_FIREBASE_APP_ID ?? '1:000000000000:web:0000000000000000000000',
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);

// Connect to Firebase emulators when VITE_USE_EMULATOR is not explicitly 'false'.
// Module-level flag prevents double-connection during Vite HMR.
const useEmulator = import.meta.env.VITE_USE_EMULATOR !== 'false';

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
