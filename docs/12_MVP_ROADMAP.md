# 12 — MVP Roadmap

## Phase 0 — Foundation

Goal: create the project skeleton and developer workflow.

Build:
- monorepo
- Flutter app scaffold
- React admin scaffold
- Firebase Functions scaffold
- Firebase emulator config
- Firestore rules draft
- sample seed data
- shared models
- app theme
- routing
- CI/check scripts

Exit criteria:
- app runs locally
- admin portal runs locally
- functions compile
- seed data can load into emulator
- tests run

## Phase 1 — MVP App

Goal: functional demo with mock/seed data.

Build:
- onboarding
- Pulse home
- team pages for football and men's basketball
- schedule
- game detail
- Gameday HQ
- Stats Lab basic cards
- Prediction Center
- XP/badges
- profile
- admin CMS for games/polls/predictions/news cards
- Firestore real data reads/writes
- security rules tested

Exit criteria:
- user can sign in/guest
- user can view next Kentucky game
- user can make predictions
- prediction locks and scores via function
- user earns XP/badge
- admin can add content
- app works with Firebase emulator and dev Firebase

## Phase 2 — Real data integrations

Goal: move beyond mock data.

Build:
- CFBD football sync
- CBBD basketball sync
- schedule/game imports
- team stats imports
- player stats imports
- stat explanations
- matchup model
- sync health dashboard
- KHSAA high school link cards
- high school school pages
- news link CMS

Exit criteria:
- nightly sync works
- stats update automatically
- data source attribution shown
- admin can trigger sync
- error monitoring in place

## Phase 3 — Community and local expansion

Goal: make it feel alive.

Build:
- game threads
- reactions
- fan posts
- report/moderation queue
- high school scoreboard import/manual reports
- city/school leaderboards
- shareable stat cards
- notification campaigns
- premium entitlement structure

Exit criteria:
- moderation tools work
- notifications work
- share cards look good
- fan engagement loops are measurable

## Phase 4 — Pregame-style venue/watch party

Goal: connect Kentucky fandom to real-world gatherings.

Build:
- venue pages
- map/list
- watch-party events
- check-ins
- venue rewards
- sponsor portal
- Stripe billing
- analytics dashboard
- push "watch party near you"

Exit criteria:
- venue can create/manage event
- fan can check in
- sponsor card appears
- billing flow works in test mode

## Phase 5 — Premium stats and AI

Goal: monetize and deepen value.

Build:
- Plus subscription
- advanced Stats Lab
- AI matchup report
- historical comparisons
- custom alerts
- premium badges/cosmetics
- saved stat boards

Exit criteria:
- RevenueCat purchase flow works
- entitlement gates work
- premium report sources only licensed/stored data
- no paywalled copied content

## Suggested first two weeks

### Day 1-2
- scaffold monorepo
- Flutter app shell
- Firebase emulator
- data models

### Day 3-4
- seed data
- Pulse home
- team pages
- schedule

### Day 5-6
- Gameday HQ
- Stats Lab cards
- explanations

### Day 7-8
- Predictions
- XP
- badges

### Day 9-10
- React admin portal
- manage games/polls/predictions

### Day 11-12
- Cloud Functions for prediction scoring and seed sync

### Day 13-14
- polish UI
- tests
- README
- prepare TestFlight path
