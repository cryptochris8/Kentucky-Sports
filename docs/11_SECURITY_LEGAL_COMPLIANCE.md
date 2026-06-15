# 11 — Security, Legal, Privacy, and Compliance

## Branding and trademark

The app should not use:
- official University of Kentucky logos
- official mascot art
- official athletics marks
- official uniform artwork
- copyrighted photos
- exact broadcast graphics
- school marks from high schools without permission

Use:
- original brand name
- original app icon
- abstract bluegrass/Kentucky-inspired graphics
- generic basketball/football iconography
- independent fan app disclaimer

Example disclaimer:
```text
Bluegrass Gameday is an independent fan and statistics app. It is not affiliated with, endorsed by, or sponsored by the University of Kentucky, UK Athletics, the NCAA, SEC, KHSAA, or any school unless otherwise stated.
```

## Data licensing

Use only:
- licensed APIs
- free/public data with terms that allow use
- admin-entered original summaries
- user-generated content with terms of service
- allowed RSS/link cards
- partner feeds

Do not:
- scrape paywalled content
- copy article bodies
- store copyrighted photos without license
- sell player likeness cards without rights
- imply official partnerships

## Sports betting

This app is not a gambling app.

Rules:
- predictions are free-to-play
- no cash prizes tied to picks
- no odds, lines, wagers, parlays, sportsbook language
- no real-money betting integrations in MVP
- no underage gambling adjacent UX

Use:
- pick
- prediction
- confidence
- challenge
- points
- XP
- leaderboard

## Minors and high school sports

Because high school sports can involve minors:

- No direct messages.
- No private contact forms.
- No athlete phone/email.
- No home addresses.
- No unmoderated comments on minor profiles.
- Use school/team pages first.
- Individual spotlights only from public/approved sources.
- Remove inappropriate content quickly.
- Provide reporting tools.
- Have a clear moderation policy.

## User-generated content

Add:
- report button
- moderation queue
- profanity filtering
- spam detection
- role-based moderation
- audit log
- user warning/suspension/ban
- blocked words list
- optional AI moderation in Cloud Functions later

## Privacy

Collect minimum data:
- email/auth provider
- display name
- favorite teams/sports
- optional home city/state
- prediction activity
- XP/badges
- notification preferences

Avoid:
- collecting age unless necessary
- collecting precise location unless check-in feature requires it
- storing location history
- selling user data

For venue check-ins later:
- ask permission
- check in only at event/venue time
- store approximate or venue-specific check-in, not raw continuous GPS

## Firestore security rules

Principles:
- Users can only modify their own user document.
- Users can create prediction entries only for themselves.
- Users cannot edit locked predictions.
- Only admins/editors can create games/news/polls/predictions.
- Only Cloud Functions can write stat imports and scoring results.
- Moderators can hide content but not grant themselves admin.
- Use custom claims for roles.

## App Check

Use Firebase App Check:
- iOS DeviceCheck/App Attest
- Android Play Integrity
- web reCAPTCHA Enterprise for admin portal

## Secrets

Store:
- CFBD_API_KEY
- CBBD_API_KEY
- STRIPE_SECRET
- REVENUECAT_WEBHOOK_SECRET
- OPENAI/GEMINI keys, if used later

Never commit:
- `.env`
- `GoogleService-Info.plist` unless private and intended
- `google-services.json` unless private and intended
- service account keys

## Terms/policies needed before launch

- Terms of Service
- Privacy Policy
- Community Guidelines
- DMCA/contact policy
- Data source attribution page
- Independent fan app disclaimer
- High school/minor safety policy
- Subscription terms, if premium
