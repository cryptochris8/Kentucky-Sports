# 01 — Research Evaluation and Market Opportunity

## Executive summary

The existing sports app landscape creates a clear opening for Chris's app.

Most sports apps fall into one of four buckets:

1. **Official school/team apps**
   - Good for schedules, tickets, rosters, notifications, broadcasts, and official news.
   - Usually not playful, not deep with analytics, and not highly community-driven.
2. **Media/community sites**
   - KSR/On3, 247Sports, Rivals, A Sea of Blue, and similar sites are strong on news, recruiting, boards, and insider content.
   - They are usually content-first, not tool-first. Their stats experience is not usually the main event.
3. **National scores apps**
   - ESPN, theScore, Yahoo Sports, CBS Sports, and similar products cover scores, alerts, stats, news, video, and favorite teams across many sports.
   - They are broad, not Kentucky-first.
4. **High school/team management apps**
   - MaxPreps, GameChanger, ScoreStream, Hudl, NFHS, GoFan, and KHSAA tools serve high school scores, stats, video, ticketing, or team workflows.
   - They are fragmented and generally not tied into the Kentucky-to-UK fan storyline.

The opportunity is to create a Kentucky-centered app that combines:

- beautiful statistics,
- simple fan explanations,
- gamified predictions,
- fun badges/cards,
- recruiting/pipeline awareness,
- high school/local coverage,
- Pregame-style venue and watch-party features,
- and a community layer without trying to become a traditional message-board site.

## What competitors already do well

### KSR / On3

KSR/On3 already owns a lot of Kentucky fan attention. Its public site structure includes KSR+, KSBoard, football and basketball news, rosters, schedules, transfer portal pages, recruiting commitments, player rankings, industry comparison, offers, visits, Recruiting Prediction Machine, NIL, podcasts, and app links.

Implication:
- Do not try to beat KSR at insider written reporting.
- Build companion utility: stats, dashboards, prediction games, fan scoring, explainers, push alerts, local/high-school pipeline.

### Official college athletics apps

Official apps commonly include:
- scores,
- schedules,
- rosters,
- tickets,
- news,
- notifications,
- live audio/video links,
- venue/fan guides,
- rewards/check-ins.

A recent Northwood Athletics app example shows the standard modern college-app bundle plus a rewards program where fans check in at events for points and redeem prizes/discounts.

Implication:
- Official app features are table stakes, not differentiation.
- The fan rewards/check-in model is worth adapting, especially with Pregame venues/watch parties.

### CollegeFootballData and CollegeBasketballData

CollegeFootballData supports structured football data, exporters, team metrics, SP+, win probability, player efficiency, predicted points, API docs, TypeScript/Python libraries, and tiered API access. Tiers include historical data, team stats, player stats, recruiting data, advanced metrics, live scoreboard, live play-by-play, and GraphQL at higher levels.

CollegeBasketballData supports basketball API access, exporters, team metrics, shooting profiles, adjusted ratings, raw data exports, and daily prediction contests.

Implication:
- These are the best early data sources for a stats-heavy MVP.
- Use server-side caching through Cloud Functions, not direct mobile API calls.

### KHSAA

KHSAA is the official Kentucky high school sports body. Its site includes school directory, sports pages, schedules/scores, statistics and stat leaders, statistical records, RPI info and data, tickets, NFHS webcast links, and multi-year stat leader pages for football, basketball, baseball, softball, volleyball, soccer, lacrosse, and more.

Implication:
- Kentucky high school data is a real differentiator.
- Start with link-outs, admin-entered data, CSV imports, and respectful data partnerships. Avoid scraping until terms/permission are clear.

### MaxPreps and GameChanger

MaxPreps is a high school sports database across many sports. GameChanger is a local/team sports app pattern built around free scorekeeping for admins, live scoring, stats, video streaming, recap stories, and paid premium fan content.

Implication:
- There is demand for high school sports data, but data quality depends on team/admin participation.
- A Kentucky-only high school module can begin as a curated layer instead of a nationwide database.

### ESPN, Yahoo, theScore

Broad apps emphasize scores, alerts, news, stats, video, favorites, fantasy, and personalized feeds. ESPN's newer app direction includes vertical short-form feeds and AI-personalized daily summaries. Yahoo's fantasy redesign shows how fantasy, news, and scores can live together in one repeated-use mobile experience. theScore is known for mobile-first real-time scores/news/stats/favorites.

Implication:
- The app should feel modern and snackable, not like a static database.
- Use a "Pulse" home screen: today's Kentucky storylines, stat cards, predictions, streaks, and short posts.

## Gap analysis

| User need | Existing options | Gap |
|---|---|---|
| Kentucky-only stats dashboard | ESPN/theScore have broad stats; KSR is news-first | No polished Kentucky-first analytics playground |
| Fun fan engagement | Message boards, social media, fantasy apps | No lightweight Kentucky fan XP/streak/prediction game |
| High school-to-UK pipeline | KHSAA, MaxPreps, On3 recruiting | Fragmented across sites |
| Pregame/watch-party layer | Pregame concept exists separately | Could tie Kentucky fandom to venues and local watch parties |
| Daily app habit | KSR news feed, ESPN alerts | App can blend news links + stat cards + trivia + predictions |
| Casual fan explanations | Analytics sites are data-heavy | Explain stats in simple fan language |
| Collectibles/cards | Fantasy/sports cards exist separately | Digital badges/cards around games, players, moments, rivalries |

## Recommended positioning

**Bluegrass Gameday is not another news app.**  
It is a Kentucky fan command center:

- "What matters today?"
- "How do we match up?"
- "Who is trending?"
- "What should I watch?"
- "Can I beat other fans with predictions?"
- "Which high school/local players are part of the Bluegrass pipeline?"
- "Where is everyone watching?"

## Must-have differentiators

1. **Stats Lab**
   - Kentucky-first dashboards for football and basketball.
   - Basic and advanced stats shown with plain-English explanations.
2. **Gameday HQ**
   - Matchup card, win probability, keys to the game, player spotlights, fan confidence, venue/watch-party tie-in.
3. **Fan Prediction Game**
   - Picks, score predictions, player prop-style non-betting questions, streaks, XP, leaderboards.
4. **Bluegrass Pipeline**
   - Kentucky high school stats, schedules, local player spotlights, recruiting interest, school pages.
5. **Collectible Fan Cards**
   - Digital badges/cards for game attendance/check-ins, prediction streaks, rivalry wins, historical trivia, and season milestones.
6. **Community Pulse**
   - Polls, comments, hot takes, moderated fan posts, and a daily pulse meter.
7. **Pregame Integration**
   - Later: watch parties, venues, distance-to-venue, local sponsors, fan check-ins, rewards.

## MVP thesis

The MVP should prove that fans want a Kentucky-specific daily app for stats and interaction. It does not need every sport or live play-by-play immediately.

The most valuable first demo is:

- Home screen with live Kentucky sports pulse
- Football and basketball team pages
- Gameday matchup dashboard
- Stats Lab
- Prediction questions
- XP/badges
- Recruiting/high-school teaser
- Admin portal to manage content and seed data
