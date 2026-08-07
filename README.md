# 🐾 Bluegrass Gameday

An independent **Kentucky Wildcats fan + statistics** companion app — built to be fun and
engaging for the Big Blue Nation, with clean stats, matchup dashboards, free-to-play
predictions, XP/badges, and a Kentucky high school "Bluegrass Pipeline."

> Bluegrass Gameday is an independent fan and statistics app. It is **not** affiliated with,
> endorsed by, or sponsored by the University of Kentucky, UK Athletics, the NCAA, SEC, or KHSAA.

---

## Monorepo layout

| Path | What it is |
|------|------------|
| `apps/mobile_flutter` | Flutter app — Riverpod + go_router, Clean Architecture. The fan experience. |
| `apps/admin_portal` | React + Vite + Tailwind admin/CMS portal. |
| `functions` | Firebase Cloud Functions (TypeScript) — predictions, XP/badges, sync jobs. |
| `packages/shared_models` | Canonical Firestore types (TypeScript) + schema docs. |
| `packages/stats_engine` | Football/basketball stat helpers + fan-friendly explanations (TS + Dart). |
| `firebase/` | `firestore.rules`, `firestore.indexes.json`, `storage.rules`. |
| `scripts/` | Seed loader + real-data sync (CFBD/CBBD), Vault history sync, AI article/legend generators, key checker. |
| `seed_data/` | Development seed. Schedules/results/rosters are **real** (CFBD/CBBD-sourced, labeled `official`); remaining illustrative values are labeled `demo`. |
| `docs/` | The full product/design pack: 14 docs, build prompts, schema contracts. |

## Tech stack

- **Mobile:** Flutter 3.32 / Dart 3.8, Riverpod, go_router. Mock-first: ships on bundled
  seed data with zero backend (Firebase SDK wiring is a Phase-C+ task, not yet a dependency).
- **Backend:** Firebase Auth, Cloud Firestore, Cloud Functions (TypeScript), FCM, Storage, App Check.
- **Admin:** React + Vite + TypeScript + Tailwind, Firebase Hosting.
- **Data (Phase 2+):** CollegeFootballData, CollegeBasketballData, KHSAA (link-outs / admin import).

## Prerequisites

Node 18+, Flutter 3.32+, Firebase CLI (`npm i -g firebase-tools`), and the Java JDK
(required by the Firestore emulator).

## Quick start (local, no cloud project needed)

```bash
# 1. Install root dev deps (cross-env for the seed script)
npm install

# 2. Start the Firebase emulator suite
firebase emulators:start
#    Emulator UI -> http://localhost:4000

# 3. In a second terminal, load the seed data into the emulator
npm run seed

# 4a. Run the mobile app (ships with a mock data source — runs with zero backend)
cd apps/mobile_flutter
flutter pub get
flutter run            # or: flutter run -d chrome

# 4b. Run the admin portal
cd apps/admin_portal
npm install
npm run dev            # http://localhost:5173

# 4c. Build & test the Cloud Functions
cd functions
npm install
npm run build
npm test
```

## Root scripts

| Command | Description |
|---------|-------------|
| `firebase emulators:start` | Start Auth, Firestore, Functions, Storage, Hosting + UI. |
| `npm run seed` | Load `seed_data/` into the Firestore emulator. |
| `npm run emulators` | Start emulators with local data import/export (persists between runs). |
| `npm run dev-claim` | Grant the admin custom claim on the Auth emulator (needed for the portal + rules). |
| `npm run sync-data` / `vault-sync` | Pull real CFBD/CBBD rosters, stats, and 83 UK season records. |
| `npm run generate` / `generate-legend` | Claude-drafted articles / Vault features from sourced data. |
| `npm run check-keys` | Verify API keys are loadable (masked output — never prints values). |

## Where to go next

- Product plan & design: [`docs/`](docs/) — start with `docs/CLAUDE.md`.
- Data model: [`docs/04_FIREBASE_DATA_MODEL.md`](docs/04_FIREBASE_DATA_MODEL.md).
- Roadmap & phased build prompts: [`docs/12_MVP_ROADMAP.md`](docs/12_MVP_ROADMAP.md), [`docs/prompts/`](docs/prompts/).

## Guardrails

No official UK marks · no secrets in clients · predictions are free-to-play (no betting
language) · no direct messaging · no scraping paywalled content · every stat shows its
source, freshness, and confidence. See [`docs/11_SECURITY_LEGAL_COMPLIANCE.md`](docs/11_SECURITY_LEGAL_COMPLIANCE.md).
