/// XP / level helpers (docs/07 — Levels).
///
/// Level thresholds are interpolated from the doc's anchor points so every
/// level 1..25 has a sensible XP requirement.
library;

/// Anchor thresholds from docs/07 (level -> cumulative XP required).
const Map<int, int> _anchorThresholds = <int, int>{
  1: 0,
  2: 250,
  3: 750,
  4: 1500,
  5: 3000,
  10: 15000,
  25: 100000,
};

/// Level display names from docs/07 (indexed loosely by tier).
const List<String> levelNames = <String>[
  'Walk-On', // L1
  'Bluegrass Believer', // L2
  'Film Room Fan', // L3
  'Gameday Captain', // L4
  'Stats Lab Legend', // L5+
  'Rupp Roarer', // L6+
  'Kroger Field General', // L8+
  'Big Blue Oracle', // L10+
];

/// Returns the cumulative XP required to reach [level] (1-based).
///
/// Levels between anchor points are linearly interpolated and rounded.
int xpForLevel(int level) {
  if (level <= 1) return 0;
  if (_anchorThresholds.containsKey(level)) return _anchorThresholds[level]!;

  // Find the surrounding anchor levels.
  final List<int> anchors = _anchorThresholds.keys.toList()..sort();
  int lower = anchors.first;
  int upper = anchors.last;
  for (int i = 0; i < anchors.length - 1; i++) {
    if (level > anchors[i] && level < anchors[i + 1]) {
      lower = anchors[i];
      upper = anchors[i + 1];
      break;
    }
  }
  if (level > anchors.last) return _anchorThresholds[anchors.last]!;

  final int lowerXp = _anchorThresholds[lower]!;
  final int upperXp = _anchorThresholds[upper]!;
  final double t = (level - lower) / (upper - lower);
  return (lowerXp + (upperXp - lowerXp) * t).round();
}

/// Computes the level for a given [xp] total.
int levelForXp(int xp) {
  int level = 1;
  for (int candidate = 1; candidate <= 25; candidate++) {
    if (xp >= xpForLevel(candidate)) {
      level = candidate;
    } else {
      break;
    }
  }
  return level;
}

/// Returns the level name for a [level].
String levelName(int level) {
  if (level <= 1) return levelNames[0];
  if (level >= 10) return levelNames[7];
  if (level >= 8) return levelNames[6];
  if (level >= 6) return levelNames[5];
  if (level >= 5) return levelNames[4];
  // Levels 2,3,4 map directly.
  return levelNames[(level - 1).clamp(0, levelNames.length - 1)];
}

/// Progress (0.0..1.0) from the start of the current level toward the next.
double levelProgress(int xp) {
  final int level = levelForXp(xp);
  final int floor = xpForLevel(level);
  final int next = xpForLevel(level + 1);
  if (next <= floor) return 1.0;
  return ((xp - floor) / (next - floor)).clamp(0.0, 1.0);
}

/// XP remaining until the next level.
int xpToNextLevel(int xp) {
  final int level = levelForXp(xp);
  final int next = xpForLevel(level + 1);
  return (next - xp).clamp(0, next);
}

/// A snapshot of a user's level state for rendering.
class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.name,
    required this.progress,
    required this.xpIntoLevel,
    required this.xpForNext,
    required this.xpRemaining,
  });

  final int level;
  final String name;
  final double progress;
  final int xpIntoLevel;
  final int xpForNext;
  final int xpRemaining;
}

/// Builds a full [LevelInfo] snapshot from an [xp] total.
LevelInfo levelInfoForXp(int xp) {
  final int level = levelForXp(xp);
  final int floor = xpForLevel(level);
  final int next = xpForLevel(level + 1);
  return LevelInfo(
    level: level,
    name: levelName(level),
    progress: levelProgress(xp),
    xpIntoLevel: xp - floor,
    xpForNext: next - floor,
    xpRemaining: xpToNextLevel(xp),
  );
}
