# 15 — The Vault (UK Football & Basketball History Archive)

*The differentiator. A living history of Kentucky football & men's basketball — structured
data where it's reliable, narrative features where it isn't. Last updated 2026-06-16.*

## Two modes (recap)
1. **Structured data — the season spine + modern detail.** Browse every season; see records,
   and (in the modern era) team stats and rosters.
2. **Eras & Legends — narrative features.** The deep history (Rupp era, early titles, pre-data
   players) told as AI-drafted, source-grounded, Chris-edited feature articles.

## What the data actually supports (probed live, 2026-06-16)
| Data | Football (CFBD) | Basketball (CBBD) |
|---|---|---|
| **Season records** (W‑L, conf) | back to **≥1950** ✓ | back to **≥1985** ✓ |
| **Team season stats** | rich modern; sparse pre‑~2000 (1985 = 1 stat, 2025 = 63) | basic team-season fields |
| **Games** | modern + historical | from **~2003** |
| **Rosters** | from **~2004** | modern |
| **Player season stats** | from **~2004** | modern-only (2003 = none) |

**Implication:** the **records timeline is a deep spine** (decades). Granular **stats + player
data are a *modern* database** (~2004→ football, ~2008→ basketball). Everything older — and the
Rupp era especially — is **Legends feature territory**, which is the better way to tell it anyway.

> Want player-level depth before ~2004? That needs sources beyond CFBD/CBBD (sports-reference,
> official UK record books, archives). We can layer those in later — but review each source's
> terms first and **never fabricate** to fill a gap; a gap becomes a feature, not invented data.

## Data model
- **`vault_seasons`** *(the spine — built now):* one doc per team-season.
  `{ id, sport, season, seasonLabel, conference, wins, losses, ties?, conferenceRecord,
     postseason?, source, confidence:"official", updatedAt }`
- **`vault_team_stats`** *(modern enrichment, later):* per-season stat lines where the API has them.
- **`vault_players`** / **`vault_player_seasons`** *(modern, ~2004→, later):* career & season lines.
- **`vault_coaches`** *(later):* coaches by era (the through-line of UK history).
- **`vault_legends`** *(the feature library):* narrative articles. Reuse the existing article
  pipeline with `type: "legend" | "era"` — AI drafts from sourced facts, Chris edits + signs off.

## The Vault screen (app)
- **Sport toggle** (Football / Basketball) → a **season-by-season timeline** (newest first):
  each row = season, record, conference finish, postseason. Tap a season → detail (record +
  modern stats/roster where available).
- **Eras & Legends** rail — the feature articles (Rupp first), with AI-drafted + Chris's-voice byline.
- **Search / jump-to-year.** Milestone markers (championships, title-era banners).

## Editorial workflow (the moat)
AI researches & drafts a Legends piece **from sourced facts only** → it lands in the admin
portal as a draft → Chris verifies, sharpens, adds his take → publish. Same grounding rule as
the gameday articles: every claim traces to a real source; nothing is invented.

## Build plan
1. **Records spine** *(this step):* pull real UK FB (1985→) + BB (1985→) season records →
   `seed_data/vault_seasons.json`. (Records exist deeper than 1985 for football — easy to extend.)
2. **Vault screen:** the season timeline + Eras rail, reading the vault data (mock-first).
3. **Legends pipeline + first Rupp piece:** extend the article generator for `type: legend`,
   ground it in sourced facts, draft the Adolph Rupp era feature, Chris edits.
4. **Modern enrichment:** layer team stats + rosters/player stats (~2004→) onto recent seasons.
5. **Deepen + broaden:** additional sources for pre-2004 player data; coaches; extend football
   records pre-1985; then women's basketball and the rest.
