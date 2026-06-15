// Typed Firestore data-access layer.
// All reads/writes go through these helpers to keep pages thin.

import {
  collection,
  doc,
  getDocs,
  getDoc,
  addDoc,
  updateDoc,
  query,
  orderBy,
  limit,
  where,
  getCountFromServer,
  serverTimestamp,
  type Timestamp,
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

// ─── Collections ─────────────────────────────────────────────────────────────

const gamesCol = () => collection(db, 'games').withConverter(gameConverter);
const predictionsCol = () => collection(db, 'predictions').withConverter(predictionConverter);
const postsCol = () => collection(db, 'community_posts').withConverter(communityPostConverter);
const newsCol = () => collection(db, 'news_cards').withConverter(newsCardConverter);
const syncRunsCol = () => collection(db, 'sync_runs').withConverter(syncRunConverter);

// ─── Games ───────────────────────────────────────────────────────────────────

export async function listGames(): Promise<Game[]> {
  const snap = await getDocs(query(gamesCol(), orderBy('startTime', 'desc')));
  return snap.docs.map((d) => d.data());
}

export async function getGame(id: string): Promise<Game | null> {
  const snap = await getDoc(doc(db, 'games', id).withConverter(gameConverter));
  return snap.exists() ? snap.data() : null;
}

export async function createGame(data: Omit<Game, 'id'>): Promise<string> {
  const ref = await addDoc(gamesCol(), { ...data, updatedAt: serverTimestamp() } as Omit<Game, 'id'>);
  return ref.id;
}

export async function updateGame(id: string, data: Partial<Omit<Game, 'id'>>): Promise<void> {
  await updateDoc(doc(db, 'games', id), { ...data, updatedAt: serverTimestamp() });
}

// ─── Predictions ─────────────────────────────────────────────────────────────

export async function listPredictions(): Promise<Prediction[]> {
  const snap = await getDocs(query(predictionsCol(), orderBy('closesAt', 'desc')));
  return snap.docs.map((d) => d.data());
}

export async function getPrediction(id: string): Promise<Prediction | null> {
  const snap = await getDoc(doc(db, 'predictions', id).withConverter(predictionConverter));
  return snap.exists() ? snap.data() : null;
}

export async function createPrediction(data: Omit<Prediction, 'id'>): Promise<string> {
  const ref = await addDoc(predictionsCol(), { ...data, createdAt: serverTimestamp() } as Omit<Prediction, 'id'>);
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
  const constraints = status
    ? [where('status', '==', status), orderBy('createdAt', 'desc')]
    : [orderBy('createdAt', 'desc')];
  const snap = await getDocs(query(postsCol(), ...constraints));
  return snap.docs.map((d) => d.data());
}

export async function updatePostStatus(id: string, status: PostStatus): Promise<void> {
  await updateDoc(doc(db, 'community_posts', id), { status, updatedAt: serverTimestamp() });
}

// ─── News Cards ───────────────────────────────────────────────────────────────

export async function listNewsCards(): Promise<NewsCard[]> {
  const snap = await getDocs(query(newsCol(), orderBy('publishedAt', 'desc')));
  return snap.docs.map((d) => d.data());
}

export async function createNewsCard(data: Omit<NewsCard, 'id'>): Promise<string> {
  const ref = await addDoc(newsCol(), { ...data, createdAt: serverTimestamp() } as Omit<NewsCard, 'id'>);
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

export async function getDashboardCounts(): Promise<{
  games: number;
  predictions: number;
  news: number;
  posts: number;
}> {
  const [games, predictions, news, posts] = await Promise.all([
    getCountFromServer(collection(db, 'games')),
    getCountFromServer(collection(db, 'predictions')),
    getCountFromServer(collection(db, 'news_cards')),
    getCountFromServer(collection(db, 'community_posts')),
  ]);
  return {
    games: games.data().count,
    predictions: predictions.data().count,
    news: news.data().count,
    posts: posts.data().count,
  };
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
