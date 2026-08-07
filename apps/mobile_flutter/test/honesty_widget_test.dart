// Widget tests for the hard-rule-6 surfaces:
//  - Home "Stat of the Day" renders percentile/rank ONLY when the TeamStat doc
//    carries them, and renders nothing without a basketball doc (no cross-sport
//    fallback, no invented value),
//  - the article AI-attribution line derives from the article's confidence
//    tier and never overclaims ("official" only for official inputs),
//  - CountdownStrip ticks via its Timer only while a countdown is running
//    (no timer when already live, self-cancel at game time), uses
//    sport-correct copy, and disposes cleanly,
//  - CompareRow treats exactly equal values as a tie — no false Kentucky edge.

import 'package:bluegrass_gameday/app/theme/theme.dart';
import 'package:bluegrass_gameday/core/data/app_data_source.dart';
import 'package:bluegrass_gameday/core/models/models.dart';
import 'package:bluegrass_gameday/core/providers/data_providers.dart';
import 'package:bluegrass_gameday/core/widgets/stat_card.dart';
import 'package:bluegrass_gameday/features/home/home_screen.dart';
import 'package:bluegrass_gameday/features/shared/article_card.dart';
import 'package:bluegrass_gameday/features/shared/game_widgets.dart';
// Hide Material's Badge widget so our Badge model name is unambiguous.
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake data source whose team stats are injectable per test case.
class _FakeDataSource implements AppDataSource {
  _FakeDataSource({this.stats = const <TeamStat>[]});

  final List<TeamStat> stats;

  @override
  Future<List<TeamStat>> teamStats() async => stats;

  @override
  Future<AppConfigDoc> appConfig() async =>
      AppConfigDoc.fromJson(<String, dynamic>{'id': 'main'});
  @override
  Future<List<AppUser>> users() async => <AppUser>[
        AppUser.fromJson(<String, dynamic>{
          'id': 'demo_user_self',
          'displayName': 'You',
        }),
      ];
  @override
  Future<List<Game>> games() async => <Game>[];
  @override
  Future<List<Team>> teams() async => <Team>[];
  @override
  Future<List<GameSummary>> gameSummaries() async => <GameSummary>[];
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
  @override
  Future<List<Article>> articles() async => <Article>[];
}

TeamStat _bballStat({Map<String, dynamic>? rankings}) {
  return TeamStat.fromJson(<String, dynamic>{
    'id': 'kentucky_mens_basketball_2026_season',
    'teamId': 'kentucky_mens_basketball',
    'season': 2026,
    'sport': 'mens_basketball',
    'stats': <String, dynamic>{'effectiveFgPct': 0.552},
    if (rankings != null) 'rankings': rankings,
    'source': 'cbbd',
    'updatedAt': '2026-06-01T12:00:00-04:00',
    'confidence': 'official',
  });
}

TeamStat _footballStat() {
  return TeamStat.fromJson(<String, dynamic>{
    'id': 'kentucky_football_2025_season',
    'teamId': 'kentucky_football',
    'season': 2025,
    'sport': 'football',
    'stats': <String, dynamic>{'pointsPerGame': 28.5},
    'source': 'cfbd',
    'confidence': 'official',
  });
}

Future<void> _pumpHome(WidgetTester tester, List<TeamStat> stats) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        dataSourceProvider.overrideWithValue(_FakeDataSource(stats: stats)),
      ],
      child: MaterialApp(theme: BgTheme.light(), home: const HomeScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// Flushes the Vault data source's simulated-latency timers (the "From the
/// Vault" tile loads the real asset) so no timer outlives the test.
Future<void> _settleVaultTimers(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 250));
}

Article _demoArticle({String confidence = 'demo'}) {
  return Article.fromJson(<String, dynamic>{
    'id': 'a1',
    'type': 'preview',
    'gameId': 'g1',
    'sport': 'football',
    'status': 'published',
    'headline': 'Headline',
    'openingNarrative': 'Opening.',
    'sources': <String>['seed_demo:team_stats/x'],
    'confidence': confidence,
  });
}

void main() {
  group('Home Stat of the Day — honesty', () {
    testWidgets('renders no percentile or rank when the doc has none',
        (WidgetTester tester) async {
      await _pumpHome(tester, <TeamStat>[_bballStat()]);

      await tester.scrollUntilVisible(find.text('Stat of the Day'), 300);
      expect(find.text('Stat of the Day'), findsOneWidget);
      expect(find.text('55.2%'), findsOneWidget);
      // No doc percentile/rank -> no bar, no tier word, no SEC claim.
      expect(find.textContaining('%ile'), findsNothing);
      expect(find.textContaining('in the SEC'), findsNothing);
      await _settleVaultTimers(tester);
    });

    testWidgets('renders percentile + rank when the doc carries them',
        (WidgetTester tester) async {
      await _pumpHome(tester, <TeamStat>[
        _bballStat(rankings: <String, dynamic>{
          'effectiveFgPctPercentile': 82,
          'effectiveFgPctSEC': 3,
        }),
      ]);

      await tester.scrollUntilVisible(find.text('Stat of the Day'), 300);
      expect(find.textContaining('82%ile'), findsOneWidget);
      expect(find.text('#3 in the SEC'), findsOneWidget);
      await _settleVaultTimers(tester);
    });

    testWidgets('renders nothing without a basketball doc (no fallback)',
        (WidgetTester tester) async {
      await _pumpHome(tester, <TeamStat>[_footballStat()]);

      // Scroll through the whole hub — the section must never appear.
      await tester.scrollUntilVisible(find.text('The Vault'), 300);
      expect(find.text('Stat of the Day'), findsNothing);
      expect(find.textContaining('%ile'), findsNothing);
      await _settleVaultTimers(tester);
    });
  });

  group('Article AI attribution — derives from confidence', () {
    Widget wrap(Widget child) => MaterialApp(
          theme: BgTheme.light(),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        );

    testWidgets('demo articles say demo stats', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(GamedayStoryCard(article: _demoArticle())),
      );
      await tester.pump();
      expect(
        find.text('Generated by Bluegrass Gameday AI from demo stats'),
        findsOneWidget,
      );
      expect(find.textContaining('from official stats'), findsNothing);
    });

    testWidgets('official articles say official stats',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(GamedayStoryCard(article: _demoArticle(confidence: 'official'))),
      );
      await tester.pump();
      expect(
        find.text('Generated by Bluegrass Gameday AI from official stats'),
        findsOneWidget,
      );
    });

    testWidgets('researched articles say researched stats — never official',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(GamedayStoryCard(article: _demoArticle(confidence: 'researched'))),
      );
      await tester.pump();
      expect(
        find.text('Generated by Bluegrass Gameday AI from researched stats'),
        findsOneWidget,
      );
      expect(find.textContaining('from official stats'), findsNothing);
    });

    testWidgets('fan_rumor and unknown tiers fall back to neutral wording',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(GamedayStoryCard(article: _demoArticle(confidence: 'fan_rumor'))),
      );
      await tester.pump();
      expect(
        find.text('Generated by Bluegrass Gameday AI from stored stats'),
        findsOneWidget,
      );
      expect(find.textContaining('from official stats'), findsNothing);

      await tester.pumpWidget(
        wrap(GamedayStoryCard(
            article: _demoArticle(confidence: 'brand_new_tier'))),
      );
      await tester.pump();
      expect(
        find.text('Generated by Bluegrass Gameday AI from stored stats'),
        findsOneWidget,
      );
      expect(find.textContaining('from official stats'), findsNothing);
    });
  });

  group('CountdownStrip — ticks, sport copy, disposal', () {
    Widget wrap(Widget child) => MaterialApp(
          theme: BgTheme.light(),
          home: Scaffold(body: child),
        );

    testWidgets('renders the segmented countdown and survives ticks',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(CountdownStrip(
          target: DateTime.now()
              .add(const Duration(days: 2, hours: 3, minutes: 30)),
          sport: 'football',
        )),
      );
      await tester.pump();
      expect(find.text('02'), findsOneWidget); // days block
      expect(find.text('DAYS'), findsOneWidget);

      // Let the periodic timer fire (30s cadence), then dispose cleanly —
      // a leaked Timer would fail the test with a pending-timer error.
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpWidget(wrap(const SizedBox()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('live state uses sport-correct copy',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(CountdownStrip(
          target: DateTime.now().subtract(const Duration(minutes: 5)),
          sport: 'mens_basketball',
        )),
      );
      await tester.pump();
      expect(find.text('Game time! Tipoff is here.'), findsOneWidget);
      expect(find.textContaining('Kickoff'), findsNothing);

      await tester.pumpWidget(wrap(const SizedBox()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('already-live target schedules no timer at all',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(CountdownStrip(
          target: DateTime.now().subtract(const Duration(minutes: 5)),
          sport: 'football',
        )),
      );
      await tester.pump();
      expect(find.text('Game time! Kickoff is here.'), findsOneWidget);

      // The live banner is static — no periodic timer may be scheduled.
      final dynamic state = tester.state(find.byType(CountdownStrip));
      expect(state.isTicking, isFalse);
    });

    testWidgets('cancels its own timer once the countdown reaches game time',
        (WidgetTester tester) async {
      // Injected clock so the test controls "now" (tester.pump advances the
      // fake async timers, not the wall clock).
      DateTime now = DateTime(2026, 9, 5, 18, 59, 30);
      await tester.pumpWidget(
        wrap(CountdownStrip(
          target: DateTime(2026, 9, 5, 19),
          sport: 'football',
          clock: () => now,
        )),
      );
      await tester.pump();
      expect(find.text('MIN'), findsOneWidget); // still counting down
      final dynamic state = tester.state(find.byType(CountdownStrip));
      expect(state.isTicking, isTrue);

      // Cross game time, then let one 30s tick fire: the strip flips to the
      // static live banner and cancels the periodic timer from the tick.
      now = DateTime(2026, 9, 5, 19, 0, 1);
      await tester.pump(const Duration(seconds: 31));
      expect(find.text('Game time! Kickoff is here.'), findsOneWidget);
      expect(state.isTicking, isFalse);

      // Dispose still cleans up without a leaked-timer exception.
      await tester.pumpWidget(wrap(const SizedBox()));
      expect(tester.takeException(), isNull);
    });
  });

  group('CompareRow — tie honesty (no unearned Kentucky edge)', () {
    Widget wrap(Widget child) => MaterialApp(
          theme: BgTheme.light(),
          home: Scaffold(body: child),
        );

    test('compareEdge is strict: equal values tie, nobody wins', () {
      final ({bool kentuckyWins, bool tie}) even =
          compareEdge(kentucky: 80.2, opponent: 80.2, higherIsBetter: true);
      expect(even.tie, isTrue);
      expect(even.kentuckyWins, isFalse);

      final ({bool kentuckyWins, bool tie}) up =
          compareEdge(kentucky: 81.0, opponent: 80.2, higherIsBetter: true);
      expect(up.kentuckyWins, isTrue);
      expect(up.tie, isFalse);

      // Lower-is-better metrics honor direction (e.g. points allowed).
      final ({bool kentuckyWins, bool tie}) down =
          compareEdge(kentucky: 68.0, opponent: 74.0, higherIsBetter: false);
      expect(down.kentuckyWins, isTrue);
      expect(down.tie, isFalse);

      final ({bool kentuckyWins, bool tie}) lost =
          compareEdge(kentucky: 74.0, opponent: 68.0, higherIsBetter: false);
      expect(lost.kentuckyWins, isFalse);
      expect(lost.tie, isFalse);
    });

    testWidgets('tied values render neutral dots and muted values',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const CompareRow(
        label: 'PPG',
        kentuckyText: '80.2',
        opponentText: '80.2',
        kentuckyWins: false,
        tie: true,
      )));
      await tester.pump();

      final ColorScheme scheme = BgTheme.light().colorScheme;
      final List<Text> values =
          tester.widgetList<Text>(find.text('80.2')).toList();
      expect(values.length, 2);
      for (final Text value in values) {
        expect(value.style?.color, scheme.onSurfaceVariant);
      }

      // Both dots stay the inactive outline color — neither side highlights.
      final List<Container> dots = tester
          .widgetList<Container>(find.byType(Container))
          .where((Container c) =>
              c.decoration is BoxDecoration &&
              (c.decoration! as BoxDecoration).shape == BoxShape.circle)
          .toList();
      expect(dots.length, 2);
      for (final Container dot in dots) {
        expect((dot.decoration! as BoxDecoration).color, scheme.outline);
      }
    });

    testWidgets('a real edge still highlights the winning side',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const CompareRow(
        label: 'PPG',
        kentuckyText: '84.1',
        opponentText: '80.2',
        kentuckyWins: true,
      )));
      await tester.pump();

      final ColorScheme scheme = BgTheme.light().colorScheme;
      final Text ky = tester.widget<Text>(find.text('84.1'));
      final Text opp = tester.widget<Text>(find.text('80.2'));
      expect(ky.style?.color, scheme.primary);
      expect(opp.style?.color, scheme.onSurfaceVariant);
    });
  });
}
