// Bluegrass Gameday — Firebase Cloud Functions entry point
// All exported names here become deployed Cloud Functions.

// ── Predictions ──────────────────────────────────────────────────────────────
export { submitPrediction } from './predictions/submitPrediction';
export { adminScorePrediction } from './predictions/adminScorePrediction';
export { onGameUpdated } from './predictions/onGameUpdated';

// ── Community ─────────────────────────────────────────────────────────────────
export { votePoll } from './community/votePoll';
export { reactToPost } from './community/reactToPost';

// ── Admin ─────────────────────────────────────────────────────────────────────
export { adminCreatePrediction } from './admin/adminCreatePrediction';
export { adminCreateNewsCard } from './admin/adminCreateNewsCard';
export { adminModeratePost } from './admin/adminModeratePost';

// ── Scheduled (ingest stubs) ──────────────────────────────────────────────────
export {
  syncCollegeFootballNightly,
  syncCollegeBasketballNightly,
  syncGamedayScoreboard,
} from './ingest/scheduledFunctions';
