# CLAUDE.md — Bluegrass Gameday

Master instructions for Claude Code working in this repository. The full product
plan lives in [`docs/`](docs/) (start with `docs/CLAUDE.md`, `docs/02_PRODUCT_REQUIREMENTS.md`,
and `docs/04_FIREBASE_DATA_MODEL.md`).

## What this is

**Bluegrass Gameday** — an independent **Kentucky-identity** app anchored by UK Football
and Men's Basketball (see `docs/VISION.md` for the five pillars: The Cats · The Vault ·
Bluegrass Preps · All Things Kentucky · The Porch). It is **not** a betting app and
**not** affiliated with the University of Kentucky. Brand name is still an open decision
("Barrels & Banners" leading — see VISION "Open decisions").

**Shipped IA (post-redesign):** 5-tab hub — Home · Gameday · Vault · Preps · Profile —
in the Hybrid design system (Bento Home/Stats, Broadcast Gameday, Editorial Vault; KY blue
`#0033A0` on white, full light + dark). There is no "Pulse" screen and no top-level
"Stats Lab" tab anymore; stats live inside Gameday's Breakdown · Stats · Predictions
sub-tabs.

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
npm run dev-claim                 # grant the admin custom claim on the Auth emulator
                                  # (run once after "Dev sign-in" — the portal's RoleGuard
                                  #  AND firestore.rules read request.auth.token.role)
# Flutter:  cd apps/mobile_flutter && flutter run -d web-server --web-port 5050
# Admin:    cd apps/admin_portal && npm run dev
# Functions:cd functions && npm run build && npm test
```

Data/AI pipeline (root passthroughs; real keys live in gitignored `functions/.env.local`,
verify with `npm run check-keys` — masked output only):

```bash
npm run sync-data          # real CFBD/CBBD rosters + stats into the seed
npm run vault-sync         # 83 UK season records (FB 1985-2025, MBB 1984-85 → 2025-26)
npm run generate           # Claude article drafts   |  npm run apply-articles
npm run generate-legend    # Vault "Eras & Legends" feature from a sourced brief
```

`sync-data`, `vault-sync`, and `generate-legend` wrap `NODE_TLS_REJECT_UNAUTHORIZED=0`
(corporate SSL-proxy workaround — **local dev only**, never CI/production). A pre-commit
guard at `.githooks/pre-commit` (installed via `git config core.hooksPath .githooks`)
blocks staged `.env` files and key-shaped strings.

The Flutter app ships with a **mock data source** that reads the bundled seed, so it runs
with zero backend. `useFirestore` in `apps/mobile_flutter/lib/core/config.dart` is
**locked false** — flipping it requires the prerequisites listed in that file's doc
comment (flutterfire configure, Firebase.initializeApp, a real FirestoreDataSource).

## Build status

- [x] Phase 0 — monorepo scaffold, Firebase config, emulator, seed data, security rules.
- [x] Phase 1 — Flutter MVP on seed data; Functions (prediction scoring, XP, badges);
      admin portal.
- [x] Phase 2 — real CFBD/CBBD rosters + stats, AI article pipeline (Claude), KHSAA
      link cards in Preps.
- [x] The Vault — 83 real season records + "Eras & Legends" pipeline (Rupp feature is the
      showcase); admin Vault editor MVP (list → editor → live preview → guarded publish).
- [x] UI redesign — Hybrid 3-skin system + 5-tab hub, light + dark, shipped in 3 passes.
- [ ] Phase C+ — Bluegrass Preps depth (Sweet 16 history), All Things Kentucky county
      spotlights, The Porch community. (Ask before starting.)

## Pre-launch checklist (before ANY production deploy)

1. **Secrets:** bind CFBD/CBBD/Anthropic keys to Functions via `defineSecret` /
   `firebase functions:secrets:set` — `.env.local` never deploys.
2. **Admin hosting:** create a real `apps/admin_portal/.env.production` (Firebase web
   config + `VITE_USE_EMULATOR` unset/false) — the build fails safe to production mode
   but needs real project values.
3. **App Check:** enforce on Functions + Firestore (currently not enforced anywhere).
4. **Rate limiting:** add abuse control to callables (none exists).
5. Remove/scope the SSL-proxy workarounds (`strict-ssl=false` .npmrc files, TLS env flag)
   — they must never reach CI or production.
6. Re-run the security review; deploy rules + indexes together (`npm run deploy:rules`).

See `docs/12_MVP_ROADMAP.md` and `docs/prompts/` for the phased build prompts.
