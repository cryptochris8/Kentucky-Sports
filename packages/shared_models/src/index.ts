// Bluegrass Gameday — Canonical Firestore types
// Used by: Firebase Cloud Functions (functions/), Admin Portal (apps/admin_portal/)
// Consumed via tsconfig path alias @bluegrass/shared-models

// ───────────────────────────────────────────────
// Enums
// ───────────────────────────────────────────────

export type Sport =
  | 'football'
  | 'mens_basketball'
  | 'womens_basketball'
  | 'baseball'
  | 'volleyball'
  | 'high_school';

export type Role =
  | 'user'
  | 'moderator'
  | 'editor'
  | 'admin'
  | 'sponsor_admin'
  | 'venue_admin';

export type GameStatus =
  | 'scheduled'
  | 'live'
  | 'final'
  | 'postponed'
  | 'canceled';

export type PredictionStatus = 'open' | 'closed' | 'scored' | 'cancelled';

export type PredictionType =
  | 'winner'
  | 'margin_bucket'
  | 'exact_score'
  | 'threes_range'
  | 'leading_scorer'
  | 'stat_over_under'
  | 'upset_pick';

export type BadgeCategory = 'prediction' | 'stats' | 'gameday' | 'high_school';
export type BadgeRarity = 'common' | 'rare' | 'epic' | 'legendary';

export type BadgeCriteriaType =
  | 'prediction_count'
  | 'prediction_streak'
  | 'rivalry_correct'
  | 'upset_correct'
  | 'exact_score'
  | 'open_stats_lab'
  | 'view_four_factors'
  | 'view_advanced_football'
  | 'view_matchup'
  | 'gameday_open'
  | 'gameday_open_bball'
  | 'follow_high_school'
  | 'view_hs_scoreboard';

export type XpEvent =
  | 'daily_open'
  | 'vote_poll'
  | 'submit_prediction'
  | 'correct_prediction'
  | 'exact_score_bonus'
  | 'comment_approved'
  | 'game_checkin'
  | 'watch_party_checkin'
  | 'read_stat_explainer'
  | 'follow_team';

export type PostStatus = 'pending' | 'visible' | 'hidden' | 'removed';

export type InterestLevel = 'mentioned' | 'visited' | 'offered' | 'high' | 'committed';
export type CommitStatus = 'uncommitted' | 'committed' | 'signed' | 'enrolled';
export type DataSource = 'cfbd' | 'cbbd' | 'khsaa' | 'manual' | 'seed_demo';

// ───────────────────────────────────────────────
// Firestore Timestamp alias (firebase-admin type)
// ───────────────────────────────────────────────
// Using string to stay import-free in shared-models;
// functions/ layer will cast to Firestore Timestamp.
export type FirestoreTimestamp = string | { seconds: number; nanoseconds: number };

// ───────────────────────────────────────────────
// Users
// ───────────────────────────────────────────────

export interface PredictionRecord {
  total: number;
  correct: number;
  streak: number;
}

export interface User {
  id?: string;
  displayName: string;
  photoUrl: string | null;
  email: string;
  favoriteCollegeTeams: string[];
  favoriteSports: Sport[];
  favoriteHighSchools: string[];
  homeState: string;
  role: Role;
  xp: number;
  level: number;
  predictionRecord: PredictionRecord;
  createdAt: FirestoreTimestamp;
  updatedAt: FirestoreTimestamp;
}

// ───────────────────────────────────────────────
// Teams
// ───────────────────────────────────────────────

export interface Team {
  id?: string;
  school: string;
  teamName: string;
  nickname: string;
  sport: Sport;
  division: string;
  conference: string;
  primaryColor: string;
  secondaryColor?: string;
  isOfficialLicensed: boolean;
  sourceIds: Record<string, string>;
  active: boolean;
}

// ───────────────────────────────────────────────
// Seasons
// ───────────────────────────────────────────────

export type SeasonStatus = 'preseason' | 'regular_season' | 'postseason' | 'completed';

export interface Season {
  id?: string;
  year: number;
  sport: Sport;
  status: SeasonStatus;
  startsAt?: FirestoreTimestamp;
  endsAt?: FirestoreTimestamp;
}

// ───────────────────────────────────────────────
// Games
// ───────────────────────────────────────────────

export interface Game {
  id?: string;
  season: number;
  sport: Sport;
  homeTeamId: string;
  awayTeamId: string;
  opponentName: string;
  opponentShort?: string;
  startTime: FirestoreTimestamp;
  venue?: string;
  city?: string;
  state?: string;
  status: GameStatus;
  homeScore: number | null;
  awayScore: number | null;
  broadcast?: string;
  source: DataSource | string;
  sourceGameId?: string;
  featured: boolean;
  isHome?: boolean;
  result?: 'win' | 'loss' | 'tie';
  rivalry?: string;
  updatedAt?: FirestoreTimestamp;
}

// ───────────────────────────────────────────────
// Game Summaries (Gameday HQ read model)
// ───────────────────────────────────────────────

export interface TeamComparison {
  [teamKey: string]: Record<string, number>;
}

export interface WinProbability {
  kentucky: number;
  opponent: number;
  source: string;
}

export interface ConcernMeter {
  level: 'low' | 'medium' | 'high';
  note: string;
}

export interface PlayerToWatch {
  playerId: string;
  reason: string;
}

export interface GameSummary {
  id?: string;
  gameId: string;
  headline: string;
  matchupVerdict?: 'kentucky_edge' | 'toss_up' | 'opponent_edge';
  matchupScore?: number;
  fanConfidence: number;
  winProbability: WinProbability;
  teamComparison: TeamComparison;
  keysToGame: string[];
  playerToWatch?: PlayerToWatch;
  concernMeter?: ConcernMeter;
  statStory?: string;
  source: string;
  confidence: string;
  updatedAt: FirestoreTimestamp;
}

// ───────────────────────────────────────────────
// Team Stats
// ───────────────────────────────────────────────

export interface TeamStat {
  id?: string;
  teamId: string;
  season: number;
  sport: Sport;
  scope: 'season' | 'game';
  gameId?: string;
  stats: Record<string, number | string | null>;
  rankings?: Record<string, number>;
  source: string;
  updatedAt: FirestoreTimestamp;
  confidence: string;
}

// ───────────────────────────────────────────────
// Player Profiles
// ───────────────────────────────────────────────

export interface PlayerProfile {
  id?: string;
  name: string;
  teamId: string;
  sport: Sport;
  position: string;
  classYear: string;
  height?: string;
  weight?: string;
  hometown?: string;
  jersey?: number;
  sourceIds?: Record<string, string>;
  active: boolean;
  // Provenance trio (hard rule 6). Optional here because a bio is not itself a
  // stat document, but every synced profile SHOULD carry all three — the CFBD/
  // CBBD sync stamps source, and freshness/confidence let the UI show how
  // current the roster info is.
  source?: string;
  updatedAt?: FirestoreTimestamp;
  /** e.g. "official" (provider roster), "manual", "demo" */
  confidence?: string;
}

// ───────────────────────────────────────────────
// Player Stats
// ───────────────────────────────────────────────

export interface PlayerStat {
  id?: string;
  playerId: string;
  teamId: string;
  season: number;
  sport: Sport;
  scope: 'season' | 'game';
  gameId?: string;
  stats: Record<string, number | string | null>;
  source: string;
  updatedAt: FirestoreTimestamp;
  confidence: string;
}

// ───────────────────────────────────────────────
// Predictions
// ───────────────────────────────────────────────

export interface PredictionOption {
  id: string;
  label: string;
}

export interface Prediction {
  id?: string;
  gameId: string;
  sport?: Sport;
  type: PredictionType;
  question: string;
  options: PredictionOption[];
  opensAt: FirestoreTimestamp;
  closesAt: FirestoreTimestamp;
  status: PredictionStatus;
  points: number;
  correctOptionId?: string | null;
  createdBy: string;
  createdAt?: FirestoreTimestamp;
}

// ───────────────────────────────────────────────
// Prediction Entries
// ───────────────────────────────────────────────

export interface PredictionEntry {
  id?: string;
  predictionId: string;
  gameId: string;
  userId: string;
  selectedOptionId: string;
  numericValue: number | null;
  locked: boolean;
  isCorrect: boolean | null;
  pointsAwarded: number;
  createdAt: FirestoreTimestamp;
  scoredAt?: FirestoreTimestamp;
}

// ───────────────────────────────────────────────
// Badges
// ───────────────────────────────────────────────

export interface BadgeCriteria {
  type: BadgeCriteriaType;
  threshold: number;
}

export interface Badge {
  id?: string;
  name: string;
  description: string;
  category: BadgeCategory;
  rarity: BadgeRarity;
  assetPath?: string;
  criteria: BadgeCriteria;
}

export interface UserBadge {
  id?: string;
  userId: string;
  badgeId: string;
  earnedAt: FirestoreTimestamp;
  metadata?: Record<string, unknown>;
}

// ───────────────────────────────────────────────
// Polls
// ───────────────────────────────────────────────

export interface PollOption {
  id: string;
  label: string;
  votes: number;
}

export interface Poll {
  id?: string;
  question: string;
  options: PollOption[];
  sport: Sport;
  status: 'open' | 'closed';
  closesAt: FirestoreTimestamp;
  createdBy?: string;
}

// ───────────────────────────────────────────────
// News Cards
// ───────────────────────────────────────────────

export interface NewsCard {
  id?: string;
  title: string;
  sourceName: string;
  url: string;
  summary: string;
  sport: Sport | 'high_school';
  tags: string[];
  publishedAt: FirestoreTimestamp;
  featured: boolean;
  createdBy: string;
}

// ───────────────────────────────────────────────
// Community Posts
// ───────────────────────────────────────────────

export interface CommunityPost {
  id?: string;
  userId: string;
  title: string;
  body: string;
  sport: Sport;
  gameId?: string;
  status: PostStatus;
  reactionCounts: Record<string, number>;
  createdAt: FirestoreTimestamp;
  updatedAt: FirestoreTimestamp;
}

// ───────────────────────────────────────────────
// High Schools
// ───────────────────────────────────────────────

export interface HighSchool {
  id?: string;
  name: string;
  city: string;
  state: string;
  khsaaId?: string | null;
  sports: string[];
  officialUrl: string | null;
  sourceUrls: Record<string, string | null>;
  verified: boolean;
  createdAt?: FirestoreTimestamp;
}

/**
 * High-school game (score-carrying — hard rule 6 applies in full).
 * Every row must say where it came from, when, and how trustworthy it is;
 * importers/admin CSV loaders must stamp all three.
 */
export interface HighSchoolGame {
  id?: string;
  schoolId: string;
  sport: string;
  season: number;
  opponent: string;
  startTime: FirestoreTimestamp;
  status: GameStatus;
  schoolScore: number | null;
  opponentScore: number | null;
  source: string;
  sourceUrl: string | null;
  updatedAt: FirestoreTimestamp;
  /** e.g. "official" (KHSAA), "manual" (admin-entered), "demo" */
  confidence: string;
}

// ───────────────────────────────────────────────
// Recruits
// ───────────────────────────────────────────────

export interface Recruit {
  id?: string;
  name: string;
  sport: Sport;
  position: string;
  classYear: number;
  highSchoolId: string | null;
  homeTown: string;
  state: string;
  stars: number;
  rating: number;
  interestLevel: InterestLevel;
  commitStatus: CommitStatus;
  committedTo: string | null;
  confidence?: string;
  sourceLinks: string[];
  lastUpdatedAt: FirestoreTimestamp;
}

// ───────────────────────────────────────────────
// App Config
// ───────────────────────────────────────────────

export interface FeatureFlags {
  highSchool: boolean;
  communityPosts: boolean;
  predictions: boolean;
  premiumStats: boolean;
  venues: boolean;
}

export interface AppConfig {
  minSupportedVersion: string;
  maintenanceMode: boolean;
  independentFanDisclaimer?: string;
  featureFlags: FeatureFlags;
}

// ───────────────────────────────────────────────
// Sync Runs
// ───────────────────────────────────────────────

// 'skipped' = the run intentionally did no work (no API key configured, or data
// already fresh). Distinct from 'success' so freshness checks and the admin
// Sync Health page never mistake a no-op for a real sync.
export type SyncRunStatus = 'running' | 'success' | 'error' | 'skipped';
export type SyncProvider = 'cfbd' | 'cbbd' | 'khsaa' | 'manual';

export interface SyncRun {
  id?: string;
  provider: SyncProvider;
  sport: Sport;
  startedAt: FirestoreTimestamp;
  completedAt?: FirestoreTimestamp | null;
  status: SyncRunStatus;
  recordsProcessed: number;
  error: string | null;
}

// ───────────────────────────────────────────────
// Normalized DTOs (for ingest adapters)
// ───────────────────────────────────────────────

export interface NormalizedGame {
  source: DataSource;
  sourceGameId: string;
  sport: Sport;
  season: number;
  homeTeamName: string;
  awayTeamName: string;
  startTime: string;
  venue?: string;
  status: GameStatus;
  homeScore?: number;
  awayScore?: number;
}

export interface NormalizedTeamStat {
  teamId: string;
  season: number;
  sport: Sport;
  scope: 'season' | 'game';
  gameId?: string;
  stats: Record<string, number | string | null>;
  source: string;
  updatedAt: string;
}

// ───────────────────────────────────────────────
// Moderation
// ───────────────────────────────────────────────

export interface ModerationAction {
  id?: string;
  postId: string;
  moderatorId: string;
  status: PostStatus;
  reason: string;
  createdAt: FirestoreTimestamp;
}

// ───────────────────────────────────────────────
// Articles (AI-generated journalistic content)
// ───────────────────────────────────────────────

/** The type of article produced by the generator */
export type ArticleType = 'preview' | 'recap' | 'stat_story';

/** Status of a generated article document */
export type ArticleStatus = 'draft' | 'published' | 'hidden';

/**
 * A section with a title and a prose narrative (used for tacticalBreakdown, theVerdict summary,
 * and other narrative blocks).
 */
export interface ArticleNarrativeSection {
  title: string;
  narrative: string;
}

/**
 * A section with a title and a list of bullet-point strings (used for byTheNumbers).
 */
export interface ArticleListSection {
  title: string;
  items: string[];
}

/**
 * Player spotlight block inside an article.
 * playerId and teamId are provenance fields stamped by the generator (not by the LLM).
 */
export interface PlayerSpotlight {
  playerId: string;
  name: string;
  teamId?: string;
  position: string;
  narrative: string;
  statline: string;
}

/**
 * Verdict / prediction block. For recap articles use `result` instead of `prediction`.
 * confidence is 0-100 (not betting odds; fan-confidence language).
 */
export interface Verdict {
  title: string;
  /** Human-readable prediction string (preview) or final result (recap) */
  prediction?: string;
  result?: string;
  /** 0-100 fan confidence score (only meaningful for previews) */
  confidence?: number;
  narrative: string;
}

/**
 * Canonical Firestore document shape for articles/{articleId}.
 * Provenance fields (gameId, sport, status, model, generatedAt, publishedAt, sources,
 * confidence) are stamped by the generator pipeline — the LLM only writes editorial fields.
 */
export interface Article {
  id?: string;

  // ── Editorial (written by Claude or the seed template) ────────────────────
  type: ArticleType;
  headline: string;
  subheadline: string;
  openingNarrative: string;
  tacticalBreakdown?: ArticleNarrativeSection;
  byTheNumbers: ArticleListSection;
  playerSpotlights: PlayerSpotlight[];
  theVerdict: Verdict;
  closingLine: string;

  // ── Provenance (stamped by the pipeline, not the LLM) ────────────────────
  gameId: string;
  sport: Sport;
  status: ArticleStatus;
  /** Which stored docs fed the model, e.g. "seed_demo:team_stats/kentucky_football_2025_season" */
  sources: string[];
  /** Model ID used for generation, or "seed_template" for the no-key offline fallback */
  model: string;
  generatedAt: FirestoreTimestamp;
  publishedAt: FirestoreTimestamp;
  /** "demo" | "official" | confidence level descriptor */
  confidence: string;
  featured?: boolean;
}
