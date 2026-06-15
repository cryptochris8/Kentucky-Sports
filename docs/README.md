# Bluegrass Gameday / Kentucky Fan Stats App — Claude Code Build Pack

Generated: 2026-06-15

This ZIP is designed to be dropped into a project folder and read by Claude Code before coding. It converts the Kentucky Wildcats fan app idea into a buildable product plan, with a recommended stack, database design, API plan, MVP phases, and detailed implementation prompts.

## Working product name

**Bluegrass Gameday**  
Alternative names:
- Bluegrass Pulse
- CatStats Kentucky
- Bluegrass Stats Lab
- BBN Pulse, only if branding/trademark review says it is safe

The project should avoid official University of Kentucky logos, marks, mascot art, and licensed brand assets unless Chris obtains permission. The app should be positioned as an independent fan and statistics companion.

## Recommended stack

Because Pregame already used Flutter + Firebase + React portal patterns, this pack recommends:

- **Mobile app:** Flutter, Dart, Clean Architecture, BLoC or Riverpod, Firebase SDK, Hive/Isar offline cache
- **Backend:** Firebase Auth, Firestore, Cloud Functions TypeScript, Cloud Scheduler, Cloud Storage, Firebase Cloud Messaging, App Check
- **Admin portal:** React + Vite + TypeScript + Tailwind + Firebase Hosting
- **Payments:** RevenueCat for mobile subscriptions first; Stripe for web/admin/sponsor billing later
- **Analytics/data:** CollegeFootballData + CollegeBasketballData, with KHSAA imports/partnership/manual moderation for Kentucky high school data
- **Search:** Firestore query/indexes in MVP; Algolia, Typesense, or Meilisearch later if search grows

## How to use with Claude Code

1. Create a new project folder, for example:
   ```bash
   mkdir bluegrass-gameday
   cd bluegrass-gameday
   ```

2. Unzip this pack into that folder.

3. Open Claude Code in the project folder.

4. Tell Claude Code:
   ```text
   Read CLAUDE.md and all markdown files in this folder. Then create the app scaffold exactly as instructed. Start with Phase 0 and Phase 1 only. Do not skip Firebase emulator setup, mock data, or tests.
   ```

5. After the scaffold is created, use the prompts inside `/prompts` one at a time.

## Package contents

- `CLAUDE.md` — master instructions for Claude Code
- `01_RESEARCH_EVALUATION.md` — competitive landscape and app opportunity
- `02_PRODUCT_REQUIREMENTS.md` — complete PRD
- `03_TECH_STACK_ARCHITECTURE.md` — frontend, backend, admin portal, data pipeline
- `04_FIREBASE_DATA_MODEL.md` — Firestore collections, fields, indexes, security rules concept
- `05_API_AND_INGESTION_DESIGN.md` — Cloud Functions and data ingestion contracts
- `06_STATS_ENGINE_DESIGN.md` — football/basketball/high-school stats engine
- `07_GAMIFICATION_AND_COMMUNITY.md` — badges, predictions, streaks, groups, moderation
- `08_HIGH_SCHOOL_AND_RECRUITING.md` — Kentucky prep sports, recruiting, NIL strategy
- `09_UI_UX_SCREEN_MAP.md` — screen-by-screen mobile and admin UI
- `10_MONETIZATION_AND_GROWTH.md` — subscription/sponsorship/venue plan
- `11_SECURITY_LEGAL_COMPLIANCE.md` — licensing, moderation, minors, data safety
- `12_MVP_ROADMAP.md` — phase plan
- `13_TESTING_DEPLOYMENT.md` — QA, Firebase emulator, App Store, CI/CD
- `/prompts` — stepwise Claude Code build prompts
- `/schemas` — starter schema contracts and example JSON
- `/seed_data` — sample development data

## First build target

The first build should not try to be ESPN, KSR, 247Sports, MaxPreps, and Pregame all at once.

The MVP target is:

> A Kentucky-first mobile app where a fan can open the app, see the next football/basketball game, view a beautiful matchup dashboard, compare stats, make friendly predictions, earn XP, follow player/recruiting storylines, and optionally follow Kentucky high school pipeline teams/players.

## Best strategic direction

Do not compete with KSR/On3 on written insider reporting. Link to news and build original value around:

- clean stats,
- fan-friendly matchup explanations,
- prediction games,
- Kentucky high school pipeline,
- watch-party/venue integration from Pregame,
- collectible badges/cards,
- personalized notifications,
- AI-generated non-paywalled summaries based on licensed/public data.
