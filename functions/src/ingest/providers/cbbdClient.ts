// CollegeBasketballData adapter skeleton — Phase 2 implementation
// DO NOT make real HTTP calls in Phase 1.

import type { NormalizedGame, NormalizedTeamStat, Sport } from '@bluegrass/shared-models';

export interface CbbdClientConfig {
  apiKey: string;
  baseUrl?: string;
}

/** Typed skeleton for the CBBD API adapter. Real implementation in Phase 2. */
export class CbbdClient {
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(config: CbbdClientConfig) {
    this.apiKey = config.apiKey;
    this.baseUrl = config.baseUrl ?? 'https://api.collegebasketballdata.com';
  }

  // TODO Phase 2: implement real HTTP calls
  async getKentuckyGames(_season: number): Promise<NormalizedGame[]> {
    throw new Error('CbbdClient.getKentuckyGames — Phase 2 not implemented');
  }

  async getKentuckyTeamStats(_season: number): Promise<NormalizedTeamStat[]> {
    throw new Error('CbbdClient.getKentuckyTeamStats — Phase 2 not implemented');
  }

  async getKentuckyPlayerStats(
    _season: number,
  ): Promise<Array<{ playerId: string; stats: Record<string, number | string | null>; sport: Sport }>> {
    throw new Error('CbbdClient.getKentuckyPlayerStats — Phase 2 not implemented');
  }
}

export function createCbbdClient(): CbbdClient {
  const apiKey = process.env.CBBD_API_KEY ?? '';
  if (!apiKey) {
    console.warn('CBBD_API_KEY not set — CbbdClient will throw on any real call');
  }
  return new CbbdClient({ apiKey });
}
