// Firebase Admin singleton — use getDb() everywhere to avoid multiple initializations
import * as admin from 'firebase-admin';

let _app: admin.app.App | undefined;
let _db: admin.firestore.Firestore | undefined;

export function getApp(): admin.app.App {
  if (!_app) {
    _app = admin.initializeApp();
  }
  return _app;
}

export function getDb(): admin.firestore.Firestore {
  if (!_db) {
    _db = getApp().firestore();
    // Provider payloads legitimately omit fields (e.g. scores on scheduled games);
    // drop undefined values instead of throwing on every write.
    _db.settings({ ignoreUndefinedProperties: true });
  }
  return _db;
}

export function getAuth(): admin.auth.Auth {
  return getApp().auth();
}

export const FieldValue = admin.firestore.FieldValue;
export const Timestamp = admin.firestore.Timestamp;
