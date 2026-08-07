// ProviderContainer tests for the screen-ready selectors in app_providers.dart:
//  - featuredGameProvider's featured -> next-game fallback chain,
//  - lastFinalGameProvider's newest-final-first sort,
//  - articleForGameProvider preferring the recap once a game is final (and the
//    preview before it), when one gameId holds both article types.

import 'package:bluegrass_gameday/core/data/app_data_source.dart';
import 'package:bluegrass_gameday/core/models/models.dart';
import 'package:bluegrass_gameday/core/providers/app_providers.dart';
import 'package:bluegrass_gameday/core/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Game _game(Map<String, dynamic> overrides) {
  return Game.fromJson(<String, dynamic>{
    'id': 'g',
    'season': 2099,
    'sport': 'football',
    'homeTeamId': 'kentucky_football',
    'awayTeamId': 'opp',
    'opponentName': 'Opponent',
    'opponentShort': 'OPP',
    'status': 'scheduled',
    'isHome': true,
    ...overrides,
  });
}

Article _article(Map<String, dynamic> overrides) {
  return Article.fromJson(<String, dynamic>{
    'id': 'a',
    'type': 'preview',
    'gameId': 'g',
    'sport': 'football',
    'status': 'published',
    'headline': 'Headline',
    'confidence': 'demo',
    ...overrides,
  });
}

/// One final game (with BOTH a preview and a recap article) plus a featured
/// and a sooner non-featured upcoming game.
class _FakeDataSource implements AppDataSource {
  _FakeDataSource({this.includeFeatured = true});

  final bool includeFeatured;

  @override
  Future<List<Game>> games() async => <Game>[
        _game(<String, dynamic>{
          'id': 'fb_final_old',
          'status': 'final',
          'startTime': '2025-09-06T19:00:00-04:00',
          'homeScore': 31,
          'awayScore': 10,
          'result': 'win',
        }),
        _game(<String, dynamic>{
          'id': 'fb_final_new',
          'status': 'final',
          'startTime': '2025-09-13T19:00:00-04:00',
          'homeScore': 48,
          'awayScore': 23,
          'result': 'win',
        }),
        // Sooner, but not featured.
        _game(<String, dynamic>{
          'id': 'fb_next_soon',
          'startTime': '2099-09-05T19:00:00-04:00',
        }),
        if (includeFeatured)
          _game(<String, dynamic>{
            'id': 'fb_featured',
            'startTime': '2099-09-12T19:00:00-04:00',
            'featured': true,
          }),
      ];

  @override
  Future<List<Article>> articles() async => <Article>[
        // Raw order puts the stale preview FIRST for the final game — the
        // provider must still pick the recap.
        _article(<String, dynamic>{
          'id': 'article_fb_final_new_preview',
          'type': 'preview',
          'gameId': 'fb_final_new',
          'publishedAt': '2025-09-10T12:00:00-04:00',
        }),
        _article(<String, dynamic>{
          'id': 'article_fb_final_new_recap',
          'type': 'recap',
          'gameId': 'fb_final_new',
          'publishedAt': '2025-09-13T23:45:00-04:00',
        }),
        _article(<String, dynamic>{
          'id': 'article_fb_featured_preview',
          'type': 'preview',
          'gameId': 'fb_featured',
          'publishedAt': '2099-09-10T12:00:00-04:00',
        }),
      ];

  @override
  Future<AppConfigDoc> appConfig() async =>
      AppConfigDoc.fromJson(<String, dynamic>{'id': 'main'});
  @override
  Future<List<Team>> teams() async => <Team>[];
  @override
  Future<List<GameSummary>> gameSummaries() async => <GameSummary>[];
  @override
  Future<List<TeamStat>> teamStats() async => <TeamStat>[];
  @override
  Future<List<PlayerProfile>> playerProfiles() async => <PlayerProfile>[];
  @override
  Future<List<PlayerStat>> playerStats() async => <PlayerStat>[];
  @override
  Future<List<Prediction>> predictions() async => <Prediction>[];
  @override
  Future<List<PredictionEntry>> predictionEntries() async =>
      <PredictionEntry>[];
  @override
  Future<List<AppUser>> users() async => <AppUser>[];
  @override
  Future<List<Badge>> badges() async => <Badge>[];
  @override
  Future<List<UserBadge>> userBadges() async => <UserBadge>[];
  @override
  Future<List<Poll>> polls() async => <Poll>[];
  @override
  Future<List<NewsCard>> newsCards() async => <NewsCard>[];
  @override
  Future<List<HighSchool>> highSchools() async => <HighSchool>[];
  @override
  Future<List<HighSchoolGame>> highSchoolGames() async => <HighSchoolGame>[];
  @override
  Future<List<Recruit>> recruits() async => <Recruit>[];
}

ProviderContainer _container({bool includeFeatured = true}) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      dataSourceProvider.overrideWithValue(
        _FakeDataSource(includeFeatured: includeFeatured),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('featuredGameProvider prefers the featured upcoming game', () async {
    final Game? featured =
        await _container().read(featuredGameProvider.future);
    expect(featured?.id, 'fb_featured');
  });

  test('featuredGameProvider falls back to the soonest upcoming game',
      () async {
    final Game? featured = await _container(includeFeatured: false)
        .read(featuredGameProvider.future);
    expect(featured?.id, 'fb_next_soon');
  });

  test('lastFinalGameProvider returns the most recent final', () async {
    final Game? last = await _container().read(lastFinalGameProvider.future);
    expect(last?.id, 'fb_final_new');
  });

  test('articleForGameProvider prefers the recap once the game is final',
      () async {
    final Article? a = await _container()
        .read(articleForGameProvider('fb_final_new').future);
    expect(a?.type, 'recap');
    expect(a?.id, 'article_fb_final_new_recap');
  });

  test('articleForGameProvider serves the preview before the game is final',
      () async {
    final Article? a = await _container()
        .read(articleForGameProvider('fb_featured').future);
    expect(a?.type, 'preview');
  });

  test('lastFinalRecapArticleProvider never returns a stale preview',
      () async {
    final Article? a =
        await _container().read(lastFinalRecapArticleProvider.future);
    expect(a?.type, 'recap');
    expect(a?.gameId, 'fb_final_new');
  });

  test('featuredPreviewArticleProvider returns the featured game preview',
      () async {
    final Article? a =
        await _container().read(featuredPreviewArticleProvider.future);
    expect(a?.id, 'article_fb_featured_preview');
  });
}
