/**
 * Deployment-shape tests: pin trigger/schedule options that only take effect
 * in production (the handlers never run under vitest), because a wrong option
 * here fails silently:
 *   - v2 Firestore triggers default to retry: false, which would turn
 *     onGameUpdated's deliberate rethrow into a log line and strand
 *     unscored predictions;
 *   - a freshness window >= the 24 h schedule period makes the nightly sync
 *     self-skip every other night (last night's completed run still counts as
 *     "fresh" when tonight's fires).
 */
import { describe, it, expect } from 'vitest';
import { onGameUpdated } from '../predictions/onGameUpdated';
import { FRESHNESS_WINDOW_HOURS } from '../ingest/scheduledFunctions';

describe('onGameUpdated trigger options', () => {
  it('has retry explicitly enabled (v2 default is no retry)', () => {
    expect(onGameUpdated.__endpoint.eventTrigger?.retry).toBe(true);
  });

  it('still listens on games/{gameId} document updates', () => {
    expect(onGameUpdated.__endpoint.eventTrigger?.eventFilterPathPatterns?.['document']).toBe(
      'games/{gameId}',
    );
  });
});

describe('nightly sync freshness window', () => {
  it('is shorter than the 24 h schedule period so a completed run never blocks the next night', () => {
    expect(FRESHNESS_WINDOW_HOURS).toBeGreaterThan(0);
    expect(FRESHNESS_WINDOW_HOURS).toBeLessThan(24);
  });
});
