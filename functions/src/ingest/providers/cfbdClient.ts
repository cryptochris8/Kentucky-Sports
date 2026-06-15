// CollegeFootballData adapter skeleton — Phase 2 implementation
// DO NOT make real HTTP calls in Phase 1.

import type { NormalizedGame, NormalizedTeamStat, Sport } from '@bluegrass/shared-models';

export interface CfbdClientConfig {
  apiKey: string;
  baseUrl?: string;
}

/** Typed skeleton for the CFBD API adapter. Real implementation in Phase 2. */
export class CfbdClient {
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(config: CfbdClientConfig) {
    // Key comes from env — never hardcoded
    this.apiKey = config.apiKey;
    this.baseUrl = config.baseUrl ?? 'https://api.collegefootballdata.com';
  }

  // TODO Phase 2: implement real HTTP calls with retry + backoff
  async getKentuckyGames(_season: number): Promise<NormalizedGame[]> {
    throw new Error('CfbdClient.getKentuckyGames — Phase 2 not implemented');
  }

  async getKentuckyTeamStats(_season: number): Promise<NormalizedTeamStat[]> {
    throw new Error('CfbdClient.getKentuckyTeamStats — Phase 2 not implemented');
  }

  async getKentuckyPlayerStats(
    _season: number,
  ): Promise<Array<{ playerId: string; stats: Record<string, number | string | null>; sport: Sport }>> {
    throw new Error('CfbdClient.getKentuckyPlayerStats — Phase 2 not implemented');
  }
}

export function createCfbdClient(): CfbdClient {
  const apiKey = process.env.CFBD_API_KEY ?? '';
  if (!apiKey) {
    console.warn('CFBD_API_KEY not set — CfbdClient will throw on any real call');
  }
  return new CfbdClient({ apiKey });
}
