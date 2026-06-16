# 14 — Data Persistence & AI Articles (Firestore as System of Record)

This is the Bluegrass Gameday version of the pattern proven in Chris's **Pregame college
football** and **Pregame 2026 World Cup** apps: the mobile client never calls a sports API
or an LLM directly. Cloud Functions and offline generators fetch/produce data, normalize
it, and persist it to **Firestore as the system of record**. All users read the same
documents. History and AI articles accumulate permanently.

## Why

- **Cost & rate limits:** one server-side fetch serves every user, instead of N API calls.
- **Speed & offline:** clients read fast denormalized Firestore docs (bundled snapshot first,
  Firestore live second) — works with no network.
- **No client secrets:** CFBD/CBBD and Claude keys live only in Functions env / Secret Manager.
- **Permanent archive:** season-keyed docs are never overwritten, so 2025, 2026, 2027 … stay
  as a growing history/statistics store. AI articles are generated once and kept.

## Three layers

### 1. Ingestion (stats, schedules, history)
Cloud Functions (`functions/src/ingest/*`) pull from CollegeFootballData / CollegeBasketballData,
normalize to the doc shapes in `04_FIREBASE_DATA_MODEL.md`, and **merge-write** into
season-keyed collections. Each write carries `source`, `updatedAt`, `confidence`, and a
`lastFetched`/freshness marker; a `sync_runs` doc records the run. Raw provider snapshots may
be archived to Cloud Storage (`sync_snapshots/`) for backfill/debug. A staleness check skips
the provider call when the cached data is fresh (Pregame uses a 24h window for schedules; live
scoreboard polls more often only on game days). **Clients never call these providers.**

### 2. AI journalistic articles (the agent-written content)
An offline/admin generator (`scripts/generate_articles.ts`) assembles the **already-stored
Firestore data** for a game (team stats, matchup, players, history, recruiting) into a prompt,
calls Claude, validates, and writes one document to the `articles` collection. Generated once
per game, deduped by id, kept indefinitely, read by all clients.

- **SDK/model:** `@anthropic-ai/sdk`, `client.messages.parse()` with a Zod schema for guaranteed
  JSON. Model from `ANTHROPIC_MODEL` env, default **`claude-opus-4-8`** (set
  `claude-sonnet-4-6` to cut cost on large batches). Adaptive thinking, `effort: medium`.
- **Prompt caching:** the journalistic system prompt + style guide is a cached prefix, so a
  whole batch of games reuses it; per-game stats go in the user turn.
- **Guardrails (enforced in the system prompt):** every number must come from the provided
  data — *never invent stats*; independent-fan voice; **no betting language**; no official UK
  marks; cite the source docs used. (Mirrors Pregame's "every statistic must come from the data
  provided" rule.)
- **Key-gated scaffold:** with no `ANTHROPIC_API_KEY`, the generator writes a deterministic
  **templated** article from the same data so the pipeline + read path work end-to-end without
  spend. Real generation switches on the moment the key is present.

### 3. Client read path
Flutter reads `articles` (and stats) from a bundled seed snapshot first, then Firestore live —
never the providers or Claude. Articles render in **Gameday HQ** (preview/recap) and **Stats
Lab** (stat story), with AI attribution + source/updated/confidence labels.

## `articles` document shape

```jsonc
articles/{articleId}: {
  "type": "preview" | "recap" | "stat_story",
  "gameId": "fb_2026_youngstown",
  "sport": "football",
  "status": "published",            // draft | published | hidden
  "headline": "…", "subheadline": "…",
  "openingNarrative": "…",
  "tacticalBreakdown": { "title": "…", "narrative": "…" },
  "byTheNumbers": { "title": "By the Numbers", "items": ["…"] },
  "playerSpotlights": [ { "playerId": "…", "name": "…", "narrative": "…", "statline": "…" } ],
  "theVerdict": { "title": "…", "prediction": "…", "confidence": 78, "narrative": "…" },
  "closingLine": "…",
  "sources": ["seed_demo:team_stats/…"],   // provenance — which stored docs fed the model
  "model": "claude-opus-4-8",              // or "seed_template" for the no-key fallback
  "generatedAt": "<ts>", "publishedAt": "<ts>", "confidence": "demo" | "official"
}
```

Indexes: `(sport, status, publishedAt DESC)` and `(gameId, generatedAt DESC)` —
see `firebase/firestore.indexes.json`. Rules: public read; editor/Functions write only —
see `firebase/firestore.rules`.

## To go live
Drop free keys into Functions env (never the client): `CFBD_API_KEY`, `CBBD_API_KEY`
(collegefootballdata.com / collegebasketballdata.com) and `ANTHROPIC_API_KEY`. Then enable the
scheduled sync functions and run `scripts/generate_articles.ts`. See
`prompts/05_REAL_DATA_SYNC_PROMPT.md` and `13_TESTING_DEPLOYMENT.md`.
