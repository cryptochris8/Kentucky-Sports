/// App-wide configuration and feature flags for Bluegrass Gameday.
///
/// Keep this file free of any secrets or API keys (hard rule). Source data
/// providers (CFBD/CBBD/KHSAA) are never called from the mobile client.
library;

abstract final class AppConfig {
  /// App display name (no official UK marks).
  static const String appName = 'Bluegrass Gameday';

  /// Marketing version. Mirror pubspec `version`.
  static const String version = '1.0.0';
  static const String buildNumber = '1';

  /// Data-source selector.
  ///
  /// ⚠️ LOCKED FOR PHASE 1: `false` => the app loads the bundled seed JSON via
  /// [MockDataSource] and runs with ZERO backend. This guarantees
  /// `flutter run` works immediately with no Firebase configured.
  ///
  /// TODO(phase-2): Flip to `true` ONLY after:
  ///   1. Running `flutterfire configure` to generate `firebase_options.dart`.
  ///   2. Calling `Firebase.initializeApp(...)` in `main()`.
  ///   3. Pointing repositories at [FirestoreDataSource].
  /// Until then this MUST stay `false` — no `firebase_options.dart` exists and
  /// Firebase is intentionally not initialized at startup.
  static const bool useFirestore = false;

  /// Path to the bundled seed asset (build-time copy of the canonical seed at
  /// repo `seed_data/dev_seed.json`).
  static const String seedAssetPath = 'assets/seed/dev_seed.json';

  /// The "current user" id in seed data (used for guest/demo personalization).
  static const String demoUserId = 'demo_user_self';

  /// Today's reference date for countdowns/demos. The app uses the real
  /// `DateTime.now()`; this constant documents the seed's intended timeframe.
  static const String seedReferenceDate = '2026-06-15';
}
