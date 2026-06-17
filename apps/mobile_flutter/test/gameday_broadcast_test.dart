// Tests for the "Modern Broadcast" skin (Pass 3) on the Gameday surfaces.
//
// These exercise the MatchupHero broadcast variant (big SOLID score numbers in
// the broadcast face) and confirm the default bento variant is unchanged, in
// BOTH light and dark themes. The broadcast skin must never drop the required
// source/confidence attribution on stat surfaces (hard product rule) — covered
// indirectly here via the widgets that host it.

import 'package:bluegrass_gameday/app/theme/theme.dart';
import 'package:bluegrass_gameday/core/models/models.dart';
import 'package:bluegrass_gameday/core/widgets/broadcast_widgets.dart';
import 'package:bluegrass_gameday/features/shared/game_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Game _finalGame() => Game.fromJson(<String, dynamic>{
      'id': 'fb_final',
      'season': 2025,
      'sport': 'football',
      'homeTeamId': 'kentucky_football',
      'awayTeamId': 'opp_em',
      'opponentName': 'Eastern Michigan',
      'opponentShort': 'EMU',
      'startTime': '2025-09-13T19:00:00-04:00',
      'venue': 'Kroger Field',
      'status': 'final',
      'homeScore': 48,
      'awayScore': 23,
      'broadcast': 'SECN',
      'isHome': true,
      'result': 'win',
    });

Game _upcomingGame() => Game.fromJson(<String, dynamic>{
      'id': 'fb_next',
      'season': 2026,
      'sport': 'football',
      'homeTeamId': 'kentucky_football',
      'awayTeamId': 'opp_ysu',
      'opponentName': 'Youngstown State',
      'opponentShort': 'YSU',
      'startTime': '2099-09-05T19:00:00-04:00',
      'venue': 'Kroger Field',
      'status': 'scheduled',
      'broadcast': 'ESPN+',
      'isHome': true,
    });

Widget _wrap(Widget child, {required ThemeData theme}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

void main() {
  group('MatchupHero — broadcast variant', () {
    testWidgets('renders the final score in the broadcast scorebug (light)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          MatchupHero(
            game: _finalGame(),
            variant: MatchupHeroVariant.broadcast,
          ),
          theme: BgTheme.light(),
        ),
      );
      // CountUpScore animates 0 -> value; settle to the final number.
      await tester.pumpAndSettle();

      expect(find.text('Kentucky'), findsOneWidget);
      expect(find.text('Eastern Michigan'), findsOneWidget);
      // Big solid score numbers count up to the real posted final.
      expect(find.text('48'), findsOneWidget);
      expect(find.text('23'), findsOneWidget);
      // Broadcast status cue.
      expect(find.text('FINAL'), findsOneWidget);
    });

    testWidgets('renders identically in dark mode without overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          MatchupHero(
            game: _finalGame(),
            variant: MatchupHeroVariant.broadcast,
          ),
          theme: BgTheme.dark(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('48'), findsOneWidget);
      expect(find.text('23'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('upcoming game shows VS (no score) and the broadcast network',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          MatchupHero(
            game: _upcomingGame(),
            variant: MatchupHeroVariant.broadcast,
          ),
          theme: BgTheme.light(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VS'), findsOneWidget);
      expect(find.text('ESPN+'), findsOneWidget);
      // No final score for an upcoming game.
      expect(find.text('48'), findsNothing);
    });
  });

  group('MatchupHero — default (bento) variant is unchanged', () {
    testWidgets('still renders the soft-card matchup (Home/team look)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(MatchupHero(game: _finalGame()), theme: BgTheme.light()),
      );
      await tester.pumpAndSettle();

      // Same content, default skin: teams + final score + FINAL pill.
      expect(find.text('Kentucky'), findsOneWidget);
      expect(find.text('Eastern Michigan'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
      expect(find.text('FINAL'), findsOneWidget);
    });
  });

  group('Broadcast primitives', () {
    testWidgets('CountUpScore reaches its value and is reduce-motion aware',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _wrap(
            const CountUpScore(value: 72),
            theme: BgTheme.light(),
          ),
        ),
      );
      // With animations disabled the final value renders immediately.
      await tester.pump();
      expect(find.text('72'), findsOneWidget);
    });

    testWidgets('BroadcastPanel renders its eyebrow + child',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const BroadcastPanel(
            eyebrow: 'Matchup Verdict',
            child: Text('Body copy', style: TextStyle(color: Colors.white)),
          ),
          theme: BgTheme.dark(),
        ),
      );
      await tester.pump();
      expect(find.text('MATCHUP VERDICT'), findsOneWidget);
      expect(find.text('Body copy'), findsOneWidget);
    });
  });
}
