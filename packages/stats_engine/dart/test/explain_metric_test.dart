import 'package:stats_engine/stats_engine.dart';
import 'package:test/test.dart';

void main() {
  group('explainMetric', () {
    test('returns non-empty explanation for known football metric', () {
      final String e = explainMetric('turnoverMargin', sport: 'football');
      expect(e, isNotEmpty);
      expect(e.toLowerCase(), contains('turnover'));
    });

    test('returns non-empty explanation for known basketball metric', () {
      final String e = explainMetric('effectiveFgPct', sport: 'mens_basketball');
      expect(e, isNotEmpty);
      expect(e.toLowerCase(), contains('three'));
    });

    test('falls back gracefully for unknown key', () {
      final String e = explainMetric('madeUpKey', sport: 'football');
      expect(e, isNotEmpty);
    });
  });

  group('fanLabel', () {
    test('maps effectiveFgPct to Shot Quality', () {
      expect(fanLabel('effectiveFgPct', sport: 'mens_basketball'),
          'Shot Quality');
    });

    test('maps redZoneScorePct to Drive Finisher', () {
      expect(fanLabel('redZoneScorePct', sport: 'football'), 'Drive Finisher');
    });
  });

  group('formatMetricValue', () {
    test('renders percent metrics with % sign', () {
      expect(formatMetricValue('effectiveFgPct', 0.552,
          sport: 'mens_basketball'), '55.2%');
    });

    test('renders whole numbers without decimals', () {
      expect(formatMetricValue('pointsPerGame', 84.0,
          sport: 'mens_basketball'), '84');
    });

    test('renders decimals with one place', () {
      expect(formatMetricValue('yardsPerPlay', 5.9, sport: 'football'), '5.9');
    });
  });

  group('buildStatStory', () {
    test('names the team with the edge', () {
      final String story = buildStatStory(
        key: 'effectiveFgPct',
        kentuckyValue: 0.552,
        opponentValue: 0.561,
        opponentName: 'Duke',
        sport: 'mens_basketball',
      );
      // Opponent has higher eFG%, so Duke holds the edge.
      expect(story, contains('Duke'));
      expect(story, contains('plain English'));
    });
  });

  group('percentile helpers', () {
    test('percentileOf places a top value high', () {
      final List<double> pop = <double>[10, 20, 30, 40, 50];
      expect(percentileOf(50, pop), 100);
      expect(percentileOf(10, pop), 20);
    });

    test('lowerIsBetter inverts the percentile', () {
      final List<double> pop = <double>[10, 20, 30, 40, 50];
      // A low value (good when lowerIsBetter) should rank high.
      expect(percentileOf(10, pop, lowerIsBetter: true), 80);
    });

    test('tierForPercentile maps bands correctly', () {
      expect(tierForPercentile(95), PercentileTier.elite);
      expect(tierForPercentile(80), PercentileTier.excellent);
      expect(tierForPercentile(60), PercentileTier.good);
      expect(tierForPercentile(40), PercentileTier.average);
      expect(tierForPercentile(10), PercentileTier.belowAverage);
    });

    test('evaluatePercentile honors knownPercentile', () {
      final PercentileResult r = evaluatePercentile(
        metric: 'effectiveFgPct',
        value: 0.552,
        knownPercentile: 82,
      );
      expect(r.percentile, 82);
      expect(r.tier, PercentileTier.excellent);
      expect(r.explanation, isNotEmpty);
    });
  });

  group('four factors', () {
    test('extracts available factors from a stats map', () {
      final List<FourFactorValue> vals = extractFourFactors(<String, dynamic>{
        'effectiveFgPct': 0.552,
        'turnoverRate': 0.151,
        'offReboundRate': 0.341,
        'freeThrowRate': 0.362,
      });
      expect(vals.length, 4);
      expect(vals.first.factor.key, 'effectiveFgPct');
    });

    test('skips missing factors', () {
      final List<FourFactorValue> vals = extractFourFactors(<String, dynamic>{
        'effectiveFgPct': 0.552,
      });
      expect(vals.length, 1);
    });
  });

  group('football composites', () {
    test('chaosFactorScore is within 0..100', () {
      final double s = chaosFactorScore(<String, dynamic>{
        'sacksPerGame': 2.4,
        'turnoverMargin': 0.5,
      });
      expect(s, inInclusiveRange(0.0, 100.0));
    });
  });
}
