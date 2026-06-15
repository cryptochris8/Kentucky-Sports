# 03 — Tech Stack and Architecture

## Recommended stack

Use the Pregame-inspired stack:

### Mobile
- Flutter
- Dart
- Clean Architecture
- BLoC or Riverpod
- Firebase Auth
- Cloud Firestore
- Firebase Messaging
- Firebase Analytics
- Firebase App Check
- Hive or Isar for offline cache

### Backend
- Firebase Cloud Functions, TypeScript
- Firestore
- Cloud Scheduler
- Cloud Tasks if queues are needed
- Cloud Storage
- Firebase Remote Config
- Firebase Emulator Suite
- Optional later: Cloud Run for heavier data ingestion or ML/stat models

### Admin portal
- React
- Vite
- TypeScript
- Tailwind CSS
- Firebase Auth
- Firestore
- Firebase Hosting
- Role-based access

### Payments
- MVP: free app with future-ready entitlement model
- Mobile subscriptions: RevenueCat
- Sponsor/venue billing: Stripe
- Later: in-app purchase for premium stats, ad-free, custom cards

### Data sources
- CollegeFootballData API
- CollegeBasketballData API
- KHSAA public pages with link-outs, admin import, partnership, or permission
- News: admin-curated links and allowed RSS only
- Recruiting: public metadata only; link to source; no scraping restricted pages

## Why not Supabase first?

Supabase is great, but Firebase fits Chris's existing Pregame workflow and app portfolio:
- Flutter support is strong
- Firestore works well for real-time fan feeds and predictions
- Cloud Functions fit data sync jobs
- Firebase Messaging supports notifications
- Firebase Hosting supports admin portal
- App Check adds abuse protection
- Existing Pregame code concepts can transfer

## Monorepo structure

```text
bluegrass-gameday/
  apps/
    mobile_flutter/
      lib/
      test/
      pubspec.yaml
    admin_portal/
      src/
      package.json
  functions/
    src/
      index.ts
      ingest/
      stats/
      predictions/
      notifications/
      moderation/
      admin/
    package.json
  packages/
    shared_models/
    stats_engine/
  firebase/
    firestore.rules
    firestore.indexes.json
    storage.rules
  scripts/
    seed_firestore.ts
    import_khsaa_csv.ts
    sync_cfbd.ts
    sync_cbbd.ts
  seed_data/
  docs/
```

## Runtime architecture

```text
Flutter App
  ↓ Firebase SDK
Firebase Auth + Firestore + FCM
  ↓
Cloud Functions TypeScript
  ↓
External data providers
  - CollegeFootballData
  - CollegeBasketballData
  - KHSAA-approved imports
  - Admin-curated news links
```

## Data flow

### Nightly sync
1. Cloud Scheduler triggers `syncCollegeFootballNightly`.
2. Function calls CollegeFootballData API using server-side secret.
3. Function transforms data into normalized Firestore documents.
4. Function writes schedules, team stats, player stats, game lines, advanced metrics.
5. Function stores sync metadata and errors.

### Gameday sync
1. Cloud Scheduler triggers more frequent sync on game days.
2. Pull scoreboard/play-by-play depending on API tier.
3. Update game state and live summary cards.
4. Trigger FCM notifications for subscribed users.

### Prediction scoring
1. Prediction closes at game start or configured deadline.
2. User picks are locked.
3. After final score or result data arrives, Cloud Function calculates points.
4. XP, streaks, badges, and leaderboards update.
5. Users receive result notification.

### Admin content
1. Admin portal creates featured cards, news link cards, polls, prediction questions.
2. Firestore publishes to mobile app.
3. Moderators can hide posts/comments and ban users.

## Flutter app feature modules

```text
features/home
features/gameday
features/teams
features/stats_lab
features/players
features/recruiting
features/high_school
features/predictions
features/community
features/rewards
features/profile
features/settings
```

Each module should contain:
```text
data/
domain/
presentation/
```

## Backend function modules

```text
src/ingest/cfbd.ts
src/ingest/cbbd.ts
src/ingest/khsaaImport.ts
src/stats/footballMetrics.ts
src/stats/basketballMetrics.ts
src/predictions/scorePredictions.ts
src/rewards/xpEngine.ts
src/notifications/push.ts
src/moderation/moderationQueue.ts
src/admin/cms.ts
```

## Performance rules

- Cache all third-party API data server-side.
- Do not hit external sports APIs from Flutter.
- Use Firestore denormalized read models for mobile screens.
- Keep home screen under 15 document reads where possible.
- Batch writes in ingestion functions.
- Use TTL or archival for old live play-by-play snapshots.
- Use Remote Config for feature flags.

## Offline support

MVP:
- Cache home dashboard
- Cache schedule
- Cache team/player pages
- Allow prediction draft locally, but submit only when online

Phase 2:
- Offline high school school pages
- Saved stat comparisons
- Downloaded historical stat packs
