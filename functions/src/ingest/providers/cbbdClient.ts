// CollegeBasketballData adapter — Phase 2 implementation
// Key-gated: when CBBD_API_KEY is absent all public methods throw with a clear message.
// DO NOT hardcode secrets here. Key comes from process.env.CBBD_API_KEY exclusively.

import type { NormalizedGame, NormalizedTeamStat, Sport, GameStatus } from '@bluegrass/shared-models';

export interface CbbdClientConfig {
  apiKey: string;
  baseUrl?: string;
}

// ── Wire DTOs (subset we care about from the CBBD API) ──────────────────────

export interface CbbdGameDto {
  id: string | number;
  season: number;
  homeTeam: string;
  awayTeam: string;
  startDate: string;
  arena?: string;
  status?: string; // "Final", "Scheduled", "InProgress"
  homeScore?: number | null;
  awayScore?: number | null;
  neutral?: boolean;
}

export interface CbbdTeamMetricsDto {
  season?: number;
  team?: string;
  adjOE?: number | null;  // adjusted offensive efficiency
  adjDE?: number | null;  // adjusted defensive efficiency
  adjNetRating?: number | null;
  tempo?: number | null;
  effectiveFGPct?: number | null;
  turnoverRate?: number | null;
  offReboundRate?: number | null;
  freeThrowRate?: number | null;
  pointsPerGame?: number | null;
  pointsAllowedPerGame?: number | null;
  [key: string]: unknown;
}

export interface CbbdPlayerStatDto {
  playerId?: string | number;
  playerName?: string;
  team?: string;
  season?: number;
  points?: number | null;
  rebounds?: number | null;
  assists?: number | null;
  effectiveFGPct?: number | null;
  threePointPct?: number | null;
  [key: string]: unknown;
}

// ── Normalization helpers ────────────────────────────────────────────────────

function mapCbbdStatus(dto: CbbdGameDto): GameStatus {
  const s = (dto.status ?? '').toLowerCase();
  if (s === 'final' || s === 'completed') return 'final';
  if (s === 'inprogress' || s === 'in_progress' || s === 'live') return 'live';
  if (s === 'postponed') return 'postponed';
  if (s === 'cancelled' || s === 'canceled') return 'canceled';
  return 'scheduled';
}

export function normalizeCbbdGame(dto: CbbdGameDto): NormalizedGame {
  return {
    source: 'cbbd',
    sourceGameId: String(dto.id),
    sport: 'mens_basketball',
    season: dto.season,
    homeTeamName: dto.homeTeam,
    awayTeamName: dto.awayTeam,
    startTime: dto.startDate,
    venue: dto.arena,
    status: mapCbbdStatus(dto),
    homeScore: dto.homeScore ?? undefined,
    awayScore: dto.awayScore ?? undefined,
  };
}

export function normalizeCbbdTeamStat(
  dto: CbbdTeamMetricsDto,
  season: number,
): NormalizedTeamStat {
  const stats: Record<string, number | string | null> = {
    adjOffRating: dto.adjOE ?? null,
    adjDefRating: dto.adjDE ?? null,
    adjNetRating: dto.adjNetRating ?? null,
    tempo: dto.tempo ?? null,
    effectiveFgPct: dto.effectiveFGPct ?? null,
    turnoverRate: dto.turnoverRate ?? null,
    offReboundRate: dto.offReboundRate ?? null,
    freeThrowRate: dto.freeThrowRate ?? null,
    pointsPerGame: dto.pointsPerGame ?? null,
    pointsAllowedPerGame: dto.pointsAllowedPerGame ?? null,
  };

  return {
    teamId: 'kentucky_mens_basketball',
    season,
    sport: 'mens_basketball',
    scope: 'season',
    stats,
    source: 'cbbd',
    updatedAt: new Date().toISOString(),
  };
}

// ── Client ───────────────────────────────────────────────────────────────────

export class CbbdClient {
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(config: CbbdClientConfig) {
    this.apiKey = config.apiKey;
    this.baseUrl = config.baseUrl ?? 'https://api.collegebasketballdata.com';
  }

  private requireKey(): void {
    if (!this.apiKey) {
      throw new Error(
        '[CbbdClient] CBBD_API_KEY is not set — skipping provider call. ' +
          'Set CBBD_API_KEY in your environment or Firebase Functions config to enable live sync.',
      );
    }
  }

  private async fetchJson<T>(path: string, params: Record<string, string | number>): Promise<T> {
    this.requireKey();
    const url = new URL(`${this.baseUrl}${path}`);
    for (const [k, v] of Object.entries(params)) url.searchParams.set(k, String(v));

    const res = await fetch(url.toString(), {
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        Accept: 'application/json',
      },
    });

    if (!res.ok) {
      throw new Error(`[CbbdClient] HTTP ${res.status} for ${path}: ${await res.text()}`);
    }
    return res.json() as Promise<T>;
  }

  async getKentuckyGames(season: number): Promise<NormalizedGame[]> {
    const raw = await this.fetchJson<CbbdGameDto[]>('/games', {
      season,
      team: 'Kentucky',
    });
    return raw.map(normalizeCbbdGame);
  }

  async getKentuckyTeamStats(season: number): Promise<NormalizedTeamStat[]> {
    const raw = await this.fetchJson<CbbdTeamMetricsDto[]>('/metrics/team', {
      season,
      team: 'Kentucky',
    });
    return raw.map((dto) => normalizeCbbdTeamStat(dto, season));
  }

  async getKentuckyPlayerStats(
    season: number,
  ): Promise<Array<{ playerId: string; stats: Record<string, number | string | null>; sport: Sport }>> {
    const raw = await this.fetchJson<CbbdPlayerStatDto[]>('/stats/player', {
      season,
      team: 'Kentucky',
    });

    return raw.map((dto) => ({
      playerId: String(dto.playerId ?? dto.playerName ?? 'unknown'),
      sport: 'mens_basketball' as Sport,
      stats: {
        points: dto.points ?? null,
        rebounds: dto.rebounds ?? null,
        assists: dto.assists ?? null,
        effectiveFgPct: dto.effectiveFGPct ?? null,
        threePointPct: dto.threePointPct ?? null,
      },
    }));
  }
}

export function createCbbdClient(): CbbdClient {
  const apiKey = process.env.CBBD_API_KEY ?? '';
  if (!apiKey) {
    console.warn('[CbbdClient] CBBD_API_KEY not set — client will throw on any real call');
  }
  return new CbbdClient({ apiKey });
}
