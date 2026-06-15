# Claude Code Prompt — Real Data Sync

Implement provider adapters for CollegeFootballData and CollegeBasketballData.

Requirements:
- API keys only in Functions secrets/env
- syncCollegeFootballNightly
- syncCollegeBasketballNightly
- syncGamedayScoreboard stub
- normalized DTOs
- Firestore batch writes
- sync_runs logging
- admin manual trigger
- rate-limit/backoff handling
- source/updatedAt on every stat document

Do not call external APIs from Flutter.
Do not implement KHSAA scraping.
