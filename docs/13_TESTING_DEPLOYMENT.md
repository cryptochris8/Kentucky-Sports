# 13 — Testing and Deployment

## Testing strategy

### Flutter tests
- unit tests for models
- unit tests for stats explainers
- widget tests for key cards
- integration test for prediction flow

### Cloud Functions tests
- prediction scoring
- XP awards
- badge criteria
- data normalization
- input validation
- admin role checks

### Firestore security rules tests
- user can read public data
- user can update own profile
- user cannot update other profiles
- user cannot write stats
- admin can create news cards
- moderator can hide posts
- anonymous/guest limitations

### Admin portal tests
- render dashboard
- create/edit prediction
- create news card
- moderation action
- auth role guard

## Firebase emulator

Use emulator for:
- Auth
- Firestore
- Functions
- Storage
- Hosting if useful

Add scripts:

```json
{
  "scripts": {
    "emulators": "firebase emulators:start",
    "seed": "tsx scripts/seed_firestore.ts",
    "test:functions": "vitest",
    "deploy:functions": "firebase deploy --only functions",
    "deploy:rules": "firebase deploy --only firestore:rules,firestore:indexes,storage"
  }
}
```

## Environments

- local
- dev
- staging
- production

Firestore paths can be same collections per project, not environment prefix, if separate Firebase projects are used.

## Deployment path

### Mobile
1. Build Flutter iOS.
2. Configure Firebase iOS.
3. Add App Check.
4. Test with Firebase dev project.
5. Archive in Xcode.
6. Upload to TestFlight.
7. Internal testing.
8. External beta.
9. App Store submission.

### Admin portal
1. Build React app.
2. Deploy to Firebase Hosting.
3. Restrict admin route by Firebase custom claims.
4. Use staging URL first.

### Functions
1. Deploy functions to dev.
2. Verify with emulator and dev Firestore.
3. Add scheduler jobs only after verifying manual triggers.
4. Deploy production with real secrets.

## Monitoring

Use:
- Firebase Crashlytics
- Firebase Analytics
- Cloud Functions logs
- Error Reporting
- sync_runs collection
- admin dashboard sync health

## QA checklist

### Before beta
- no official logos
- disclaimer visible
- privacy policy and terms linked
- predictions are free-to-play
- no gambling words
- no direct messaging
- report content button works
- all data has source/updatedAt
- app handles empty/offseason states
- push notifications opt-in
- account deletion flow planned
- no API keys in client code

### Before production
- App Store screenshots
- support URL
- privacy URL
- data safety answers
- content moderation process
- subscription terms, if enabled
- crash-free sessions > 99%
- Firestore billing estimate
- API provider tier selected
