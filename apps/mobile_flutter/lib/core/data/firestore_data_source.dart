import '../models/models.dart';
import 'app_data_source.dart';

/// Live Firestore implementation of [AppDataSource].
///
/// ⚠️ NOT WIRED UP IN PHASE 1. This is intentionally a stub:
///   * `AppConfig.useFirestore` is `false`, so the app never constructs this.
///   * `cloud_firestore` is NOT a dependency yet and `firebase_options.dart`
///     does not exist, so Firebase is never initialized at startup.
///
/// TODO(phase-2): To enable live data:
///   1. `flutter pub add firebase_core cloud_firestore`.
///   2. `flutterfire configure` to generate `firebase_options.dart`.
///   3. `await Firebase.initializeApp(...)` in `main()`.
///   4. Replace each method body below with a `FirebaseFirestore.instance`
///      collection read mapping snapshots through the model `fromJson`s.
///   5. Flip `AppConfig.useFirestore` to `true`.
///
/// The method signatures already match the collections in docs/04 so the
/// migration is mechanical. Until then every method throws to make accidental
/// use loud and obvious.
class FirestoreDataSource implements AppDataSource {
  const FirestoreDataSource();

  Never _notWired(String collection) {
    throw UnimplementedError(
      'FirestoreDataSource.$collection is not wired up. Phase 1 runs on the '
      'bundled seed via MockDataSource. See AppConfig.useFirestore and the '
      'TODO in firestore_data_source.dart before enabling Firebase.',
    );
  }

  @override
  Future<AppConfigDoc> appConfig() => _notWired('appConfig');

  @override
  Future<List<Team>> teams() => _notWired('teams');

  @override
  Future<List<Game>> games() => _notWired('games');

  @override
  Future<List<GameSummary>> gameSummaries() => _notWired('gameSummaries');

  @override
  Future<List<TeamStat>> teamStats() => _notWired('teamStats');

  @override
  Future<List<PlayerProfile>> playerProfiles() => _notWired('playerProfiles');

  @override
  Future<List<PlayerStat>> playerStats() => _notWired('playerStats');

  @override
  Future<List<Prediction>> predictions() => _notWired('predictions');

  @override
  Future<List<PredictionEntry>> predictionEntries() =>
      _notWired('predictionEntries');

  @override
  Future<List<AppUser>> users() => _notWired('users');

  @override
  Future<List<Badge>> badges() => _notWired('badges');

  @override
  Future<List<UserBadge>> userBadges() => _notWired('userBadges');

  @override
  Future<List<Poll>> polls() => _notWired('polls');

  @override
  Future<List<NewsCard>> newsCards() => _notWired('newsCards');

  @override
  Future<List<HighSchool>> highSchools() => _notWired('highSchools');

  @override
  Future<List<HighSchoolGame>> highSchoolGames() =>
      _notWired('highSchoolGames');

  @override
  Future<List<Recruit>> recruits() => _notWired('recruits');
}
