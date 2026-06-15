// Widget + unit tests for Bluegrass Gameday.
//
// These tests avoid loading the full app (which would hit google_fonts and the
// seed asset bundle). Instead they exercise the StatCard rendering contract and
// the stats_engine level math the app relies on.

import 'package:bluegrass_gameday/app/theme/theme.dart';
import 'package:bluegrass_gameday/core/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stats_engine/stats_engine.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: BgTheme.light(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  testWidgets('StatCard shows its value, label, and source attribution',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        StatCard.fromMetric(
          metricKey: 'effectiveFgPct',
          value: 0.552,
          sport: 'mens_basketball',
          source: 'seed_demo',
          updatedAt: DateTime(2026, 6, 1),
          confidence: 'demo',
          percentile: 82,
        ),
      ),
    );
    await tester.pump();

    // Fan label + formatted value.
    expect(find.text('SHOT QUALITY'), findsOneWidget);
    expect(find.text('55.2%'), findsOneWidget);

    // REQUIRED attribution: source + confidence are visible on the card.
    expect(find.textContaining('Source: seed_demo'), findsOneWidget);
    expect(find.textContaining('Demo data'), findsOneWidget);
  });

  testWidgets('StatCard "What this means" reveals the explanation on tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        StatCard.fromMetric(
          metricKey: 'turnoverMargin',
          value: 0.5,
          sport: 'football',
          source: 'seed_demo',
          updatedAt: DateTime(2026, 1, 5),
          confidence: 'demo',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('What this means'), findsOneWidget);
    await tester.tap(find.text('What this means'));
    await tester.pumpAndSettle();

    expect(find.textContaining('turnover battle'), findsOneWidget);
  });

  group('stats_engine level math (used across the app)', () {
    test('seed user at 1280 XP resolves to level 3', () {
      expect(levelForXp(1280), 3);
    });

    test('level names match the doc tiers', () {
      expect(levelName(1), 'Walk-On');
      expect(levelName(4), 'Gameday Captain');
    });

    test('formatMetricValue renders percent metrics', () {
      expect(
        formatMetricValue('effectiveFgPct', 0.552, sport: 'mens_basketball'),
        '55.2%',
      );
    });
  });
}
