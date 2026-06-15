# 09 — UI/UX Screen Map

## Design direction

The app should feel like:
- Kentucky-first
- fast
- polished
- modern sports broadcast
- fun but not childish
- stats-heavy without being intimidating

Avoid official UK logo/marks unless licensed. Use original bluegrass-inspired design, abstract cat/paw/ball shapes only if legally reviewed, and custom typography/icons.

## Mobile navigation

Recommended bottom nav:

1. Pulse
2. Gameday
3. Stats
4. Pipeline
5. Profile

Community can be reached through Pulse/Gameday initially.

## Screen list

### 1. Onboarding

Purpose:
- collect favorite sports
- optional favorite high school
- notification preferences
- explain independent fan app

Screens:
- Welcome
- Pick sports: football, men's basketball, women's basketball, baseball, volleyball
- Pick notification style
- Optional sign in / continue as guest
- Legal/disclaimer

### 2. Pulse Home

Components:
- top bar: greeting, XP level
- next game countdown
- daily pulse card
- stat of the day
- prediction prompt
- poll
- trending news link cards
- fan confidence meter
- badge progress

### 3. Gameday HQ

States:
- pregame
- live
- halftime
- final/postgame
- offseason/no game

Pregame components:
- matchup hero card
- countdown
- team comparison
- keys to the game
- player to watch
- fan predictions
- venue/watch-party teaser

Live components:
- score
- key stat pulse
- fan reactions
- live predictions if allowed
- timeline, if data available

Postgame:
- final score
- prediction results
- badge awards
- stat recap
- top fan leaderboard

### 4. Team Page

Tabs:
- overview
- schedule
- roster
- stats
- news links
- history

### 5. Stats Lab

Sections:
- Compare Kentucky vs opponent
- Football advanced stats
- Basketball Four Factors
- Player cards
- Trends
- Rankings
- Stat explainers

UI patterns:
- metric cards
- percentile bars
- "What this means" tooltip
- trend arrows
- compare table
- shareable card

### 6. Player Profile

- bio
- season stats
- game log
- trend card
- related news links
- badges/milestones, if college player rights permit

### 7. Prediction Center

- open predictions
- locked predictions
- results
- leaderboard
- streaks
- prediction history

### 8. Bluegrass Pipeline

- followed schools
- statewide high school feed
- KHSAA links
- school pages
- local player/recruit cards
- Friday night scoreboard
- Sweet 16 / state tournament mode

### 9. Recruiting Radar

- commitments
- offers
- visits
- transfer portal
- in-state prospects
- source links
- fan poll/reaction

### 10. Community Pulse

- game thread
- polls
- reactions
- fan posts
- report button
- moderation status for user's own posts

### 11. Profile

- user info
- XP level
- badges/cards
- prediction record
- followed teams/schools
- notification settings
- subscription/Plus status

### 12. Settings

- account
- notifications
- privacy
- content preferences
- legal
- app version

## Admin portal screens

1. Dashboard
   - sync health
   - active games
   - content queue
   - moderation queue
   - prediction activity

2. Games manager
   - create/edit games
   - feature games
   - override display data

3. Team/player manager
   - profiles
   - roster
   - stats source mapping

4. Prediction manager
   - create questions
   - close questions
   - score/override results

5. CMS/news cards
   - add link cards
   - feature cards
   - expire old content

6. High school manager
   - schools
   - schedules
   - CSV imports
   - source links
   - verification status

7. Recruiting manager
   - recruits
   - transfer board
   - source links

8. Moderation
   - reported posts
   - hidden posts
   - user warnings
   - bans

9. Sponsors/venues
   - phase 2
   - venue profile
   - watch party
   - coupon/reward
   - billing status

## Visual concepts

### Home hero
"Tonight in Big Blue"
- game/time
- confidence meter
- one stat
- one prediction button

### Stats card
"Kentucky has a 72nd percentile Shot Quality"
- value
- rank
- explanation
- trend arrow
- source

### Prediction card
"How many threes will Kentucky hit?"
- quick tap options
- XP reward
- closes in 2h

### Collectible badge card
- abstract blue/gold/silver card
- rarity label
- earned date
- share button

## Accessibility

- high contrast mode
- large tap targets
- text scaling
- avoid color-only meaning
- screen reader labels
- reduced motion option

## App Store-safe language

Use:
- prediction
- pick
- confidence
- challenge
- points
- XP

Avoid:
- bet
- wager
- odds
- sportsbook
- parlay
- gambling
