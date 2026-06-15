import '../models/models.dart';

/// The data-source contract used by all repositories.
///
/// Two implementations exist:
///  * [MockDataSource] — loads the bundled seed JSON (default, zero backend).
///  * [FirestoreDataSource] — reads live Firestore (Phase 2, gated by a flag).
///
/// Keeping this interface narrow keeps the dependency tree shallow and lets the
/// app swap backends by flipping `AppConfig.useFirestore`.
abstract interface class AppDataSource {
  Future<AppConfigDoc> appConfig();
  Future<List<Team>> teams();
  Future<List<Game>> games();
  Future<List<GameSummary>> gameSummaries();
  Future<List<TeamStat>> teamStats();
  Future<List<PlayerProfile>> playerProfiles();
  Future<List<PlayerStat>> playerStats();
  Future<List<Prediction>> predictions();
  Future<List<PredictionEntry>> predictionEntries();
  Future<List<AppUser>> users();
  Future<List<Badge>> badges();
  Future<List<UserBadge>> userBadges();
  Future<List<Poll>> polls();
  Future<List<NewsCard>> newsCards();
  Future<List<HighSchool>> highSchools();
  Future<List<HighSchoolGame>> highSchoolGames();
  Future<List<Recruit>> recruits();
}
