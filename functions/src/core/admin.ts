// Firebase Admin singleton — use getDb() everywhere to avoid multiple initializations
import * as admin from 'firebase-admin';

let _app: admin.app.App | undefined;

export function getApp(): admin.app.App {
  if (!_app) {
    _app = admin.initializeApp();
  }
  return _app;
}

export function getDb(): admin.firestore.Firestore {
  return getApp().firestore();
}

export function getAuth(): admin.auth.Auth {
  return getApp().auth();
}

export const FieldValue = admin.firestore.FieldValue;
export const Timestamp = admin.firestore.Timestamp;
