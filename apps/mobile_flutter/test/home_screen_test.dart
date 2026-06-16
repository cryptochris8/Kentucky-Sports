// Integration-style test: the Home Bento hub renders the greeting, the
// featured-game hero tile, and the "Your Picks" + "Leaderboard" tiles that
// surface Predictions.
//
// We override the data source with an in-memory fake (no seed asset, no
// network) so the real HomeScreen + providers render deterministically.

import 'package:bluegrass_gameday/app/theme/theme.dart';
import 'package:bluegrass_gameday/core/data/app_data_source.dart';
import 'package:bluegrass_gameday/core/models/models.dart';
import 'package:bluegrass_gameday/core/providers/data_providers.dart';
import 'package:bluegrass_gameday/features/home/home_screen.dart';
// Hide Material's Badge widget so our Badge model name is unambiguous.
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal fake returning a single upcoming game + matching user.
class _FakeDataSource implements AppDataSource {
  @override
  Future<AppConfigDoc> appConfig() async => AppConfigDoc.fromJson(
        <String, dynamic>{'id': 'main', 'independentFanDisclaimer': 'Demo.'},
      );

  @override
  Future<List<Game>> games() async => <Game>[
        Game.fromJson(<String, dynamic>{
          'id': 'fb_next',
          'season': 2099,
          'sport': 'football',
          'homeTeamId': 'kentucky_football',
          'awayTeamId': 'opp_youngstown_state',
          'opponentName': 'Youngstown State',
          'opponentShort': 'YSU',
          // Far-future so it is unambiguously the "next" game.
          'startTime': '2099-09-05T19:00:00-04:00',
          'venue': 'Kroger Field',
          'status': 'scheduled',
          'featured': true,
          'isHome': true,
        }),
      ];

  @override
  Future<List<AppUser>> users() async => <AppUser>[
        AppUser.fromJson(<String, dynamic>{
          'id': 'demo_user_self',
          'displayName': 'You',
          'xp': 1280,
          'level': 3,
          'predictionRecord': <String, dynamic>{
            'total': 8,
            'correct': 5,
            'streak': 2,
          },
        }),
      ];

  // Everything else is empty for this test.
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

void main() {
  testWidgets('Home hub renders the greeting, the gameday hero, and the '
      'picks/leaderboard tiles', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          dataSourceProvider.overrideWithValue(_FakeDataSource()),
        ],
        child: MaterialApp(
          theme: BgTheme.light(),
          home: const HomeScreen(),
        ),
      ),
    );

    // Let the FutureProviders resolve.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The greeting uses the seed user's display name.
    expect(find.text('You'), findsWidgets);

    // The matchup hero shows Kentucky vs the opponent.
    expect(find.text('Kentucky'), findsWidgets);
    expect(find.text('Youngstown State'), findsWidgets);

    // The hub surfaces Predictions via the Your Picks + Leaderboard tiles
    // (scroll them into view — they sit below the gameday hero).
    await tester.scrollUntilVisible(find.text('YOUR PICKS'), 300);
    expect(find.text('YOUR PICKS'), findsOneWidget);
    expect(find.text('LEADERBOARD'), findsOneWidget);

    // The Explore row scales the hub to the vision's pillars.
    await tester.scrollUntilVisible(find.text('The Vault'), 300);
    expect(find.text('The Vault'), findsOneWidget);
    expect(find.text('Bluegrass Preps'), findsOneWidget);
  });
}
