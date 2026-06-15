# CLAUDE.md — Master Instructions for Claude Code

You are building a Flutter + Firebase sports fan app called **Bluegrass Gameday**.

The app is an independent Kentucky sports fan and statistics companion focused first on Kentucky college football and men's basketball, then women's basketball, baseball, volleyball, other UK sports, and Kentucky high school sports.

## Absolute priorities

1. Build a production-quality foundation, not a throwaway prototype.
2. Reuse proven Pregame-style patterns:
   - Flutter mobile app
   - Firebase backend
   - React admin portal
   - Firestore data model
   - Firebase Auth
   - Cloud Functions
   - Firebase Cloud Messaging
   - Stripe/RevenueCat monetization path
   - team schedule/stat pages
   - fan profiles
   - venue/watch-party features later
3. Do not hardcode secrets or API keys into the mobile app.
4. Do not use official University of Kentucky logos, marks, or copyrighted media.
5. Do not scrape restricted/paywalled content.
6. Use clean feature modules and separation of concerns.
7. Start with mock data and emulator-friendly local development before live APIs.

## Build output expected

Create a monorepo:

```text
bluegrass-gameday/
  apps/
    mobile_flutter/
    admin_portal/
  functions/
  packages/
    shared_models/
    stats_engine/
  docs/
  firebase/
    firestore.rules
    firestore.indexes.json
    storage.rules
  scripts/
  seed_data/
  README.md
```

## Recommended mobile architecture

Use Flutter Clean Architecture:

```text
lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    constants/
    errors/
    network/
    auth/
    analytics/
    cache/
  features/
    home/
    gameday/
    teams/
    stats_lab/
    players/
    recruiting/
    high_school/
    predictions/
    community/
    profile/
    settings/
```

State management:
- Use BLoC if Chris wants to stay closest to Pregame.
- Use Riverpod only if the new scaffold is simpler and Claude determines it is faster.
- Do not mix state-management styles inside one feature.

## Recommended backend architecture

Use Firebase:
- Firestore for app data
- Auth for accounts
- Functions TypeScript for data ingest, stats calculation, predictions, moderation hooks
- Cloud Scheduler for nightly sync jobs
- FCM for notifications
- Storage for user uploads and admin content assets
- App Check for abuse reduction

Data providers:
- CollegeFootballData API for football stats, schedules, recruiting, advanced metrics.
- CollegeBasketballData API for basketball stats, team metrics, shooting profile, adjusted ratings.
- KHSAA data: use links, manual CSV import, or partnership/import permission first. Do not scrape without reviewing terms.
- News/content: admin-curated link cards and RSS where allowed. Do not copy paywalled articles.

## MVP scope

Implement Phase 0 and Phase 1 first:

### Phase 0
- Monorepo scaffold
- Flutter shell
- Firebase config placeholders
- Emulator setup
- Shared models
- Seed data
- Basic theme
- App routing
- Auth stub / anonymous user option
- Firestore security rules draft

### Phase 1
- Home dashboard
- Kentucky football and basketball team pages
- Schedule and game detail
- Basic team/player stat cards
- Gameday matchup dashboard
- Predictions game
- XP/badges
- Admin portal to manage mock content, games, featured cards, polls
- Cloud Function stubs for ingest and stat calculations

## Do not build yet

Do not build real-money betting. Predictions are free-to-play only.

Do not build direct messaging for minors or high school athletes in MVP.

Do not create any automated system that ranks high school minors in an exploitative or unsafe way. High school features should focus on school/team stats, schedules, publicly available leaderboards, and positive spotlight content with moderation.

## First task for Claude Code

1. Read every markdown file in this package.
2. Create the monorepo scaffold.
3. Generate the initial Flutter app with screens and mock data.
4. Generate the Firebase Functions TypeScript project.
5. Generate the React admin portal.
6. Add seed data and docs.
7. Stop and summarize the created files and next commands.
