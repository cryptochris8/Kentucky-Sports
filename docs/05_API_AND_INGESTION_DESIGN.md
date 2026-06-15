# 05 — API and Data Ingestion Design

## Principle

The mobile app should read fast, clean, already-normalized Firestore documents. All external data access should go through Cloud Functions or scheduled jobs.

## External providers

### CollegeFootballData

Use for:
- teams
- schedules/games
- scores
- team stats
- player stats
- recruiting
- advanced metrics
- live scoreboard/play-by-play if subscription tier supports it
- win probability and EPA/PPA where available

### CollegeBasketballData

Use for:
- schedules/games
- team metrics
- adjusted ratings
- shooting profiles
- player/team stats
- tournament/modeling data where available

### KHSAA

Use for:
- official link-outs
- school directory references
- schedules/scores references
- stats leader references
- RPI references
- manual CSV/admin import if allowed

Do not scrape KHSAA pages until terms and permission are reviewed. Start with manual import and link cards.

### News and content

Use:
- admin-created link cards
- RSS feeds only where permitted
- summaries written by the app/admin, not copied article bodies
- paywalled/insider content should only be linked, not summarized in detail

## Cloud Functions

### Public read endpoints

These are optional in Firebase because the mobile app can read Firestore directly. Use callable/HTTPS functions for aggregation or protected actions.

```text
GET /api/home
GET /api/teams/:teamId
GET /api/games/:gameId
GET /api/stats/team/:teamId/:season
GET /api/stats/player/:playerId/:season
GET /api/high-schools/:schoolId
GET /api/recruits
```

### User action functions

```text
submitPrediction(predictionId, selectedOptionId, numericValue?)
reactToPost(postId, reactionType)
votePoll(pollId, optionId)
claimBadge(badgeId) // mostly server-awarded, but callable for claimable badges
updateNotificationSettings(settings)
```

### Admin functions

```text
adminCreateGame(payload)
adminCreatePrediction(payload)
adminCreateNewsCard(payload)
adminImportHighSchoolCsv(payload)
adminFeatureCard(payload)
adminModeratePost(postId, status, reason)
adminTriggerSync(provider, sport, season)
```

### Scheduled functions

```text
syncCollegeFootballNightly
syncCollegeBasketballNightly
syncGamedayScoreboard
scoreClosedPredictions
awardDailyStreakBadges
sendMorningPulseNotification
sendGamedayNotifications
archiveOldLiveData
```

## Data source adapters

Create adapter modules:

```text
functions/src/ingest/providers/cfbdClient.ts
functions/src/ingest/providers/cbbdClient.ts
functions/src/ingest/providers/khsaaCsvParser.ts
functions/src/ingest/providers/newsRssClient.ts
```

Each adapter returns internal normalized DTOs.

## Normalized DTO examples

### NormalizedGame

```ts
export interface NormalizedGame {
  source: 'cfbd' | 'cbbd' | 'khsaa' | 'manual';
  sourceGameId: string;
  sport: Sport;
  season: number;
  homeTeamName: string;
  awayTeamName: string;
  startTime: string;
  venue?: string;
  status: 'scheduled' | 'live' | 'final' | 'postponed' | 'canceled';
  homeScore?: number;
  awayScore?: number;
}
```

### NormalizedTeamStat

```ts
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
```

## Cloud Function pseudocode

```ts
export const syncCollegeFootballNightly = onSchedule('every day 03:00', async () => {
  const api = new CfbdClient(process.env.CFBD_API_KEY);
  const games = await api.getKentuckyGames(currentSeason);
  const stats = await api.getKentuckyTeamStats(currentSeason);
  const players = await api.getKentuckyPlayerStats(currentSeason);

  const batch = db.batch();

  for (const game of games.map(normalizeCfbdGame)) {
    batch.set(db.collection('games').doc(game.id), game, { merge: true });
  }

  for (const stat of stats.map(normalizeCfbdTeamStat)) {
    batch.set(db.collection('team_stats').doc(stat.id), stat, { merge: true });
  }

  await batch.commit();
});
```

## Caching strategy

- Store raw payload snapshots in Cloud Storage for debugging if allowed by provider terms.
- Store normalized data in Firestore.
- Store `sync_runs` documents with status, provider, records processed, errors.

### sync_runs/{syncRunId}

```json
{
  "provider": "cfbd",
  "sport": "football",
  "startedAt": "timestamp",
  "completedAt": "timestamp",
  "status": "success",
  "recordsProcessed": 124,
  "error": null
}
```

## Rate limit strategy

- Sync nightly for historical/season stats.
- Sync more often only on Kentucky game days.
- Use provider tier appropriate to call volume.
- Use Firestore cache so multiple users do not multiply provider calls.
- Backoff retries.
- Alert admin on failures.

## AI summaries

Allowed:
- Summaries generated from your own stored stats, game data, and admin notes.
- Example: "Kentucky's edge is turnover margin and red-zone efficiency."

Not allowed:
- Summarizing paywalled articles or reproducing insider content.
- Using copyrighted article bodies as source text.

## API keys and secrets

Use:
- Firebase Functions config
- Google Secret Manager
- `.env.local` for emulator only

Do not use:
- API keys in Flutter code
- API keys in public GitHub
- API keys in admin portal frontend
