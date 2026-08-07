// Unit tests for the honesty-critical game logic:
//  - Game.kentuckyWon tri-state derivation (result string, score fallback,
//    unknown), for home AND away games,
//  - Fmt.countdownParts / Fmt.countdown time math with a fixed `from`,
//  - Fmt.startVerb sport-correct copy.

import 'package:bluegrass_gameday/core/models/models.dart';
import 'package:bluegrass_gameday/core/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

Game _game(Map<String, dynamic> overrides) {
  return Game.fromJson(<String, dynamic>{
    'id': 'g',
    'season': 2025,
    'sport': 'football',
    'homeTeamId': 'kentucky_football',
    'awayTeamId': 'opp',
    'opponentName': 'Opponent',
    'opponentShort': 'OPP',
    'status': 'final',
    'isHome': true,
    ...overrides,
  });
}

void main() {
  group('Game.kentuckyWon — tri-state derivation', () {
    test('explicit result wins over everything', () {
      expect(_game(<String, dynamic>{'result': 'win'}).kentuckyWon, isTrue);
      expect(_game(<String, dynamic>{'result': 'loss'}).kentuckyWon, isFalse);
    });

    test('null result derives from scores (home game)', () {
      expect(
        _game(<String, dynamic>{'homeScore': 48, 'awayScore': 23}).kentuckyWon,
        isTrue,
      );
      expect(
        _game(<String, dynamic>{'homeScore': 10, 'awayScore': 24}).kentuckyWon,
        isFalse,
      );
    });

    test('null result derives from scores (away game — sides swap)', () {
      final Game awayWin = _game(<String, dynamic>{
        'isHome': false,
        'homeScore': 20,
        'awayScore': 27,
      });
      expect(awayWin.kentuckyScore, 27);
      expect(awayWin.opponentScore, 20);
      expect(awayWin.kentuckyWon, isTrue);

      final Game awayLoss = _game(<String, dynamic>{
        'isHome': false,
        'homeScore': 31,
        'awayScore': 14,
      });
      expect(awayLoss.kentuckyWon, isFalse);
    });

    test('unknown when result and scores are both missing', () {
      expect(_game(<String, dynamic>{}).kentuckyWon, isNull);
      expect(
        _game(<String, dynamic>{'homeScore': 21}).kentuckyWon,
        isNull,
      );
    });

    test('a tie is not reported as a win or a loss', () {
      expect(
        _game(<String, dynamic>{'homeScore': 17, 'awayScore': 17}).kentuckyWon,
        isNull,
      );
    });
  });

  group('Fmt.countdownParts — fixed-clock math', () {
    final DateTime from = DateTime(2026, 9, 5, 12, 0);

    test('splits days / hours / minutes', () {
      final DateTime target =
          from.add(const Duration(days: 2, hours: 3, minutes: 45));
      final ({int days, int hours, int minutes, bool live}) p =
          Fmt.countdownParts(target, from: from);
      expect(p.days, 2);
      expect(p.hours, 3);
      expect(p.minutes, 45);
      expect(p.live, isFalse);
    });

    test('goes live once the target is in the past', () {
      final ({int days, int hours, int minutes, bool live}) p =
          Fmt.countdownParts(
        from.subtract(const Duration(minutes: 1)),
        from: from,
      );
      expect(p.live, isTrue);
      expect(p.days, 0);
    });

    test('null target renders zeros and is not live', () {
      final ({int days, int hours, int minutes, bool live}) p =
          Fmt.countdownParts(null);
      expect(p.days, 0);
      expect(p.hours, 0);
      expect(p.minutes, 0);
      expect(p.live, isFalse);
    });

    test('countdown string variants', () {
      expect(
        Fmt.countdown(from.add(const Duration(days: 12, hours: 4)),
            from: from),
        '12d 4h',
      );
      expect(
        Fmt.countdown(from.add(const Duration(hours: 4, minutes: 12)),
            from: from),
        '4h 12m',
      );
      expect(
        Fmt.countdown(from.subtract(const Duration(hours: 1)), from: from),
        'In progress',
      );
    });
  });

  group('Fmt.startVerb — sport-correct copy', () {
    test('maps each sport to its verb', () {
      expect(Fmt.startVerb('football'), 'Kickoff');
      expect(Fmt.startVerb('mens_basketball'), 'Tipoff');
      expect(Fmt.startVerb('womens_basketball'), 'Tipoff');
      expect(Fmt.startVerb('baseball'), 'First pitch');
      expect(Fmt.startVerb('volleyball'), 'First serve');
    });

    test('unknown sports return null so callers use neutral copy', () {
      expect(Fmt.startVerb('curling'), isNull);
    });
  });
}
