# Bluegrass Gameday — Product Vision

*Working name. **Living document** — last updated 2026-06-16. This is the north star that
steers what we build; it will evolve as the vision sharpens.*

## The North Star

**The digital home for Kentucky pride — anchored by the Cats.**

This is not a sports app with Kentucky flavor bolted on. It is a Kentucky-**identity** app
where University of Kentucky Football and Basketball are the front door, and everything a
Kentuckian loves lives inside: the Sweet 16, bourbon, horse country, the coalfields, the
farmlands, hometown and county history. The same fan who argues about the 1996 title team
also has roots in a county with its own story. The app is for that whole person.

> If you're from Kentucky, this is the app that *gets it.*

## Who it's for

- **Big Blue Nation** — die-hard UK football & basketball fans, first.
- **Kentuckians who love the state itself** — its high school hoops lore, its towns and
  counties, its bourbon, horses, and heritage.
- **Chris, as editor-in-chief** — bringing real expertise and voice, especially UK history
  from 1990 to today.

## The Pillars

### 🐾 1. The Cats — the anchor *(built)*
UK Football & Men's Basketball as the core: Gameday HQ, real/live stats, matchup
breakdowns, free-to-play predictions, and a daily article feed. Then the trickle-down —
Women's Basketball, Baseball, Volleyball, Cheer, Rifle — the rest of the Wildcats.

### 📚 2. The Vault — the crown jewel
The complete, living history of UK Football & Basketball, in **two modes**:
- **Structured data — 1985→present:** season-by-season records, teams, players, and stats,
  granular and searchable. (This is the era where reliable, complete data is available.)
- **Eras & Legends — pre-1985:** select feature pieces that tell the deeper story — the
  **Adolph Rupp** era (the Baron of the Bluegrass, whose name is on the arena), the early
  championships, and the figures and games that became myth.

Everything is **grounded in real sources**, AI-drafted, and layered with **Chris's own takes**
(his expertise runs richest from 1985 on). This is the differentiator nobody else has.

### 🏀 3. Bluegrass Preps — Kentucky high school
Kentucky's high school sports culture, with a love letter to **the Sweet 16** state
basketball tournament: its history, legendary teams, players, coaches, and the figures who
became myth — plus a current Friday-night scoreboard and school pages.
*(Safety-first: school/team-level, public sources, strong moderation, no exploiting minors.)*

### 🥃 4. All Things Kentucky — the heritage magazine
The layer that makes it *feel* like Kentucky, not just a scoreboard:
- **Kentucky culture:** bourbon history, the horse farms, KFC, Kentucky-born icons, food,
  music, traditions.
- **The State Itself — county & region spotlights** (rotating weekly/monthly): the story of
  Kentucky's **120 counties** and its great regions — Appalachia & the **Eastern
  Coalfields**, the **Bluegrass**, the **Pennyroyal**, the **Western Coalfield**, and the
  far-western farmlands of the **Jackson Purchase**. Where people are from, what shaped them,
  what makes each place Kentucky.

### 💬 5. The Porch — where Kentuckians talk
The community feel: discussion threads, polls, hot takes, and fan creativity — like a
**design-a-uniform** studio (pick designs/colors, submit, vote). The place Kentucky people
gather to talk teams, sports, and everything else they love.

## The Editorial Engine — AI does the work, Chris brings the soul

The habit-forming heart of the app is a **constant feed of articles** (KSR-style). The model:

1. **AI researches & drafts** from sourced facts — recaps, "On this day in UK history," Vault
   deep-dives, county/region spotlights, stat stories.
2. **Chris edits in the admin portal** — verifies, sharpens, and adds the *take* AI can't
   replicate (his 1990-on expertise).
3. Published to the front-page feed.

That hybrid is the moat: tireless AI research + a real Kentuckian's voice and judgment.

**Cadence / habit loop:**
- *Daily:* the front-page feed (UK takes, recaps, history nuggets).
- *Gameday:* live HQ + predictions.
- *Weekly/Monthly:* the marquee **spotlights** — a county/region, a Vault retrospective, a
  Sweet 16 legend. A reason to return between games.

## Guardrails (non-negotiable)

- **Accuracy is sacred.** History and stats are grounded in real, citable sources — AI never
  invents a title, score, or fact. Chris is the final editor. The whole app earns trust here.
- **Rights & marks:** original branding; no official UK logos/marks or athlete-likeness
  products without permission; link to news, never copy paywalled content.
- **People & minors:** high-school content stays respectful and public-sourced; moderation on
  all community surfaces; no direct messaging.
- **No gambling:** predictions are free-to-play; no betting language.

## Build order (focus first, then trickle down)

1. **Phase A — Make the Cats undeniable** *(in progress):* real data, Gameday, predictions,
   the daily feed.
2. **Phase B — Open The Vault:** the UK FB/BB history archive + AI history pipeline + Chris's
   editorial workflow. *(The differentiator.)*
3. **Phase C — Light up the state:** Bluegrass Preps + Sweet 16 history; the first
   county/region spotlights.
4. **Phase D — All Things Kentucky + The Porch:** bourbon/horses/heritage magazine; community
   + design-a-uniform.
5. **Phase E — Trickle down:** the other UK sports; growth, polish, ship.

Keep the UK core central at every phase — everything else is a tab that lights up once the
core is rock-solid.

## Open decisions (we'll resolve these as we go)

- **Brand (marinating):** "Bluegrass Gameday" is sports-narrow. Leaning toward a play on
  **bourbon barrels + bluegrass + basketball** — candidates: *Barrels & Banners* (bourbon
  barrels + the championship banners in the rafters), *The Three B's* / *Triple B*, *Bluegrass
  & Banners*, *The Bluegrass Almanac*, *Commonwealth ___*. Decide later; check
  domain/trademark + no implied UK affiliation first.
- **The Vault depth:** *decided* — structured data **1985→present**; pre-1985 told as select
  feature pieces (Rupp era, early titles). Open: how fast to fill it in.
- **Editor cadence:** daily writing/editing vs. curating AI drafts a few times a week.
- **Community timing:** is The Porch day-one (for the "Kentuckians talking" feel) or after
  there's an audience?
- **Heritage depth:** research-driven articles vs. lighter "fun facts" to start.
- **Platform & monetization:** iOS / Android / web priority; free vs. premium vs. local
  sponsors (the Pregame venue angle).

## What exists today
A working foundation for Phase A: Flutter app (mock-first), Firebase Functions, React admin
portal, real CFBD/CBBD data sync, the Claude-powered article pipeline, predictions/XP/badges.
See `README.md`, `CLAUDE.md`, and `docs/12_MVP_ROADMAP.md`.
