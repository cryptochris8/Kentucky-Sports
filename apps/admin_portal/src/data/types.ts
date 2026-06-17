// Typed interfaces for Firestore collections used by the admin portal.
// These are local to this app; they mirror docs/04_FIREBASE_DATA_MODEL.md.

import type { Timestamp } from 'firebase/firestore';

export type Sport =
  | 'football'
  | 'mens_basketball'
  | 'womens_basketball'
  | 'baseball'
  | 'volleyball'
  | 'high_school';

export type GameStatus = 'scheduled' | 'live' | 'halftime' | 'final' | 'cancelled' | 'postponed';

export interface Game {
  id: string;
  season: number;
  sport: Sport;
  homeTeamId: string;
  awayTeamId: string;
  opponentName: string;
  opponentShort?: string;
  startTime: Timestamp | string;
  venue: string;
  city?: string;
  state?: string;
  status: GameStatus;
  homeScore: number | null;
  awayScore: number | null;
  broadcast?: string;
  source: string;
  sourceGameId?: string;
  featured: boolean;
  isHome?: boolean;
  rivalry?: string;
  result?: 'win' | 'loss' | 'tie';
  updatedAt?: Timestamp | string;
}

export type PredictionType =
  | 'winner'
  | 'margin_bucket'
  | 'threes_range'
  | 'total_points'
  | 'custom';

export type PredictionStatus = 'open' | 'closed' | 'scored' | 'cancelled';

export interface PredictionOption {
  id: string;
  label: string;
}

export interface Prediction {
  id: string;
  gameId: string;
  sport?: Sport;
  type: PredictionType;
  question: string;
  options: PredictionOption[];
  opensAt: Timestamp | string;
  closesAt: Timestamp | string;
  status: PredictionStatus;
  points: number;
  createdBy: string;
  correctOptionId?: string;
  createdAt?: Timestamp | string;
}

export type PostStatus = 'visible' | 'hidden' | 'pending' | 'removed';

export interface CommunityPost {
  id: string;
  userId: string;
  title?: string;
  body: string;
  sport?: Sport;
  gameId?: string;
  status: PostStatus;
  reactionCounts?: Record<string, number>;
  createdAt: Timestamp | string;
  updatedAt?: Timestamp | string;
}

export interface NewsCard {
  id: string;
  title: string;
  sourceName: string;
  url: string;
  summary: string;
  sport: Sport | string;
  tags?: string[];
  publishedAt: Timestamp | string;
  featured: boolean;
  createdBy: string;
  createdAt?: Timestamp | string;
}

// ─── The Vault — Legends (AI-drafted history features) ──────────────────────────

export type VaultLegendStatus = 'draft' | 'ready' | 'published';

export interface VaultLegendSection {
  heading: string;
  body: string;
}

export interface VaultLegend {
  id: string;
  type: 'legend';
  subject: string;
  sport: Sport | string;
  era: string;
  title: string;
  subtitle: string;
  sections: VaultLegendSection[];
  byTheNumbers: string[];
  pullQuote: string;
  closingLine: string;
  sources: string[];
  model: string;
  status: VaultLegendStatus;
  confidence: string;
  generatedAt: Timestamp | string;
  updatedAt?: Timestamp | string;
  publishedAt?: Timestamp | string;
}

/** Sourced fact-sheet that grounds a legend (read-only context for the fact-check). */
export interface LegendBrief {
  id: string;
  subject: string;
  sport: Sport | string;
  era: string;
  facts: string[];
  sources: string[];
}

export type SyncStatus = 'success' | 'error' | 'running' | 'partial';

export interface SyncRun {
  id: string;
  provider: string;
  status: SyncStatus;
  recordsProcessed?: number;
  recordsFailed?: number;
  errorMessage?: string;
  startedAt: Timestamp | string;
  completedAt?: Timestamp | string;
  triggeredBy?: string;
}

export interface AdminUser {
  uid: string;
  email: string | null;
  displayName: string | null;
  role: UserRole | null;
}

export type UserRole = 'admin' | 'editor' | 'moderator' | 'user' | 'sponsor_admin' | 'venue_admin';

export interface UserDoc {
  displayName: string;
  email: string;
  role: UserRole;
  xp?: number;
  level?: number;
  homeState?: string;
  favoriteCollegeTeams?: string[];
  favoriteSports?: string[];
}
