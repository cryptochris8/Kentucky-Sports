// Typed Firestore data-access layer.
// All reads/writes go through these helpers to keep pages thin.
// Datetime-local form values are converted to Firestore Timestamps HERE, at the
// boundary — pages never write raw "2026-09-05T19:00" strings into Timestamp
// fields (strings mis-sort against Timestamps and carry no timezone).

import {
  collection,
  doc,
  getDocs,
  getDoc,
  addDoc,
  updateDoc,
  writeBatch,
  query,
  orderBy,
  limit,
  where,
  getCountFromServer,
  serverTimestamp,
  Timestamp,
  type Query,
  type DocumentData,
} from 'firebase/firestore';
import { db } from '../lib/firebase';
import {
  gameConverter,
  predictionConverter,
  communityPostConverter,
  newsCardConverter,
  syncRunConverter,
} from './converters';
import type { Game, Prediction, CommunityPost, NewsCard, SyncRun, PostStatus, UserDoc } from './types';

// Unbounded list queries pull every document ever written into the browser.
// Cap them until cursor paging is actually needed.
const LIST_LIMIT = 100;

// ─── Timestamp helpers ───────────────────────────────────────────────────────

/**
 * Convert a `<input type="datetime-local">` value to a Firestore Timestamp.
 * The browser interprets the value in the admin's LOCAL timezone — pages show
 * a timezone hint next to these inputs.
 */
function localInputToTimestamp(v: string): Timestamp {
  return Timestamp.fromDate(new Date(v));
}

/** Coerce a field that may arrive as a datetime-local string into a Timestamp. */
function coerceTimestamp(v: Timestamp | string): Timestamp {
  return typeof v === 'string' ? localInputToTimestamp(v) : v;
}

/** Convert a stored Timestamp (or legacy ISO string) back into a datetime-local value. */
export function timestampToLocalInput(ts: Timestamp | string | undefined): string {
  if (!ts) return '';
  const d = typeof ts === 'string' ? new Date(ts) : ts.toDate();
  if (Number.isNaN(d.getTime())) return '';
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

// ─── Collections ─────────────────────────────────────────────────────────────

const gamesCol = () => collection(db, 'games').withConverter(gameConverter);
const predictionsCol = () => collection(db, 'predictions').withConverter(predictionConverter);
const postsCol = () => collection(db, 'community_posts').withConverter(communityPostConverter);
const newsCol = () => collection(db, 'news_cards').withConverter(newsCardConverter);
const syncRunsCol = () => collection(db, 'sync_runs').withConverter(syncRunConverter);

// ─── Games ───────────────────────────────────────────────────────────────────

export async function listGames(): Promise<Game[]> {
  const snap = await getDocs(query(gamesCol(), orderBy('startTime', 'desc'), limit(LIST_LIMIT)));
  return snap.docs.map((d) => d.data());
}

export async function getGame(id: string): Promise<Game | null> {
  const snap = await getDoc(doc(db, 'games', id).withConverter(gameConverter));
  return snap.exists() ? snap.data() : null;
}

export async function createGame(data: Omit<Game, 'id'>): Promise<string> {
  const ref = await addDoc(gamesCol(), {
    ...data,
    startTime: coerceTimestamp(data.startTime),
    updatedAt: serverTimestamp(),
  } as Omit<Game, 'id'>);
  return ref.id;
}

export async function updateGame(id: string, data: Partial<Omit<Game, 'id'>>): Promise<void> {
  const patch: Record<string, unknown> = { ...data, updatedAt: serverTimestamp() };
  if (data.startTime !== undefined) patch.startTime = coerceTimestamp(data.startTime);
  await updateDoc(doc(db, 'games', id), patch);
}

// ─── Predictions ─────────────────────────────────────────────────────────────

export async function listPredictions(): Promise<Prediction[]> {
  const snap = await getDocs(query(predictionsCol(), orderBy('closesAt', 'desc'), limit(LIST_LIMIT)));
  return snap.docs.map((d) => d.data());
}

export async function getPrediction(id: string): Promise<Prediction | null> {
  const snap = await getDoc(doc(db, 'predictions', id).withConverter(predictionConverter));
  return snap.exists() ? snap.data() : null;
}

export async function createPrediction(data: Omit<Prediction, 'id'>): Promise<string> {
  const ref = await addDoc(predictionsCol(), {
    ...data,
    opensAt: coerceTimestamp(data.opensAt),
    closesAt: coerceTimestamp(data.closesAt),
    createdAt: serverTimestamp(),
  } as Omit<Prediction, 'id'>);
  return ref.id;
}

export async function closePrediction(id: string): Promise<void> {
  await updateDoc(doc(db, 'predictions', id), { status: 'closed' });
}

export async function getPredictionEntryCount(predictionId: string): Promise<number> {
  const col = collection(db, 'prediction_entries');
  const q = query(col, where('predictionId', '==', predictionId));
  const snap = await getCountFromServer(q);
  return snap.data().count;
}

// ─── Community Posts ──────────────────────────────────────────────────────────

export async function listPosts(status?: PostStatus): Promise<CommunityPost[]> {
  // The filtered branch deliberately avoids `where + orderBy` (that shape needs
  // a (status, createdAt) composite index which firestore.indexes.json does not
  // declare — the emulator would accept it, production would throw
  // FAILED_PRECONDITION). Equality-only filters run on automatic single-field
  // indexes; we sort the capped result client-side instead.
  if (!status) {
    const snap = await getDocs(query(postsCol(), orderBy('createdAt', 'desc'), limit(LIST_LIMIT)));
    return snap.docs.map((d) => d.data());
  }
  const snap = await getDocs(query(postsCol(), where('status', '==', status), limit(LIST_LIMIT)));
  const millis = (ts: Timestamp | string | undefined): number => {
    if (!ts) return 0;
    return typeof ts === 'string' ? new Date(ts).getTime() : ts.toMillis();
  };
  return snap.docs.map((d) => d.data()).sort((a, b) => millis(b.createdAt) - millis(a.createdAt));
}

/**
 * Moderate a post: flip its status AND write the moderation_actions audit doc
 * in the same atomic batch. An unauditable moderation path is a policy hole —
 * moderation is the guardrail for community content (docs/04, firestore.rules).
 */
export async function moderatePost(
  id: string,
  status: PostStatus,
  moderatorUid: string,
  reason?: string,
): Promise<void> {
  const batch = writeBatch(db);
  batch.update(doc(db, 'community_posts', id), { status, updatedAt: serverTimestamp() });
  batch.set(doc(collection(db, 'moderation_actions')), {
    postId: id,
    action: status,
    moderatorUid,
    ...(reason ? { reason } : {}),
    createdAt: serverTimestamp(),
  });
  await batch.commit();
}

// ─── News Cards ───────────────────────────────────────────────────────────────

export async function listNewsCards(): Promise<NewsCard[]> {
  const snap = await getDocs(query(newsCol(), orderBy('publishedAt', 'desc'), limit(LIST_LIMIT)));
  return snap.docs.map((d) => d.data());
}

export async function createNewsCard(
  data: Omit<NewsCard, 'id' | 'publishedAt' | 'createdAt'>,
): Promise<string> {
  const ref = await addDoc(newsCol(), {
    ...data,
    publishedAt: serverTimestamp(),
    createdAt: serverTimestamp(),
  } as unknown as Omit<NewsCard, 'id'>);
  return ref.id;
}

export async function updateNewsCard(id: string, data: Partial<Omit<NewsCard, 'id'>>): Promise<void> {
  await updateDoc(doc(db, 'news_cards', id), data);
}

// ─── Sync Runs ────────────────────────────────────────────────────────────────

export async function listSyncRuns(limitN = 20): Promise<SyncRun[]> {
  const snap = await getDocs(query(syncRunsCol(), orderBy('startedAt', 'desc'), limit(limitN)));
  return snap.docs.map((d) => d.data());
}

// ─── Dashboard Counts ─────────────────────────────────────────────────────────

export interface DashboardCounts {
  games: number | null;
  predictions: number | null;
  news: number | null;
  posts: number | null;
}

/**
 * Per-collection counts with per-card error tolerance: a count the caller's
 * role cannot read comes back `null` instead of rejecting the whole dashboard.
 * The posts count filters to `visible` so it is provable under firestore.rules
 * for non-moderator roles.
 */
export async function getDashboardCounts(): Promise<DashboardCounts> {
  const count = async (q: Query<DocumentData, DocumentData>): Promise<number | null> => {
    try {
      return (await getCountFromServer(q)).data().count;
    } catch {
      return null;
    }
  };
  const [games, predictions, news, posts] = await Promise.all([
    count(collection(db, 'games')),
    count(collection(db, 'predictions')),
    count(collection(db, 'news_cards')),
    count(query(collection(db, 'community_posts'), where('status', '==', 'visible'))),
  ]);
  return { games, predictions, news, posts };
}

// ─── Users (role fallback) ────────────────────────────────────────────────────

export async function getUserDoc(uid: string): Promise<UserDoc | null> {
  const snap = await getDoc(doc(db, 'users', uid));
  return snap.exists() ? (snap.data() as UserDoc) : null;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

export function toDisplayDate(ts: Timestamp | string | undefined): string {
  if (!ts) return '—';
  if (typeof ts === 'string') return new Date(ts).toLocaleString();
  return ts.toDate().toLocaleString();
}
