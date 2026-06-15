import 'package:stats_engine/stats_engine.dart';
import 'package:test/test.dart';

void main() {
  group('xpForLevel', () {
    test('matches doc anchor thresholds', () {
      expect(xpForLevel(1), 0);
      expect(xpForLevel(2), 250);
      expect(xpForLevel(3), 750);
      expect(xpForLevel(4), 1500);
      expect(xpForLevel(5), 3000);
      expect(xpForLevel(10), 15000);
      expect(xpForLevel(25), 100000);
    });

    test('interpolates between anchors monotonically', () {
      expect(xpForLevel(6), greaterThan(xpForLevel(5)));
      expect(xpForLevel(6), lessThan(xpForLevel(10)));
      expect(xpForLevel(7), greaterThan(xpForLevel(6)));
    });
  });

  group('levelForXp', () {
    test('seed user "self" at 1280 XP is level 3', () {
      // 1280 is past L3 (750) but below L4 (1500).
      expect(levelForXp(1280), 3);
    });

    test('seed admin at 5400 XP is level 6', () {
      // 5400 is past L5 (3000); interpolated L6 < 5400.
      expect(levelForXp(5400), greaterThanOrEqualTo(6));
    });

    test('zero XP is level 1', () {
      expect(levelForXp(0), 1);
    });

    test('exact threshold lands on that level', () {
      expect(levelForXp(3000), 5);
      expect(levelForXp(15000), 10);
    });
  });

  group('levelName', () {
    test('level 1 is Walk-On', () {
      expect(levelName(1), 'Walk-On');
    });

    test('level 4 is Gameday Captain', () {
      expect(levelName(4), 'Gameday Captain');
    });

    test('level 10+ is Big Blue Oracle', () {
      expect(levelName(12), 'Big Blue Oracle');
    });
  });

  group('levelProgress / xpToNextLevel', () {
    test('progress is between 0 and 1', () {
      final double p = levelProgress(1280);
      expect(p, inInclusiveRange(0.0, 1.0));
    });

    test('xpToNextLevel is positive below cap', () {
      expect(xpToNextLevel(1280), greaterThan(0));
    });

    test('levelInfoForXp returns consistent snapshot', () {
      final LevelInfo info = levelInfoForXp(1280);
      expect(info.level, 3);
      expect(info.xpIntoLevel, 1280 - xpForLevel(3));
      expect(info.xpRemaining, xpForLevel(4) - 1280);
    });
  });
}
