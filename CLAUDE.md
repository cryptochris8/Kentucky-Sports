# CLAUDE.md — Bluegrass Gameday

Master instructions for Claude Code working in this repository. The full product
plan lives in [`docs/`](docs/) (start with `docs/CLAUDE.md`, `docs/02_PRODUCT_REQUIREMENTS.md`,
and `docs/04_FIREBASE_DATA_MODEL.md`).

## What this is

**Bluegrass Gameday** — an independent Kentucky sports fan + statistics companion app.
Football and men's basketball first, then women's basketball, baseball, volleyball, and
Kentucky high school sports. It is **not** a betting app and **not** affiliated with the
University of Kentucky.

## Locked decisions (this build)

- **Monorepo** rooted at this directory.
- **Mobile:** Flutter + Dart, **Riverpod** state management, `go_router`, Clean Architecture
  feature modules, Firebase SDK, mock/seed data first.
- **Backend:** Firebase — Auth, Firestore, Cloud Functions (TypeScript), FCM, Storage, App Check.
- **Admin portal:** React + Vite + TypeScript + Tailwind, Firebase Hosting.
- **Data providers (Phase 2+):** CollegeFootballData, CollegeBasketballData, KHSAA via
  link-outs / admin CSV import. Never called from the mobile client.

## Repository layout

```
apps/mobile_flutter      Flutter app (Riverpod, clean architecture)
apps/admin_portal        React + Vite + Tailwind admin portal
functions                Firebase Cloud Functions (TypeScript)
packages/shared_models   Canonical Firestore types (TS) + schema docs
packages/stats_engine    Football/basketball stat helpers (TS + Dart)
firebase/                firestore.rules, firestore.indexes.json, storage.rules
scripts/                 seed_firestore.ts and future importers
seed_data/dev_seed.json  Development seed data (source: seed_demo)
docs/                    The full product/design pack (14 docs + prompts + schemas)
```

## Hard rules (do not violate)

1. No official University of Kentucky logos, marks, mascot art, or copyrighted media.
2. No API keys or secrets in the Flutter app or the admin frontend. Server-side only
   (Functions config / Secret Manager / `.env.local` for the emulator).
3. Predictions are **free-to-play only**. Never use betting language (bet, wager, odds,
   parlay, sportsbook). Use pick / prediction / confidence / challenge / XP.
4. No direct messaging, especially around high school / minors. School/team-level content
   first; individual spotlights only from public sources, with moderation.
5. Don't scrape paywalled/restricted content (KSR+, On3, 247, Rivals, ESPN, MaxPreps).
   Admin-curated link cards and allowed feeds only.
6. Every stat document carries `source`, `updatedAt`, and `confidence`. Never invent data;
   label demo/fan-submitted data clearly.
7. Clean feature modules and separation of concerns. Don't mix state-management styles
   within a feature.

## Local development

```bash
firebase emulators:start          # Auth :9099  Firestore :8080  Functions :5001  UI :4000
npm run seed                      # load seed_data into the Firestore emulator
# Flutter:  cd apps/mobile_flutter && flutter run
# Admin:    cd apps/admin_portal && npm run dev
# Functions:cd functions && npm run build && npm test
```

The Flutter app ships with a **mock data source** that reads the bundled seed, so it runs
with zero backend. Point it at the emulator by flipping the repository's data-source flag.

## Build status

- [x] Phase 0 — monorepo scaffold, Firebase config, emulator, seed data, security rules.
- [~] Phase 1 — Flutter MVP screens (Pulse, Teams, Gameday HQ, Stats Lab, Predictions,
      Profile) on seed data; Functions skeleton (prediction scoring, XP, badges);
      admin portal skeleton.
- [ ] Phase 2 — real CFBD/CBBD sync, KHSAA link cards. (Do not start without asking.)

See `docs/12_MVP_ROADMAP.md` and `docs/prompts/` for the phased build prompts.
