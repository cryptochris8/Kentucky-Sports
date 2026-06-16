import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../models/models.dart';
import 'data_providers.dart';

/// Higher-level, screen-ready providers derived from raw collections.
///
/// Repositories here are thin selectors/combinators over the cached collection
/// providers. They keep the dependency graph acyclic: features depend on these,
/// these depend on `data_providers`, those depend on the data source.

// --- Current user -----------------------------------------------------------

/// The "you" user from seed (guest/demo identity).
final currentUserProvider = FutureProvider<AppUser>((Ref ref) async {
  final List<AppUser> users = await ref.watch(usersProvider.future);
  return users.firstWhere(
    (AppUser u) => u.id == AppConfig.demoUserId,
    orElse: () => users.isNotEmpty
        ? users.first
        : const AppUser(
            id: 'guest',
            displayName: 'Guest',
            email: '',
            role: 'user',
            favoriteCollegeTeams: <String>['kentucky'],
            favoriteSports: <String>['football', 'mens_basketball'],
            favoriteHighSchools: <String>[],
            homeState: 'KY',
            xp: 0,
            level: 1,
            predictionRecord:
                PredictionRecord(total: 0, correct: 0, streak: 0),
          ),
  );
});

// --- Games selectors --------------------------------------------------------

/// Upcoming (scheduled) games sorted by soonest start time.
final upcomingGamesProvider = FutureProvider<List<Game>>((Ref ref) async {
  final List<Game> games = await ref.watch(gamesProvider.future);
  final List<Game> upcoming =
      games.where((Game g) => g.isUpcoming).toList()
        ..sort((Game a, Game b) {
          final DateTime ax =
              a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bx =
              b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
          return ax.compareTo(bx);
        });
  return upcoming;
});

/// The single next game across all sports (soonest upcoming), or null.
final nextGameProvider = FutureProvider<Game?>((Ref ref) async {
  final List<Game> upcoming = await ref.watch(upcomingGamesProvider.future);
  if (upcoming.isEmpty) return null;
  final DateTime now = DateTime.now();
  // Prefer games still in the future; otherwise fall back to the first.
  for (final Game g in upcoming) {
    final DateTime? t = g.startTime;
    if (t != null && t.isAfter(now)) return g;
  }
  return upcoming.first;
});

/// The featured upcoming game for Gameday HQ (featured flag, else next game).
final featuredGameProvider = FutureProvider<Game?>((Ref ref) async {
  final List<Game> games = await ref.watch(gamesProvider.future);
  final DateTime now = DateTime.now();
  final List<Game> featuredUpcoming = games
      .where((Game g) =>
          g.featured && g.isUpcoming && (g.startTime?.isAfter(now) ?? false))
      .toList()
    ..sort((Game a, Game b) =>
        (a.startTime ?? now).compareTo(b.startTime ?? now));
  if (featuredUpcoming.isNotEmpty) return featuredUpcoming.first;
  return ref.watch(nextGameProvider.future);
});

/// The most recent final game (for postgame state + prediction results).
final lastFinalGameProvider = FutureProvider<Game?>((Ref ref) async {
  final List<Game> games = await ref.watch(gamesProvider.future);
  final List<Game> finals = games.where((Game g) => g.isFinal).toList()
    ..sort((Game a, Game b) => (b.startTime ?? DateTime(0))
        .compareTo(a.startTime ?? DateTime(0)));
  return finals.isEmpty ? null : finals.first;
});

/// Game summary lookup by gameId.
final gameSummaryByIdProvider =
    FutureProvider.family<GameSummary?, String>((Ref ref, String gameId) async {
  final List<GameSummary> all = await ref.watch(gameSummariesProvider.future);
  for (final GameSummary s in all) {
    if (s.gameId == gameId) return s;
  }
  return null;
});

/// Games for a specific team (home team id match), sorted by date.
final gamesForTeamProvider =
    FutureProvider.family<List<Game>, String>((Ref ref, String teamId) async {
  final List<Game> games = await ref.watch(gamesProvider.future);
  final List<Game> filtered = games
      .where((Game g) => g.homeTeamId == teamId || g.awayTeamId == teamId)
      .toList()
    ..sort((Game a, Game b) =>
        (a.startTime ?? DateTime(0)).compareTo(b.startTime ?? DateTime(0)));
  return filtered;
});

// --- Team selectors ---------------------------------------------------------

final teamByIdProvider =
    FutureProvider.family<Team?, String>((Ref ref, String teamId) async {
  final List<Team> teams = await ref.watch(teamsProvider.future);
  for (final Team t in teams) {
    if (t.id == teamId) return t;
  }
  return null;
});

final teamStatForTeamProvider =
    FutureProvider.family<TeamStat?, String>((Ref ref, String teamId) async {
  final List<TeamStat> stats = await ref.watch(teamStatsProvider.future);
  TeamStat? best;
  for (final TeamStat s in stats) {
    if (s.teamId == teamId) {
      if (best == null || s.season > best.season) best = s;
    }
  }
  return best;
});

final playersForTeamProvider =
    FutureProvider.family<List<PlayerProfile>, String>(
        (Ref ref, String teamId) async {
  final List<PlayerProfile> players =
      await ref.watch(playerProfilesProvider.future);
  return players.where((PlayerProfile p) => p.teamId == teamId).toList();
});

final playerStatByPlayerProvider =
    FutureProvider.family<PlayerStat?, String>(
        (Ref ref, String playerId) async {
  final List<PlayerStat> stats = await ref.watch(playerStatsProvider.future);
  PlayerStat? best;
  for (final PlayerStat s in stats) {
    if (s.playerId == playerId) {
      if (best == null || s.season > best.season) best = s;
    }
  }
  return best;
});

final playerByIdProvider =
    FutureProvider.family<PlayerProfile?, String>(
        (Ref ref, String playerId) async {
  final List<PlayerProfile> players =
      await ref.watch(playerProfilesProvider.future);
  for (final PlayerProfile p in players) {
    if (p.id == playerId) return p;
  }
  return null;
});

// --- Predictions ------------------------------------------------------------

/// Open predictions sorted by soonest close time.
final openPredictionsProvider = FutureProvider<List<Prediction>>((Ref ref) async {
  final List<Prediction> preds = await ref.watch(predictionsProvider.future);
  final List<Prediction> open = preds.where((Prediction p) => p.isOpen).toList()
    ..sort((Prediction a, Prediction b) =>
        (a.closesAt ?? DateTime(0)).compareTo(b.closesAt ?? DateTime(0)));
  return open;
});

/// Scored predictions (used in the Results section).
final scoredPredictionsProvider =
    FutureProvider<List<Prediction>>((Ref ref) async {
  final List<Prediction> preds = await ref.watch(predictionsProvider.future);
  return preds.where((Prediction p) => p.isScored).toList();
});

/// The current user's prediction entries.
final myEntriesProvider =
    FutureProvider<List<PredictionEntry>>((Ref ref) async {
  final List<PredictionEntry> entries =
      await ref.watch(predictionEntriesProvider.future);
  return entries
      .where((PredictionEntry e) => e.userId == AppConfig.demoUserId)
      .toList();
});

// --- Leaderboard ------------------------------------------------------------

/// Users sorted by XP descending (leaderboard).
final leaderboardProvider = FutureProvider<List<AppUser>>((Ref ref) async {
  final List<AppUser> users = await ref.watch(usersProvider.future);
  final List<AppUser> sorted = List<AppUser>.of(users)
    ..sort((AppUser a, AppUser b) => b.xp.compareTo(a.xp));
  return sorted;
});

// --- Badges -----------------------------------------------------------------

/// The current user's earned badge ids.
final myEarnedBadgeIdsProvider = FutureProvider<Set<String>>((Ref ref) async {
  final List<UserBadge> ub = await ref.watch(userBadgesProvider.future);
  return ub
      .where((UserBadge b) => b.userId == AppConfig.demoUserId)
      .map((UserBadge b) => b.badgeId)
      .toSet();
});

// --- Articles ---------------------------------------------------------------

/// All published articles, sorted by publishedAt descending.
final publishedArticlesProvider =
    FutureProvider<List<Article>>((Ref ref) async {
  final List<Article> all = await ref.watch(articlesProvider.future);
  final List<Article> published =
      all.where((Article a) => a.isPublished).toList()
        ..sort((Article a, Article b) =>
            (b.publishedAt ?? DateTime(0))
                .compareTo(a.publishedAt ?? DateTime(0)));
  return published;
});

/// The article (preview or recap) for a specific gameId, or null.
final articleForGameProvider =
    FutureProvider.family<Article?, String>((Ref ref, String gameId) async {
  final List<Article> all = await ref.watch(articlesProvider.future);
  for (final Article a in all) {
    if (a.gameId == gameId && a.isPublished) return a;
  }
  return null;
});

/// The featured preview article (for the featured upcoming game's pregame read).
final featuredPreviewArticleProvider =
    FutureProvider<Article?>((Ref ref) async {
  final Game? game = await ref.watch(featuredGameProvider.future);
  if (game == null) return null;
  return ref.watch(articleForGameProvider(game.id).future);
});

/// The recap article for the most recent final game.
final lastFinalRecapArticleProvider =
    FutureProvider<Article?>((Ref ref) async {
  final Game? game = await ref.watch(lastFinalGameProvider.future);
  if (game == null) return null;
  return ref.watch(articleForGameProvider(game.id).future);
});

// --- High schools -----------------------------------------------------------

/// High school games joined with their school name, sorted by date.
final highSchoolGameRowsProvider =
    FutureProvider<List<({HighSchoolGame game, HighSchool? school})>>(
        (Ref ref) async {
  final List<HighSchoolGame> games =
      await ref.watch(highSchoolGamesProvider.future);
  final List<HighSchool> schools = await ref.watch(highSchoolsProvider.future);
  final Map<String, HighSchool> byId = <String, HighSchool>{
    for (final HighSchool s in schools) s.id: s,
  };
  final List<({HighSchoolGame game, HighSchool? school})> rows = games
      .map((HighSchoolGame g) =>
          (game: g, school: byId[g.schoolId]))
      .toList()
    ..sort((({HighSchoolGame game, HighSchool? school}) a,
            ({HighSchoolGame game, HighSchool? school}) b) =>
        (a.game.startTime ?? DateTime(0))
            .compareTo(b.game.startTime ?? DateTime(0)));
  return rows;
});
