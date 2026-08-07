// CollegeFootballData adapter — Phase 2 implementation
// Key-gated: when CFBD_API_KEY is absent all public methods throw with a clear message.
// DO NOT hardcode secrets here. Key comes from process.env.CFBD_API_KEY exclusively.

import type { NormalizedGame, NormalizedTeamStat, Sport, GameStatus } from '@bluegrass/shared-models';

export interface CfbdClientConfig {
  apiKey: string;
  baseUrl?: string;
}

// ── Wire DTOs (subset we care about from the CFBD API) ──────────────────────

export interface CfbdGameDto {
  id: number;
  season: number;
  home_team: string;
  away_team: string;
  start_date: string;
  venue?: string;
  completed: boolean;
  home_points?: number | null;
  away_points?: number | null;
  status?: string; // e.g. "completed", "scheduled", "in_progress"
  notes?: string;
}

export interface CfbdTeamStatDto {
  game_id?: number;
  team: string;
  conference?: string;
  // Commonly returned team-season stats
  points_per_game?: number;
  total_yards?: number;
  passing_yards?: number;
  rushing_yards?: number;
  third_down_conversions?: number;
  third_down_attempts?: number;
  red_zone_attempts?: number;
  red_zone_scores?: number;
  fumbles_lost?: number;
  interceptions_thrown?: number;
  interceptions?: number;
  sacks?: number;
  [key: string]: unknown;
}

export interface CfbdPlayerStatDto {
  player_id?: string;
  player?: string;
  team?: string;
  stat_type?: string;
  stat?: string | number;
  [key: string]: unknown;
}

// ── Normalization helpers ────────────────────────────────────────────────────

function mapCfbdStatus(dto: CfbdGameDto): GameStatus {
  if (dto.completed) return 'final';
  const s = (dto.status ?? '').toLowerCase();
  if (s === 'in_progress' || s === 'live') return 'live';
  if (s === 'postponed') return 'postponed';
  if (s === 'cancelled' || s === 'canceled') return 'canceled';
  return 'scheduled';
}

export function normalizeCfbdGame(dto: CfbdGameDto): NormalizedGame {
  return {
    source: 'cfbd',
    sourceGameId: String(dto.id),
    sport: 'football',
    season: dto.season,
    homeTeamName: dto.home_team,
    awayTeamName: dto.away_team,
    startTime: dto.start_date,
    venue: dto.venue,
    status: mapCfbdStatus(dto),
    homeScore: dto.home_points ?? undefined,
    awayScore: dto.away_points ?? undefined,
  };
}

export function normalizeCfbdTeamStat(
  dto: CfbdTeamStatDto,
  season: number,
): NormalizedTeamStat {
  const third =
    dto.third_down_attempts && dto.third_down_attempts > 0
      ? (dto.third_down_conversions ?? 0) / dto.third_down_attempts
      : null;
  const redZone =
    dto.red_zone_attempts && dto.red_zone_attempts > 0
      ? (dto.red_zone_scores ?? 0) / dto.red_zone_attempts
      : null;

  const stats: Record<string, number | string | null> = {
    pointsPerGame: dto.points_per_game ?? null,
    totalYards: dto.total_yards ?? null,
    passingYards: dto.passing_yards ?? null,
    rushingYards: dto.rushing_yards ?? null,
    thirdDownPct: third,
    redZoneScorePct: redZone,
    fumbles: dto.fumbles_lost ?? null,
    interceptionsThrown: dto.interceptions_thrown ?? null,
    interceptions: dto.interceptions ?? null,
    sacks: dto.sacks ?? null,
  };

  return {
    teamId: `kentucky_football`,
    season,
    sport: 'football',
    scope: 'season',
    stats,
    source: 'cfbd',
    updatedAt: new Date().toISOString(),
  };
}

// ── Client ───────────────────────────────────────────────────────────────────

/** Abort a hung provider connection well before the function's own timeout. */
const FETCH_TIMEOUT_MS = 15_000;
/** Delay before the single retry on transient (429/5xx/network) failures. */
const RETRY_DELAY_MS = 2_000;
/** Error messages end up in sync_runs docs — never echo a full response body. */
const ERROR_BODY_LIMIT = 500;

export class CfbdClient {
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(config: CfbdClientConfig) {
    this.apiKey = config.apiKey;
    this.baseUrl = config.baseUrl ?? 'https://api.collegefootballdata.com';
  }

  private requireKey(): void {
    if (!this.apiKey) {
      throw new Error(
        '[CfbdClient] CFBD_API_KEY is not set — skipping provider call. ' +
          'Set CFBD_API_KEY in your environment or Firebase Functions config to enable live sync.',
      );
    }
  }

  private async fetchJson<T>(path: string, params: Record<string, string | number>): Promise<T> {
    this.requireKey();
    const url = new URL(`${this.baseUrl}${path}`);
    for (const [k, v] of Object.entries(params)) url.searchParams.set(k, String(v));

    let lastError: Error | null = null;
    for (let attempt = 0; attempt <= 1; attempt++) {
      if (attempt > 0) await new Promise((resolve) => setTimeout(resolve, RETRY_DELAY_MS));

      let res: Response;
      try {
        res = await fetch(url.toString(), {
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            Accept: 'application/json',
          },
          signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
        });
      } catch (err) {
        // Timeout / network failure — worth one retry.
        lastError = new Error(
          `[CfbdClient] Network error for ${path}: ${err instanceof Error ? err.message : String(err)}`,
        );
        continue;
      }

      if (!res.ok) {
        const body = (await res.text()).slice(0, ERROR_BODY_LIMIT);
        const error = new Error(`[CfbdClient] HTTP ${res.status} for ${path}: ${body}`);
        if (res.status === 429 || res.status >= 500) {
          lastError = error; // transient — retry once
          continue;
        }
        throw error; // other 4xx will not improve on retry
      }

      return (await res.json()) as T;
    }
    throw lastError ?? new Error(`[CfbdClient] Request failed for ${path}`);
  }

  async getKentuckyGames(season: number): Promise<NormalizedGame[]> {
    const raw = await this.fetchJson<CfbdGameDto[]>('/games', {
      season,
      team: 'Kentucky',
      seasonType: 'regular',
    });
    return raw.map(normalizeCfbdGame);
  }

  async getKentuckyTeamStats(season: number): Promise<NormalizedTeamStat[]> {
    const raw = await this.fetchJson<CfbdTeamStatDto[]>('/stats/season', {
      season,
      team: 'Kentucky',
    });
    return raw.map((dto) => normalizeCfbdTeamStat(dto, season));
  }

  async getKentuckyPlayerStats(
    season: number,
  ): Promise<Array<{ playerId: string; stats: Record<string, number | string | null>; sport: Sport }>> {
    const raw = await this.fetchJson<CfbdPlayerStatDto[]>('/stats/player/season', {
      season,
      team: 'Kentucky',
    });

    return raw.map((dto) => ({
      playerId: String(dto.player_id ?? dto.player ?? 'unknown'),
      sport: 'football' as Sport,
      stats: {
        statType: dto.stat_type ?? null,
        value: typeof dto.stat === 'number' ? dto.stat : null,
      },
    }));
  }
}

export function createCfbdClient(apiKey: string = process.env.CFBD_API_KEY ?? ''): CfbdClient {
  if (!apiKey) {
    console.warn('[CfbdClient] CFBD_API_KEY not set — client will throw on any real call');
  }
  return new CfbdClient({ apiKey });
}
