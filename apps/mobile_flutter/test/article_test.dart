// Tests for the Article model and the GamedayStoryCard widget.
//
// Unit tests: Article.fromJson for both preview and recap seed docs.
// Widget test: GamedayStoryCard renders the seed preview article's headline.

import 'package:bluegrass_gameday/app/theme/theme.dart';
import 'package:bluegrass_gameday/core/data/app_data_source.dart';
import 'package:bluegrass_gameday/core/models/models.dart';
import 'package:bluegrass_gameday/core/providers/data_providers.dart';
import 'package:bluegrass_gameday/features/shared/article_card.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Seed fixtures (inline copies of the two seed articles)
// ---------------------------------------------------------------------------

final Map<String, dynamic> _previewJson = <String, dynamic>{
  'id': 'article_fb_2026_youngstown_preview',
  'type': 'preview',
  'gameId': 'fb_2026_youngstown',
  'sport': 'football',
  'status': 'published',
  'headline': 'New Season Kicks Off: Kentucky Hosts Youngstown State',
  'subheadline':
      'Ball security and red-zone finishing give the Wildcats a comfortable edge in the opener.',
  'openingNarrative':
      'Kroger Field gets its first Saturday night of the season, and the early '
      'statistical picture favors the home team.',
  'tacticalBreakdown': <String, dynamic>{
    'title': 'The Chess Match',
    'narrative':
        'Kentucky wants to establish the run early and lean on play-action.',
  },
  'byTheNumbers': <String, dynamic>{
    'title': 'By the Numbers',
    'items': <String>[
      'Kentucky red-zone TD rate: 86% (top-tier finishing).',
      'Turnover margin: +0.5 per game — the quiet superpower.',
      'Yards per play edge: 5.9 to 5.6 in the Cats\' favor.',
    ],
  },
  'playerSpotlights': <Map<String, dynamic>>[
    <String, dynamic>{
      'playerId': 'fb_qb_demo',
      'name': 'Jordan Avery',
      'teamId': 'kentucky_football',
      'position': 'QB',
      'narrative': 'Sets the offense\'s tempo and protects the football.',
      'statline': '3,015 yds, 24 TD, 8 INT (2025 demo)',
    },
  ],
  'theVerdict': <String, dynamic>{
    'title': 'The Verdict',
    'prediction': 'Kentucky by 17',
    'confidence': 78,
    'narrative':
        'If the Cats avoid the explosive play on defense, this stays comfortable.',
  },
  'closingLine':
      'Opening night in the Bluegrass — and the numbers like the home team.',
  'sources': <String>[
    'seed_demo:team_stats/kentucky_football_2025_season',
    'seed_demo:game_summaries/fb_2026_youngstown',
  ],
  'model': 'seed_template',
  'generatedAt': '2026-06-12T12:00:00-04:00',
  'publishedAt': '2026-06-12T12:00:00-04:00',
  'confidence': 'demo',
  'featured': true,
};

final Map<String, dynamic> _recapJson = <String, dynamic>{
  'id': 'article_fb_2025_eastern_michigan_recap',
  'type': 'recap',
  'gameId': 'fb_2025_eastern_michigan',
  'sport': 'football',
  'status': 'published',
  'headline': 'Cats Cruise: Kentucky Rolls Past Eastern Michigan 48-23',
  'subheadline':
      'A red-zone stand and a clean turnover sheet decide an early SEC slugfest.',
  'openingNarrative':
      'It wasn\'t always pretty, but it was Kentucky\'s kind of game.',
  // No tacticalBreakdown on recap.
  'byTheNumbers': <String, dynamic>{
    'title': 'By the Numbers',
    'items': <String>[
      'Beat Eastern Michigan for a comfortable home win.',
      'A season-high 48 points for the Kentucky offense.',
    ],
  },
  'playerSpotlights': <Map<String, dynamic>>[
    <String, dynamic>{
      'playerId': 'fb_rb_demo',
      'name': 'Darius Combs',
      'position': 'RB',
      'narrative': 'Carried the load late to salt the game away.',
      'statline': '118 rush yds, 1 TD (demo)',
    },
  ],
  'theVerdict': <String, dynamic>{
    'title': 'The Takeaway',
    // No prediction on recap; has result instead.
    'result': 'Kentucky 48, Eastern Michigan 23',
    'narrative':
        'A blueprint win: no giveaways, touchdowns in the red zone.',
  },
  'closingLine': 'Not flashy — just the formula. The Cats bank an early SEC win.',
  'sources': <String>[
    'seed_demo:games/fb_2025_eastern_michigan',
    'seed_demo:team_stats/kentucky_football_2025_season',
  ],
  'model': 'seed_template',
  'generatedAt': '2025-09-13T23:30:00-04:00',
  'publishedAt': '2025-09-13T23:45:00-04:00',
  'confidence': 'demo',
  'featured': false,
};

// ---------------------------------------------------------------------------
// Minimal fake data source used by the widget test
// ---------------------------------------------------------------------------

class _FakeDataSource implements AppDataSource {
  @override
  Future<AppConfigDoc> appConfig() async =>
      AppConfigDoc.fromJson(<String, dynamic>{
        'id': 'main',
        'independentFanDisclaimer': 'Demo.',
      });

  @override
  Future<List<Article>> articles() async => <Article>[
        Article.fromJson(_previewJson),
        Article.fromJson(_recapJson),
      ];

  @override
  Future<List<Game>> games() async => <Game>[];
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
  Future<List<PredictionEntry>> predictionEntries() async => <PredictionEntry>[];
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

// ---------------------------------------------------------------------------
// Unit tests — Article.fromJson
// ---------------------------------------------------------------------------

void main() {
  group('Article.fromJson — preview doc', () {
    late Article article;

    setUp(() {
      article = Article.fromJson(_previewJson);
    });

    test('parses id, type, gameId, sport, status', () {
      expect(article.id, 'article_fb_2026_youngstown_preview');
      expect(article.type, 'preview');
      expect(article.gameId, 'fb_2026_youngstown');
      expect(article.sport, 'football');
      expect(article.status, 'published');
      expect(article.isPublished, isTrue);
      expect(article.isPreview, isTrue);
      expect(article.isRecap, isFalse);
    });

    test('parses headline and subheadline', () {
      expect(
        article.headline,
        'New Season Kicks Off: Kentucky Hosts Youngstown State',
      );
      expect(
        article.subheadline,
        contains('Ball security'),
      );
    });

    test('parses tacticalBreakdown (optional, present on preview)', () {
      expect(article.tacticalBreakdown, isNotNull);
      expect(article.tacticalBreakdown!.title, 'The Chess Match');
      expect(article.tacticalBreakdown!.narrative, contains('run early'));
    });

    test('parses byTheNumbers with 3 items', () {
      expect(article.byTheNumbers, isNotNull);
      expect(article.byTheNumbers!.title, 'By the Numbers');
      expect(article.byTheNumbers!.items.length, 3);
      expect(article.byTheNumbers!.items.first, contains('86%'));
    });

    test('parses playerSpotlights', () {
      expect(article.playerSpotlights.length, 1);
      expect(article.playerSpotlights.first.name, 'Jordan Avery');
      expect(article.playerSpotlights.first.position, 'QB');
      expect(article.playerSpotlights.first.statline, contains('3,015'));
    });

    test('parses theVerdict with prediction and confidence (no result)', () {
      expect(article.theVerdict, isNotNull);
      expect(article.theVerdict!.title, 'The Verdict');
      expect(article.theVerdict!.prediction, 'Kentucky by 17');
      expect(article.theVerdict!.confidence, 78);
      expect(article.theVerdict!.result, isNull);
    });

    test('parses sources, model, confidence, featured', () {
      expect(article.sources.length, 2);
      expect(article.sources.first, contains('seed_demo'));
      expect(article.model, 'seed_template');
      expect(article.confidence, 'demo');
      expect(article.featured, isTrue);
    });

    test('parses generatedAt as DateTime', () {
      expect(article.generatedAt, isNotNull);
      expect(article.generatedAt!.year, 2026);
    });
  });

  group('Article.fromJson — recap doc (optional field differences)', () {
    late Article article;

    setUp(() {
      article = Article.fromJson(_recapJson);
    });

    test('parses type as recap', () {
      expect(article.type, 'recap');
      expect(article.isRecap, isTrue);
      expect(article.isPreview, isFalse);
    });

    test('tacticalBreakdown is null on recap (field absent)', () {
      expect(article.tacticalBreakdown, isNull);
    });

    test('theVerdict has result but no prediction or confidence', () {
      expect(article.theVerdict, isNotNull);
      expect(article.theVerdict!.result, 'Kentucky 48, Eastern Michigan 23');
      expect(article.theVerdict!.prediction, isNull);
      expect(article.theVerdict!.confidence, isNull);
    });

    test('parses byTheNumbers on recap', () {
      expect(article.byTheNumbers!.items.length, 2);
      expect(article.byTheNumbers!.items.first, contains('Eastern Michigan'));
    });

    test('featured is false on recap', () {
      expect(article.featured, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Widget test — GamedayStoryCard renders the headline
  // ---------------------------------------------------------------------------

  testWidgets(
    'GamedayStoryCard renders the seed preview article headline',
    (WidgetTester tester) async {
      final Article article = Article.fromJson(_previewJson);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            dataSourceProvider.overrideWithValue(_FakeDataSource()),
          ],
          child: MaterialApp(
            theme: BgTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GamedayStoryCard(article: article),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Headline is rendered.
      expect(
        find.textContaining(
            'New Season Kicks Off'),
        findsWidgets,
      );

      // Subheadline is rendered.
      expect(find.textContaining('Ball security'), findsOneWidget);

      // AI attribution label is rendered.
      expect(
        find.textContaining('Bluegrass Gameday AI'),
        findsWidgets,
      );

      // Source attribution is rendered.
      expect(find.textContaining('seed_demo'), findsWidgets);
    },
  );

  testWidgets(
    'GamedayStoryCard renders recap result score when expanded',
    (WidgetTester tester) async {
      final Article article = Article.fromJson(_recapJson);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            dataSourceProvider.overrideWithValue(_FakeDataSource()),
          ],
          child: MaterialApp(
            theme: BgTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GamedayStoryCard(article: article),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Headline is rendered.
      expect(
        find.textContaining('Cats Cruise'),
        findsWidgets,
      );

      // Opening narrative is rendered.
      expect(find.textContaining('Kentucky\'s kind of game'), findsOneWidget);

      // Tap "Read full story" to expand.
      await tester.tap(find.text('Read full story'));
      await tester.pumpAndSettle();

      // Verdict result score appears.
      expect(find.textContaining('Kentucky 48, Eastern Michigan 23'), findsOneWidget);
    },
  );
}
