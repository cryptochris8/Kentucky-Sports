/// TS<->Dart parity fixtures.
///
/// Every value asserted here is also asserted by the TypeScript suite
/// (packages/stats_engine/typescript/src/__tests__/stats.test.ts). If a
/// fixture changes on one side, change the other in the same commit — the two
/// implementations must stay value-for-value and word-for-word identical.
library;

import 'package:stats_engine/stats_engine.dart';
import 'package:test/test.dart';

void main() {
  group('percentile parity (mid-rank formula)', () {
    test('shared fixtures match the TypeScript percentileRank', () {
      final List<double> pop = <double>[10, 20, 30, 40, 50];
      expect(percentileOf(50, pop), 90);
      expect(percentileOf(10, pop), 10);
      expect(percentileOf(10, pop, lowerIsBetter: true), 90);
      final List<double> pop10 =
          <double>[10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
      expect(percentileOf(30, pop10), 25);
      expect(percentileOf(50, <double>[]), isNull);
    });

    test('tier ladder matches the TypeScript percentileLabel bands', () {
      expect(tierForPercentile(95).label, 'Elite');
      expect(tierForPercentile(80).label, 'Excellent');
      expect(tierForPercentile(60).label, 'Good');
      expect(tierForPercentile(50).label, 'Average');
      expect(tierForPercentile(34).label, 'Below Average');
      expect(tierForPercentile(5).label, 'Below Average');
    });
  });

  group('football composites parity', () {
    test('driveFinisherScore blends red zone and PPG 50/50', () {
      expect(
          driveFinisherScore(
              <String, dynamic>{'redZoneScorePct': 0.86, 'pointsPerGame': 29.4}),
          72);
      expect(
          driveFinisherScore(
              <String, dynamic>{'redZoneScorePct': 1.2, 'pointsPerGame': 60}),
          100); // both terms capped
      expect(
          driveFinisherScore(
              <String, dynamic>{'redZoneScorePct': 0, 'pointsPerGame': 0}),
          0);
      // pointsPerGame must matter: elite red zone + no offense is NOT a 100.
      expect(
          driveFinisherScore(
              <String, dynamic>{'redZoneScorePct': 0.9, 'pointsPerGame': 0}),
          45);
    });

    test('chaosFactorScore blends sacks and turnover margin 50/50', () {
      expect(
          chaosFactorScore(
              <String, dynamic>{'sacksPerGame': 2.4, 'turnoverMargin': 0.5}),
          53);
      expect(
          chaosFactorScore(
              <String, dynamic>{'sacksPerGame': 3.0, 'turnoverMargin': 1.0}),
          63);
      expect(
          chaosFactorScore(
              <String, dynamic>{'sacksPerGame': 6, 'turnoverMargin': 4}),
          100); // both terms capped
      // Each term floors at 0 — a terrible margin cannot go negative and
      // cancel the sack component.
      expect(
          chaosFactorScore(
              <String, dynamic>{'sacksPerGame': 0, 'turnoverMargin': -4}),
          0);
      expect(
          chaosFactorScore(
              <String, dynamic>{'sacksPerGame': 5, 'turnoverMargin': -4}),
          50);
    });
  });

  group('stat-story verdict parity', () {
    test('Kentucky-favoring verdict matches the TS explainMetric wording', () {
      final String story = buildStatStory(
        key: 'effectiveFgPct',
        kentuckyValue: 0.552,
        opponentValue: 0.53,
        opponentName: 'Duke',
        sport: 'mens_basketball',
      );
      expect(story, startsWith('Kentucky holds the edge in Shot Quality.'));
    });

    test('opponent-favoring verdict names the opponent', () {
      final String story = buildStatStory(
        key: 'effectiveFgPct',
        kentuckyValue: 0.552,
        opponentValue: 0.561,
        opponentName: 'Duke',
        sport: 'mens_basketball',
      );
      expect(story, startsWith('Duke has the edge in Shot Quality.'));
    });

    test('equal values read as even — no manufactured Kentucky edge', () {
      final String story = buildStatStory(
        key: 'effectiveFgPct',
        kentuckyValue: 0.55,
        opponentValue: 0.55,
        opponentName: 'Duke',
        sport: 'mens_basketball',
      );
      expect(story, startsWith('Kentucky and Duke are even in Shot Quality.'));
    });

    test('lower-is-better metrics honor direction', () {
      // Kentucky allows fewer points -> Kentucky holds the edge.
      final String story = buildStatStory(
        key: 'pointsAllowedPerGame',
        kentuckyValue: 68.0,
        opponentValue: 74.0,
        opponentName: 'Louisville',
        sport: 'mens_basketball',
      );
      expect(story, startsWith('Kentucky holds the edge in Defense.'));
    });
  });
}
