# 08 — High School, Recruiting, Transfer Portal, and NIL

## Strategy

This app can stand out by connecting Kentucky college fandom with Kentucky high school/local sports in a tasteful, safe way.

The goal is not to exploit high school athletes. The goal is to celebrate Kentucky sports culture and help fans follow the local pipeline.

## High school module name

Recommended: **Bluegrass Pipeline**

## MVP high school features

1. School pages
   - name
   - city
   - sports
   - schedule links
   - stats links
   - recent results if admin-entered
   - follow button
2. Sport pages
   - football
   - boys basketball
   - girls basketball
   - baseball/softball later
3. Stats leaders
   - link to KHSAA official stat leader pages
   - optional admin-imported CSV with source and date
4. Friday night scoreboard
   - admin-entered or approved source
   - community-submitted score reports with moderation
5. Positive spotlight cards
   - team milestones
   - state tournament stories
   - alumni updates
6. Follow local schools
   - get notifications when official links/cards are updated

## KHSAA integration

KHSAA has official pages for schedules/scores, stats leaders, statistical records, RPI, tickets, and NFHS links.

MVP implementation:
- provide official link cards
- use admin curation
- create CSV import template for public/permissioned data
- store source URL and import timestamp
- clearly label data as official, partner, admin-entered, or fan-submitted

Do not scrape KHSAA until terms are reviewed and permission is obtained.

## Recruiting module

### Features
- Recruit profile cards
- Commitments list
- Offer tracker
- Transfer portal tracker
- Kentucky targets
- In-state prospects
- visit calendar
- source links
- fan reaction/polls
- prediction questions, but avoid implying insider certainty

### Data fields
- name
- class year
- sport
- position
- height/weight
- school
- hometown/state
- stars/rating, if licensed/public and sourced
- offer status
- visit status
- commit status
- source links
- last updated

### Source rule
Never copy On3/KSR/247/Rivals paywalled content. Only link to the source and use public metadata that is allowed.

## Transfer portal

Transfer portal is important for modern Kentucky basketball and football.

MVP:
- admin-managed transfer board
- statuses:
  - rumored/linked
  - offered/contacted
  - visiting
  - committed
  - signed/enrolled
  - no longer target
- source links
- confidence labels:
  - confirmed by public source
  - reported by media
  - fan rumor/unverified
- fan poll: "Want this player?"

## NIL features

### MVP
- NIL news link cards
- player profile field for public NIL links only
- sponsor directory for local businesses
- educational explainers

### Phase 2
- sponsor spotlight marketplace
- local deal discovery
- athlete-approved profile pages
- campaign tracking

### Legal caution
NIL, athlete likeness, and collectives are rights-sensitive. Do not monetize player likenesses, cards, or sponsored player features without contracts/permission.

## Minors safety

Because high school sports may include minors:

- No direct messaging.
- No private contact features.
- No sensitive personal data.
- No exact home addresses.
- Do not publish phone/email unless official school contact.
- Moderate comments.
- Remove inappropriate content quickly.
- Use school/team-level spotlight first, individual high-school athlete spotlights only with public source and moderation.
- Follow app store youth safety guidance.

## Bluegrass Pipeline roadmap

### Phase 1
- school follow pages
- KHSAA link cards
- admin school profiles
- basic statewide high school feed

### Phase 2
- local scoreboard
- team pages by sport
- CSV importer
- school admin verification
- local sponsor cards

### Phase 3
- coach/team stat submission
- KHSAA/local media partnerships
- recruiting path tools
- alumni tracker
- high school championship mode
