# Bluegrass Gameday — Admin Portal

React + Vite + TypeScript + Tailwind portal for editors, moderators, and admins.
Deployed to Firebase Hosting (`firebase.json` serves `dist/`).

## Local development

```bash
# from the repo root, in another terminal:
firebase emulators:start        # Auth :9099  Firestore :8080
npm run seed                    # load seed data into the emulator

# then here:
npm install
npm run dev
```

`.env.development` (gitignored — copy from `.env.example`) sets
`VITE_USE_EMULATOR=true`. Emulator connections are **opt-in**: the app only
talks to localhost when that flag is exactly `'true'`; any other value (or a
production build without it) targets the real Firebase project.

## Production builds

A real `.env.production` is **required** before `npm run build` for deploy —
copy `.env.production.example` and fill in the actual Firebase web config.
Those values are public identifiers, not secrets. **App Check (reCAPTCHA
Enterprise) is planned pre-launch and not yet wired** — it must be added to
`src/lib/firebase.ts` as part of the first real deploy
(see `docs/13_TESTING_DEPLOYMENT.md`).

## Scripts

```bash
npm run dev       # Vite dev server
npm run build     # tsc -b + vite build
npm test          # vitest (vaultGuards publish-gate suite)
npm run lint      # eslint
```

## House rules enforced in code

- **No betting language** reaches published content: `src/data/vaultGuards.ts`
  blocks bet/wager/parlay/sportsbook/… (inflection-aware) and warns on
  standalone "odds"/"spread". Covered by `vaultGuards.test.ts`.
- **Provenance is preserved**: game updates never overwrite `source` or null
  out real final scores; edits record `lastEditedBy`.
- **Moderation is audited**: every status change writes a `moderation_actions`
  doc in the same batch.
- All `datetime-local` inputs are converted to Firestore Timestamps in
  `src/data/firestore.ts` (local-timezone interpretation, hinted in the UI).
