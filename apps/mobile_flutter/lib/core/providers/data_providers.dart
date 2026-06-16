import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../data/app_data_source.dart';
import '../data/firestore_data_source.dart';
import '../data/mock_data_source.dart';
import '../models/models.dart';

/// The active [AppDataSource]. Defaults to [MockDataSource] (seed JSON).
///
/// Gated by `AppConfig.useFirestore` — Firestore is intentionally NOT the
/// default and Firebase is never initialized in Phase 1.
final dataSourceProvider = Provider<AppDataSource>((Ref ref) {
  // ignore: dead_code — useFirestore is a const false in Phase 1 by design.
  if (AppConfig.useFirestore) {
    return const FirestoreDataSource();
  }
  return MockDataSource();
});

// --- Raw collection providers (each loads one seed collection once) ---------

final appConfigProvider = FutureProvider<AppConfigDoc>((Ref ref) {
  return ref.watch(dataSourceProvider).appConfig();
});

final teamsProvider = FutureProvider<List<Team>>((Ref ref) {
  return ref.watch(dataSourceProvider).teams();
});

final gamesProvider = FutureProvider<List<Game>>((Ref ref) {
  return ref.watch(dataSourceProvider).games();
});

final gameSummariesProvider = FutureProvider<List<GameSummary>>((Ref ref) {
  return ref.watch(dataSourceProvider).gameSummaries();
});

final teamStatsProvider = FutureProvider<List<TeamStat>>((Ref ref) {
  return ref.watch(dataSourceProvider).teamStats();
});

final playerProfilesProvider = FutureProvider<List<PlayerProfile>>((Ref ref) {
  return ref.watch(dataSourceProvider).playerProfiles();
});

final playerStatsProvider = FutureProvider<List<PlayerStat>>((Ref ref) {
  return ref.watch(dataSourceProvider).playerStats();
});

final predictionsProvider = FutureProvider<List<Prediction>>((Ref ref) {
  return ref.watch(dataSourceProvider).predictions();
});

final predictionEntriesProvider =
    FutureProvider<List<PredictionEntry>>((Ref ref) {
  return ref.watch(dataSourceProvider).predictionEntries();
});

final usersProvider = FutureProvider<List<AppUser>>((Ref ref) {
  return ref.watch(dataSourceProvider).users();
});

final badgesProvider = FutureProvider<List<Badge>>((Ref ref) {
  return ref.watch(dataSourceProvider).badges();
});

final userBadgesProvider = FutureProvider<List<UserBadge>>((Ref ref) {
  return ref.watch(dataSourceProvider).userBadges();
});

final pollsProvider = FutureProvider<List<Poll>>((Ref ref) {
  return ref.watch(dataSourceProvider).polls();
});

final newsCardsProvider = FutureProvider<List<NewsCard>>((Ref ref) {
  return ref.watch(dataSourceProvider).newsCards();
});

final highSchoolsProvider = FutureProvider<List<HighSchool>>((Ref ref) {
  return ref.watch(dataSourceProvider).highSchools();
});

final highSchoolGamesProvider =
    FutureProvider<List<HighSchoolGame>>((Ref ref) {
  return ref.watch(dataSourceProvider).highSchoolGames();
});

final recruitsProvider = FutureProvider<List<Recruit>>((Ref ref) {
  return ref.watch(dataSourceProvider).recruits();
});

final articlesProvider = FutureProvider<List<Article>>((Ref ref) {
  return ref.watch(dataSourceProvider).articles();
});
