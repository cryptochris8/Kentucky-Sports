import '../models/models.dart';
import 'app_data_source.dart';
import 'seed_loader.dart';

/// Default [AppDataSource] — reads the bundled seed JSON.
///
/// This is what makes `flutter run` work with ZERO backend. A small simulated
/// latency is added so loading states are visible and realistic in the UI.
class MockDataSource implements AppDataSource {
  MockDataSource({this.latency = const Duration(milliseconds: 220)});

  /// Simulated network latency so loading skeletons are exercised.
  final Duration latency;

  final SeedLoader _seed = SeedLoader.instance;

  Future<List<T>> _list<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final List<Map<String, dynamic>> raw = await _seed.collection(key);
    await Future<void>.delayed(latency);
    return raw.map(fromJson).toList();
  }

  @override
  Future<AppConfigDoc> appConfig() async {
    final List<Map<String, dynamic>> raw = await _seed.collection('app_config');
    await Future<void>.delayed(latency);
    if (raw.isEmpty) {
      return AppConfigDoc.fromJson(<String, dynamic>{'id': 'main'});
    }
    return AppConfigDoc.fromJson(raw.first);
  }

  @override
  Future<List<Team>> teams() => _list('teams', Team.fromJson);

  @override
  Future<List<Game>> games() => _list('games', Game.fromJson);

  @override
  Future<List<GameSummary>> gameSummaries() =>
      _list('game_summaries', GameSummary.fromJson);

  @override
  Future<List<TeamStat>> teamStats() =>
      _list('team_stats', TeamStat.fromJson);

  @override
  Future<List<PlayerProfile>> playerProfiles() =>
      _list('player_profiles', PlayerProfile.fromJson);

  @override
  Future<List<PlayerStat>> playerStats() =>
      _list('player_stats', PlayerStat.fromJson);

  @override
  Future<List<Prediction>> predictions() =>
      _list('predictions', Prediction.fromJson);

  @override
  Future<List<PredictionEntry>> predictionEntries() =>
      _list('prediction_entries', PredictionEntry.fromJson);

  @override
  Future<List<AppUser>> users() => _list('users', AppUser.fromJson);

  @override
  Future<List<Badge>> badges() => _list('badges', Badge.fromJson);

  @override
  Future<List<UserBadge>> userBadges() =>
      _list('user_badges', UserBadge.fromJson);

  @override
  Future<List<Poll>> polls() => _list('polls', Poll.fromJson);

  @override
  Future<List<NewsCard>> newsCards() =>
      _list('news_cards', NewsCard.fromJson);

  @override
  Future<List<HighSchool>> highSchools() =>
      _list('high_schools', HighSchool.fromJson);

  @override
  Future<List<HighSchoolGame>> highSchoolGames() =>
      _list('high_school_games', HighSchoolGame.fromJson);

  @override
  Future<List<Recruit>> recruits() => _list('recruits', Recruit.fromJson);
}
