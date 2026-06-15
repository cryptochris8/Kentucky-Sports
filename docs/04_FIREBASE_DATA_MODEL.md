# 04 — Firebase Data Model

## Design strategy

Use Firestore as the primary app database. Store normalized source data where useful, but create denormalized read models for mobile screens.

## Core collections

### users/{userId}

```json
{
  "displayName": "Chris",
  "photoUrl": null,
  "email": "user@example.com",
  "favoriteCollegeTeams": ["kentucky"],
  "favoriteSports": ["football", "mens_basketball"],
  "favoriteHighSchools": [],
  "homeState": "KY",
  "role": "user",
  "xp": 1200,
  "level": 4,
  "predictionRecord": {
    "total": 25,
    "correct": 14,
    "streak": 3
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

Roles:
- user
- moderator
- editor
- admin
- sponsor_admin
- venue_admin

### teams/{teamId}

Use IDs:
- `kentucky_football`
- `kentucky_mens_basketball`
- `kentucky_womens_basketball`
- `kentucky_baseball`
- `kentucky_volleyball`

```json
{
  "school": "Kentucky",
  "teamName": "Kentucky",
  "nickname": "Wildcats",
  "sport": "football",
  "division": "NCAA",
  "conference": "SEC",
  "primaryColor": "#1E5AA8",
  "isOfficialLicensed": false,
  "sourceIds": {
    "cfbdTeam": "Kentucky",
    "cbbdTeam": "Kentucky"
  },
  "active": true
}
```

### seasons/{seasonId}

```json
{
  "year": 2026,
  "sport": "football",
  "status": "preseason",
  "startsAt": "timestamp",
  "endsAt": "timestamp"
}
```

### games/{gameId}

```json
{
  "season": 2026,
  "sport": "football",
  "homeTeamId": "kentucky_football",
  "awayTeamId": "louisville_football",
  "opponentName": "Louisville",
  "startTime": "timestamp",
  "venue": "Kroger Field",
  "city": "Lexington",
  "state": "KY",
  "status": "scheduled",
  "homeScore": null,
  "awayScore": null,
  "broadcast": "TBD",
  "source": "cfbd",
  "sourceGameId": "12345",
  "featured": true,
  "updatedAt": "timestamp"
}
```

### game_summaries/{gameId}

Read model for Gameday HQ.

```json
{
  "gameId": "2026_kentucky_louisville_fb",
  "headline": "Governor's Cup matchup",
  "fanConfidence": 71,
  "winProbability": {
    "kentucky": 0.58,
    "opponent": 0.42,
    "source": "cfbd"
  },
  "teamComparison": {
    "kentucky": {
      "pointsPerGame": 31.2,
      "yardsPerPlay": 6.1,
      "turnoverMargin": 0.4
    },
    "opponent": {
      "pointsPerGame": 28.4,
      "yardsPerPlay": 5.8,
      "turnoverMargin": -0.1
    }
  },
  "keysToGame": [
    "Protect the football",
    "Win explosive plays",
    "Finish red-zone trips"
  ],
  "updatedAt": "timestamp"
}
```

### team_stats/{teamStatId}

```json
{
  "teamId": "kentucky_football",
  "season": 2026,
  "sport": "football",
  "scope": "season",
  "stats": {
    "pointsPerGame": 31.2,
    "yardsPerPlay": 6.1,
    "successRate": 0.44,
    "ppaOffense": 0.21,
    "ppaDefense": 0.11,
    "turnoverMargin": 0.4
  },
  "rankings": {
    "pointsPerGameSEC": 5,
    "yardsPerPlaySEC": 4
  },
  "source": "cfbd",
  "updatedAt": "timestamp"
}
```

### player_profiles/{playerId}

```json
{
  "name": "Player Name",
  "teamId": "kentucky_mens_basketball",
  "sport": "mens_basketball",
  "position": "G",
  "classYear": "SO",
  "height": "6-4",
  "weight": "195",
  "hometown": "Lexington, KY",
  "sourceIds": {},
  "active": true
}
```

### player_stats/{playerStatId}

```json
{
  "playerId": "player_123",
  "teamId": "kentucky_mens_basketball",
  "season": 2026,
  "sport": "mens_basketball",
  "scope": "season",
  "stats": {
    "points": 14.2,
    "rebounds": 4.8,
    "assists": 3.1,
    "effectiveFgPct": 0.552,
    "threePointPct": 0.389
  },
  "source": "cbbd",
  "updatedAt": "timestamp"
}
```

### predictions/{predictionId}

```json
{
  "gameId": "2026_kentucky_louisville_fb",
  "type": "winner",
  "question": "Who wins?",
  "options": [
    {"id": "kentucky", "label": "Kentucky"},
    {"id": "opponent", "label": "Louisville"}
  ],
  "opensAt": "timestamp",
  "closesAt": "timestamp",
  "status": "open",
  "points": 10,
  "createdBy": "adminUserId",
  "createdAt": "timestamp"
}
```

### prediction_entries/{entryId}

```json
{
  "predictionId": "prediction_123",
  "gameId": "game_123",
  "userId": "user_123",
  "selectedOptionId": "kentucky",
  "numericValue": null,
  "locked": true,
  "isCorrect": null,
  "pointsAwarded": 0,
  "createdAt": "timestamp"
}
```

### badges/{badgeId}

```json
{
  "name": "Gameday Regular",
  "description": "Submitted predictions for 5 Kentucky games.",
  "category": "prediction",
  "rarity": "common",
  "assetPath": "badges/gameday_regular.png",
  "criteria": {
    "type": "prediction_count",
    "threshold": 5
  }
}
```

### user_badges/{userBadgeId}

```json
{
  "userId": "user_123",
  "badgeId": "badge_gameday_regular",
  "earnedAt": "timestamp",
  "metadata": {}
}
```

### high_schools/{schoolId}

```json
{
  "name": "Lexington Catholic",
  "city": "Lexington",
  "state": "KY",
  "khsaaId": null,
  "sports": ["football", "basketball"],
  "officialUrl": null,
  "sourceUrls": {
    "khsaa": null,
    "maxpreps": null
  },
  "verified": false,
  "createdAt": "timestamp"
}
```

### high_school_games/{gameId}

```json
{
  "schoolId": "lexington_catholic",
  "sport": "football",
  "season": 2026,
  "opponent": "School Name",
  "startTime": "timestamp",
  "status": "scheduled",
  "schoolScore": null,
  "opponentScore": null,
  "source": "manual",
  "sourceUrl": null
}
```

### recruits/{recruitId}

```json
{
  "name": "Recruit Name",
  "sport": "football",
  "position": "QB",
  "classYear": 2027,
  "highSchoolId": null,
  "homeTown": "Louisville, KY",
  "state": "KY",
  "stars": 4,
  "rating": 0.92,
  "interestLevel": "offered",
  "commitStatus": "uncommitted",
  "committedTo": null,
  "sourceLinks": [],
  "lastUpdatedAt": "timestamp"
}
```

### news_cards/{cardId}

```json
{
  "title": "Kentucky lands transfer target",
  "sourceName": "KSR",
  "url": "https://example.com/story",
  "summary": "Short admin-written summary. Do not copy article text.",
  "sport": "mens_basketball",
  "tags": ["transfer_portal"],
  "publishedAt": "timestamp",
  "featured": true,
  "createdBy": "adminUserId"
}
```

### community_posts/{postId}

```json
{
  "userId": "user_123",
  "title": "What is your score prediction?",
  "body": "Fan post text",
  "sport": "football",
  "gameId": "game_123",
  "status": "visible",
  "reactionCounts": {
    "like": 3,
    "fire": 8
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### polls/{pollId}

```json
{
  "question": "Which player are you most excited to watch?",
  "options": [
    {"id": "a", "label": "Player A", "votes": 10},
    {"id": "b", "label": "Player B", "votes": 7}
  ],
  "sport": "mens_basketball",
  "status": "open",
  "closesAt": "timestamp"
}
```

### app_config/main

```json
{
  "minSupportedVersion": "1.0.0",
  "featureFlags": {
    "highSchool": true,
    "communityPosts": true,
    "premiumStats": false,
    "venues": false
  },
  "maintenanceMode": false
}
```

## Suggested Firestore indexes

- `games`: `sport ASC, startTime ASC`
- `games`: `status ASC, startTime ASC`
- `team_stats`: `teamId ASC, season DESC`
- `player_stats`: `teamId ASC, season DESC, sport ASC`
- `predictions`: `gameId ASC, status ASC, closesAt ASC`
- `prediction_entries`: `userId ASC, gameId ASC`
- `community_posts`: `sport ASC, status ASC, createdAt DESC`
- `news_cards`: `sport ASC, featured DESC, publishedAt DESC`
- `high_school_games`: `schoolId ASC, startTime DESC`
- `recruits`: `sport ASC, classYear ASC, state ASC`

## Security rules concept

- Public read for published teams, games, stats, news cards, polls.
- Authenticated write for prediction entries, reactions, and posts.
- User can update only their own profile.
- Admin/editor roles can create/update CMS content.
- Moderator/admin roles can update post status and moderation actions.
- Only Cloud Functions service account can write imported stats and scored predictions.

## Important rules

- Keep external source API keys in functions config or Secret Manager.
- Never expose source API keys in mobile.
- Never let clients write stat records directly.
- Validate all user-generated content.
- Store minor/high-school data carefully and avoid sensitive personal data.
