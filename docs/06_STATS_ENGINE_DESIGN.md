# 06 — Stats Engine Design

## Product goal

Make sports analytics feel fun and understandable for normal Kentucky fans while still satisfying stat-heavy users.

## Stats engine modules

```text
packages/stats_engine/
  football/
    basic_metrics.dart / ts
    advanced_metrics.dart / ts
    matchup_model.dart / ts
  basketball/
    four_factors.dart / ts
    adjusted_metrics.dart / ts
    shot_profile.dart / ts
    matchup_model.dart / ts
  shared/
    percentile_rank.dart / ts
    trend_detector.dart / ts
    explain_metric.dart / ts
```

The TypeScript version runs in Cloud Functions. Dart models/rendering helpers run in Flutter.

## Football metrics

### Basic
- Record
- Points per game
- Points allowed per game
- Yards per game
- Yards per play
- Passing yards/game
- Rushing yards/game
- Third-down conversion
- Red-zone scoring
- Turnover margin
- Sacks
- Explosive plays

### Advanced
Use provider data when available:
- EPA
- PPA
- Success rate
- Explosiveness
- Field position efficiency
- Win probability
- Opponent-adjusted metrics
- SP+ trend

### Fan-friendly labels
- "Drive Finisher" = red-zone efficiency + points per scoring opportunity
- "Big Play Spark" = explosive play rate
- "Chaos Factor" = sacks + turnovers forced + havoc
- "Ball Security Grade" = turnovers lost + fumbles + interceptions
- "Grit Index" = rushing success + third/fourth-down conversion

## Basketball metrics

### Basic
- Record
- Points per game
- Points allowed per game
- FG%
- 3P%
- FT%
- Rebounds
- Assists
- Turnovers
- Blocks/steals

### Advanced
- Offensive rating
- Defensive rating
- Adjusted offensive rating
- Adjusted defensive rating
- Adjusted net rating
- Pace/tempo
- Effective field goal %
- Turnover rate
- Offensive rebound rate
- Free throw rate
- Shot profile:
  - rim attempts
  - midrange attempts
  - three-point attempts
  - catch-and-shoot
  - transition
- Assist rate
- Bench points
- Close-game performance

### Fan-friendly labels
- "Shot Quality" = eFG% + rim/3PA profile
- "Glass Work" = offensive + defensive rebound rate
- "Tempo Meter" = possessions per game
- "Clutch Meter" = close-game net rating
- "Paint Pressure" = rim attempts + free throw rate
- "Ball Movement" = assist rate + assist/turnover

## Matchup dashboard

Each upcoming game should have:

1. **Big matchup score**
   - Kentucky edge, Toss-up, Opponent edge
2. **Three keys**
   - Derived from statistical mismatches
3. **Player to watch**
   - Player with rising trend or matchup relevance
4. **Concern meter**
   - Data-driven risk areas
5. **Fan confidence**
   - Poll/prediction aggregate
6. **Stat story**
   - One paragraph generated from data

## Trend detection

Use rolling windows:
- last 3 games
- last 5 games
- season
- conference-only
- home/away
- versus top-25 if available

Trend examples:
- "Kentucky's three-point rate is up 8% over the last 5 games."
- "Turnover margin has improved in three straight football games."
- "Opponent allows explosive rush plays at a high rate."

## Percentile rankings

For each metric:
- team percentile nationally
- team percentile in SEC
- trend percentile over last N games

Output:
```json
{
  "metric": "effectiveFgPct",
  "value": 0.552,
  "nationalPercentile": 82,
  "secRank": 4,
  "label": "Excellent",
  "explanation": "Kentucky is shooting efficiently compared with most teams."
}
```

## Prediction scoring

### Free-to-play points

| Question type | Points |
|---|---:|
| Pick winner | 10 |
| Score margin bucket | 15 |
| Exact score bonus | 50 |
| Leading scorer/rusher/pass yards leader | 15 |
| Team stat over/under style, non-betting | 10 |
| Upset pick | 20 |
| Streak bonus | 5-25 |

Do not use gambling language like "bet", "wager", "odds", or "parlay" in the UI. Use "prediction", "pick", "confidence", and "fan challenge."

## AI-generated stat explanations

Use a controlled template first, not open-ended AI.

Example template:

```text
Kentucky's biggest statistical edge is {metricName}. The Cats rank {rank} in the SEC while {opponent} ranks {opponentRank}. In plain English, this means {plainMeaning}. Watch for {playerOrUnit} to be important.
```

Phase 2 can use OpenAI or Gemini in Cloud Functions with strict prompts and source data only.

## High school stats

MVP:
- show KHSAA stat leader links
- admin-imported CSV leaders
- school/team schedules manually added
- verified source links

Phase 2:
- school admin portal
- coach/team stat submission
- parent/community score reports with moderation
- partnership with KHSAA/local outlets

## Avoid bad statistics

- Do not invent data.
- Every stat card needs `source`, `updatedAt`, and `confidence`.
- Mark estimated/fan-submitted data clearly.
- Do not blend official and fan-submitted stats without labeling.
