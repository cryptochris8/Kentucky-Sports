/// Dart domain models for Bluegrass Gameday, mirroring docs/04 (Firebase Data
/// Model) and the shapes in seed_data/dev_seed.json.
///
/// These are deliberately permissive: `fromJson` tolerates missing/null fields
/// so demo seed data and future Firestore documents both parse cleanly.
library;

/// Safe numeric coercion: handles int, double, num, numeric strings, or null.
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

List<String> _toStringList(dynamic v) {
  if (v is List) return v.map((dynamic e) => e.toString()).toList();
  return const <String>[];
}

// ---------------------------------------------------------------------------
// App config
// ---------------------------------------------------------------------------

class AppConfigDoc {
  const AppConfigDoc({
    required this.id,
    required this.minSupportedVersion,
    required this.maintenanceMode,
    required this.independentFanDisclaimer,
    required this.featureFlags,
  });

  final String id;
  final String minSupportedVersion;
  final bool maintenanceMode;
  final String independentFanDisclaimer;
  final Map<String, bool> featureFlags;

  factory AppConfigDoc.fromJson(Map<String, dynamic> j) => AppConfigDoc(
    id: j['id']?.toString() ?? 'main',
    minSupportedVersion: j['minSupportedVersion']?.toString() ?? '1.0.0',
    maintenanceMode: j['maintenanceMode'] == true,
    independentFanDisclaimer: j['independentFanDisclaimer']?.toString() ?? '',
    featureFlags: <String, bool>{
      for (final MapEntry<String, dynamic> e
          in (j['featureFlags'] as Map<String, dynamic>? ??
                  <String, dynamic>{})
              .entries)
        e.key: e.value == true,
    },
  );
}

// ---------------------------------------------------------------------------
// Team
// ---------------------------------------------------------------------------

class Team {
  const Team({
    required this.id,
    required this.school,
    required this.teamName,
    required this.nickname,
    required this.sport,
    required this.division,
    required this.conference,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isOfficialLicensed,
    required this.active,
  });

  final String id;
  final String school;
  final String teamName;
  final String nickname;
  final String sport;
  final String division;
  final String conference;
  final String primaryColor;
  final String secondaryColor;
  final bool isOfficialLicensed;
  final bool active;

  factory Team.fromJson(Map<String, dynamic> j) => Team(
    id: j['id']?.toString() ?? '',
    school: j['school']?.toString() ?? 'Kentucky',
    teamName: j['teamName']?.toString() ?? 'Kentucky',
    nickname: j['nickname']?.toString() ?? 'Wildcats',
    sport: j['sport']?.toString() ?? 'football',
    division: j['division']?.toString() ?? 'NCAA',
    conference: j['conference']?.toString() ?? 'SEC',
    primaryColor: j['primaryColor']?.toString() ?? '#1E5AA8',
    secondaryColor: j['secondaryColor']?.toString() ?? '#C8B273',
    isOfficialLicensed: j['isOfficialLicensed'] == true,
    active: j['active'] != false,
  );
}

// ---------------------------------------------------------------------------
// Game
// ---------------------------------------------------------------------------

enum GameStatus { scheduled, live, halftime, finalScore, unknown }

GameStatus _gameStatus(String? s) {
  switch (s) {
    case 'scheduled':
      return GameStatus.scheduled;
    case 'live':
      return GameStatus.live;
    case 'halftime':
      return GameStatus.halftime;
    case 'final':
      return GameStatus.finalScore;
    default:
      return GameStatus.unknown;
  }
}

class Game {
  const Game({
    required this.id,
    required this.season,
    required this.sport,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.opponentName,
    required this.opponentShort,
    required this.startTime,
    required this.venue,
    required this.city,
    required this.state,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    required this.broadcast,
    required this.source,
    required this.featured,
    required this.isHome,
    required this.rivalry,
    required this.result,
  });

  final String id;
  final int season;
  final String sport;
  final String homeTeamId;
  final String awayTeamId;
  final String opponentName;
  final String opponentShort;
  final DateTime? startTime;
  final String venue;
  final String city;
  final String state;
  final GameStatus status;
  final int? homeScore;
  final int? awayScore;
  final String broadcast;
  final String source;
  final bool featured;
  final bool isHome;
  final String? rivalry;
  final String? result;

  bool get isFinal => status == GameStatus.finalScore;
  bool get isUpcoming => status == GameStatus.scheduled;
  bool get kentuckyWon => result == 'win';

  /// Kentucky's score regardless of home/away (seed is always isHome=true).
  int? get kentuckyScore => isHome ? homeScore : awayScore;
  int? get opponentScore => isHome ? awayScore : homeScore;

  factory Game.fromJson(Map<String, dynamic> j) => Game(
    id: j['id']?.toString() ?? '',
    season: _toInt(j['season']) ?? 0,
    sport: j['sport']?.toString() ?? 'football',
    homeTeamId: j['homeTeamId']?.toString() ?? '',
    awayTeamId: j['awayTeamId']?.toString() ?? '',
    opponentName: j['opponentName']?.toString() ?? 'Opponent',
    opponentShort: j['opponentShort']?.toString() ?? 'OPP',
    startTime: _toDate(j['startTime']),
    venue: j['venue']?.toString() ?? '',
    city: j['city']?.toString() ?? '',
    state: j['state']?.toString() ?? '',
    status: _gameStatus(j['status']?.toString()),
    homeScore: _toInt(j['homeScore']),
    awayScore: _toInt(j['awayScore']),
    broadcast: j['broadcast']?.toString() ?? 'TBD',
    source: j['source']?.toString() ?? 'seed_demo',
    featured: j['featured'] == true,
    isHome: j['isHome'] != false,
    rivalry: j['rivalry']?.toString(),
    result: j['result']?.toString(),
  );
}

// ---------------------------------------------------------------------------
// Game summary (Gameday HQ read model)
// ---------------------------------------------------------------------------

class TeamComparison {
  const TeamComparison({required this.kentucky, required this.opponent});
  final Map<String, double> kentucky;
  final Map<String, double> opponent;

  static Map<String, double> _coerce(dynamic v) {
    if (v is Map) {
      final Map<String, double> out = <String, double>{};
      v.forEach((dynamic k, dynamic val) {
        final double? d = _toDouble(val);
        if (d != null) out[k.toString()] = d;
      });
      return out;
    }
    return const <String, double>{};
  }

  factory TeamComparison.fromJson(Map<String, dynamic> j) => TeamComparison(
    kentucky: _coerce(j['kentucky']),
    opponent: _coerce(j['opponent']),
  );
}

class PlayerToWatch {
  const PlayerToWatch({required this.playerId, required this.reason});
  final String playerId;
  final String reason;

  factory PlayerToWatch.fromJson(Map<String, dynamic> j) => PlayerToWatch(
    playerId: j['playerId']?.toString() ?? '',
    reason: j['reason']?.toString() ?? '',
  );
}

class GameSummary {
  const GameSummary({
    required this.id,
    required this.gameId,
    required this.headline,
    required this.matchupVerdict,
    required this.matchupScore,
    required this.fanConfidence,
    required this.kentuckyWinProb,
    required this.opponentWinProb,
    required this.teamComparison,
    required this.keysToGame,
    required this.playerToWatch,
    required this.concernLevel,
    required this.concernNote,
    required this.statStory,
    required this.source,
    required this.updatedAt,
    required this.confidence,
  });

  final String id;
  final String gameId;
  final String headline;
  final String matchupVerdict; // kentucky_edge | toss_up | opponent_edge
  final int matchupScore; // 0..100
  final int fanConfidence; // 0..100
  final double kentuckyWinProb;
  final double opponentWinProb;
  final TeamComparison teamComparison;
  final List<String> keysToGame;
  final PlayerToWatch? playerToWatch;
  final String concernLevel;
  final String concernNote;
  final String statStory;
  final String source;
  final DateTime? updatedAt;
  final String confidence;

  factory GameSummary.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> wp =
        (j['winProbability'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic> cm =
        (j['concernMeter'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return GameSummary(
      id: j['id']?.toString() ?? '',
      gameId: j['gameId']?.toString() ?? '',
      headline: j['headline']?.toString() ?? '',
      matchupVerdict: j['matchupVerdict']?.toString() ?? 'toss_up',
      matchupScore: _toInt(j['matchupScore']) ?? 50,
      fanConfidence: _toInt(j['fanConfidence']) ?? 50,
      kentuckyWinProb: _toDouble(wp['kentucky']) ?? 0.5,
      opponentWinProb: _toDouble(wp['opponent']) ?? 0.5,
      teamComparison: TeamComparison.fromJson(
        (j['teamComparison'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      keysToGame: _toStringList(j['keysToGame']),
      playerToWatch: j['playerToWatch'] is Map
          ? PlayerToWatch.fromJson(j['playerToWatch'] as Map<String, dynamic>)
          : null,
      concernLevel: cm['level']?.toString() ?? 'low',
      concernNote: cm['note']?.toString() ?? '',
      statStory: j['statStory']?.toString() ?? '',
      source: j['source']?.toString() ?? 'seed_demo',
      updatedAt: _toDate(j['updatedAt']),
      confidence: j['confidence']?.toString() ?? 'demo',
    );
  }
}

// ---------------------------------------------------------------------------
// Team stats
// ---------------------------------------------------------------------------

class TeamStat {
  const TeamStat({
    required this.id,
    required this.teamId,
    required this.season,
    required this.sport,
    required this.scope,
    required this.stats,
    required this.rankings,
    required this.source,
    required this.updatedAt,
    required this.confidence,
  });

  final String id;
  final String teamId;
  final int season;
  final String sport;
  final String scope;
  final Map<String, dynamic> stats;
  final Map<String, int> rankings;
  final String source;
  final DateTime? updatedAt;
  final String confidence;

  /// Convenience: the team record string, e.g. "9-4".
  String get record => stats['record']?.toString() ?? '—';

  double? statValue(String key) => _toDouble(stats[key]);

  factory TeamStat.fromJson(Map<String, dynamic> j) => TeamStat(
    id: j['id']?.toString() ?? '',
    teamId: j['teamId']?.toString() ?? '',
    season: _toInt(j['season']) ?? 0,
    sport: j['sport']?.toString() ?? 'football',
    scope: j['scope']?.toString() ?? 'season',
    stats: (j['stats'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    rankings: <String, int>{
      for (final MapEntry<String, dynamic> e
          in ((j['rankings'] as Map<String, dynamic>?) ?? <String, dynamic>{})
              .entries)
        if (_toInt(e.value) != null) e.key: _toInt(e.value)!,
    },
    source: j['source']?.toString() ?? 'seed_demo',
    updatedAt: _toDate(j['updatedAt']),
    confidence: j['confidence']?.toString() ?? 'demo',
  );
}

// ---------------------------------------------------------------------------
// Players
// ---------------------------------------------------------------------------

class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.name,
    required this.teamId,
    required this.sport,
    required this.position,
    required this.classYear,
    required this.height,
    required this.weight,
    required this.hometown,
    required this.jersey,
    required this.active,
  });

  final String id;
  final String name;
  final String teamId;
  final String sport;
  final String position;
  final String classYear;
  final String height;
  final String weight;
  final String hometown;
  final int? jersey;
  final bool active;

  factory PlayerProfile.fromJson(Map<String, dynamic> j) => PlayerProfile(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? 'Player',
    teamId: j['teamId']?.toString() ?? '',
    sport: j['sport']?.toString() ?? 'football',
    position: j['position']?.toString() ?? '',
    classYear: j['classYear']?.toString() ?? '',
    height: j['height']?.toString() ?? '',
    weight: j['weight']?.toString() ?? '',
    hometown: j['hometown']?.toString() ?? '',
    jersey: _toInt(j['jersey']),
    active: j['active'] != false,
  );
}

class PlayerStat {
  const PlayerStat({
    required this.id,
    required this.playerId,
    required this.teamId,
    required this.season,
    required this.sport,
    required this.scope,
    required this.stats,
    required this.source,
    required this.updatedAt,
    required this.confidence,
  });

  final String id;
  final String playerId;
  final String teamId;
  final int season;
  final String sport;
  final String scope;
  final Map<String, dynamic> stats;
  final String source;
  final DateTime? updatedAt;
  final String confidence;

  double? statValue(String key) => _toDouble(stats[key]);

  factory PlayerStat.fromJson(Map<String, dynamic> j) => PlayerStat(
    id: j['id']?.toString() ?? '',
    playerId: j['playerId']?.toString() ?? '',
    teamId: j['teamId']?.toString() ?? '',
    season: _toInt(j['season']) ?? 0,
    sport: j['sport']?.toString() ?? 'football',
    scope: j['scope']?.toString() ?? 'season',
    stats: (j['stats'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    source: j['source']?.toString() ?? 'seed_demo',
    updatedAt: _toDate(j['updatedAt']),
    confidence: j['confidence']?.toString() ?? 'demo',
  );
}

// ---------------------------------------------------------------------------
// Predictions
// ---------------------------------------------------------------------------

class PredictionOption {
  const PredictionOption({required this.id, required this.label});
  final String id;
  final String label;

  factory PredictionOption.fromJson(Map<String, dynamic> j) =>
      PredictionOption(
        id: j['id']?.toString() ?? '',
        label: j['label']?.toString() ?? '',
      );
}

enum PredictionStatus { open, closed, scored, unknown }

PredictionStatus _predStatus(String? s) {
  switch (s) {
    case 'open':
      return PredictionStatus.open;
    case 'closed':
      return PredictionStatus.closed;
    case 'scored':
      return PredictionStatus.scored;
    default:
      return PredictionStatus.unknown;
  }
}

class Prediction {
  const Prediction({
    required this.id,
    required this.gameId,
    required this.sport,
    required this.type,
    required this.question,
    required this.options,
    required this.opensAt,
    required this.closesAt,
    required this.status,
    required this.points,
    required this.correctOptionId,
    required this.createdBy,
  });

  final String id;
  final String gameId;
  final String sport;
  final String type;
  final String question;
  final List<PredictionOption> options;
  final DateTime? opensAt;
  final DateTime? closesAt;
  final PredictionStatus status;
  final int points;
  final String? correctOptionId;
  final String createdBy;

  bool get isOpen => status == PredictionStatus.open;
  bool get isScored => status == PredictionStatus.scored;

  PredictionOption? optionById(String? id) {
    if (id == null) return null;
    for (final PredictionOption o in options) {
      if (o.id == id) return o;
    }
    return null;
  }

  factory Prediction.fromJson(Map<String, dynamic> j) => Prediction(
    id: j['id']?.toString() ?? '',
    gameId: j['gameId']?.toString() ?? '',
    sport: j['sport']?.toString() ?? 'football',
    type: j['type']?.toString() ?? 'winner',
    question: j['question']?.toString() ?? '',
    options: ((j['options'] as List<dynamic>?) ?? <dynamic>[])
        .map((dynamic e) =>
            PredictionOption.fromJson(e as Map<String, dynamic>))
        .toList(),
    opensAt: _toDate(j['opensAt']),
    closesAt: _toDate(j['closesAt']),
    status: _predStatus(j['status']?.toString()),
    points: _toInt(j['points']) ?? 10,
    correctOptionId: j['correctOptionId']?.toString(),
    createdBy: j['createdBy']?.toString() ?? '',
  );
}

class PredictionEntry {
  const PredictionEntry({
    required this.id,
    required this.predictionId,
    required this.gameId,
    required this.userId,
    required this.selectedOptionId,
    required this.locked,
    required this.isCorrect,
    required this.pointsAwarded,
    required this.createdAt,
  });

  final String id;
  final String predictionId;
  final String gameId;
  final String userId;
  final String selectedOptionId;
  final bool locked;
  final bool? isCorrect;
  final int pointsAwarded;
  final DateTime? createdAt;

  factory PredictionEntry.fromJson(Map<String, dynamic> j) => PredictionEntry(
    id: j['id']?.toString() ?? '',
    predictionId: j['predictionId']?.toString() ?? '',
    gameId: j['gameId']?.toString() ?? '',
    userId: j['userId']?.toString() ?? '',
    selectedOptionId: j['selectedOptionId']?.toString() ?? '',
    locked: j['locked'] == true,
    isCorrect: j['isCorrect'] is bool ? j['isCorrect'] as bool : null,
    pointsAwarded: _toInt(j['pointsAwarded']) ?? 0,
    createdAt: _toDate(j['createdAt']),
  );
}

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------

class PredictionRecord {
  const PredictionRecord({
    required this.total,
    required this.correct,
    required this.streak,
  });

  final int total;
  final int correct;
  final int streak;

  double get accuracy => total == 0 ? 0 : correct / total;

  factory PredictionRecord.fromJson(Map<String, dynamic> j) =>
      PredictionRecord(
        total: _toInt(j['total']) ?? 0,
        correct: _toInt(j['correct']) ?? 0,
        streak: _toInt(j['streak']) ?? 0,
      );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.favoriteCollegeTeams,
    required this.favoriteSports,
    required this.favoriteHighSchools,
    required this.homeState,
    required this.xp,
    required this.level,
    required this.predictionRecord,
  });

  final String id;
  final String displayName;
  final String email;
  final String role;
  final List<String> favoriteCollegeTeams;
  final List<String> favoriteSports;
  final List<String> favoriteHighSchools;
  final String homeState;
  final int xp;
  final int level;
  final PredictionRecord predictionRecord;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id']?.toString() ?? '',
    displayName: j['displayName']?.toString() ?? 'Fan',
    email: j['email']?.toString() ?? '',
    role: j['role']?.toString() ?? 'user',
    favoriteCollegeTeams: _toStringList(j['favoriteCollegeTeams']),
    favoriteSports: _toStringList(j['favoriteSports']),
    favoriteHighSchools: _toStringList(j['favoriteHighSchools']),
    homeState: j['homeState']?.toString() ?? '',
    xp: _toInt(j['xp']) ?? 0,
    level: _toInt(j['level']) ?? 1,
    predictionRecord: PredictionRecord.fromJson(
      (j['predictionRecord'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    ),
  );
}

// ---------------------------------------------------------------------------
// Badges
// ---------------------------------------------------------------------------

class Badge {
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.criteriaType,
    required this.criteriaThreshold,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String rarity;
  final String criteriaType;
  final int criteriaThreshold;

  factory Badge.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> c =
        (j['criteria'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return Badge(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? 'Badge',
      description: j['description']?.toString() ?? '',
      category: j['category']?.toString() ?? 'prediction',
      rarity: j['rarity']?.toString() ?? 'common',
      criteriaType: c['type']?.toString() ?? '',
      criteriaThreshold: _toInt(c['threshold']) ?? 1,
    );
  }
}

class UserBadge {
  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
  });

  final String id;
  final String userId;
  final String badgeId;
  final DateTime? earnedAt;

  factory UserBadge.fromJson(Map<String, dynamic> j) => UserBadge(
    id: j['id']?.toString() ?? '',
    userId: j['userId']?.toString() ?? '',
    badgeId: j['badgeId']?.toString() ?? '',
    earnedAt: _toDate(j['earnedAt']),
  );
}

// ---------------------------------------------------------------------------
// Polls
// ---------------------------------------------------------------------------

class PollOption {
  const PollOption({required this.id, required this.label, required this.votes});
  final String id;
  final String label;
  final int votes;

  factory PollOption.fromJson(Map<String, dynamic> j) => PollOption(
    id: j['id']?.toString() ?? '',
    label: j['label']?.toString() ?? '',
    votes: _toInt(j['votes']) ?? 0,
  );
}

class Poll {
  const Poll({
    required this.id,
    required this.question,
    required this.sport,
    required this.status,
    required this.options,
    required this.closesAt,
  });

  final String id;
  final String question;
  final String sport;
  final String status;
  final List<PollOption> options;
  final DateTime? closesAt;

  int get totalVotes =>
      options.fold(0, (int sum, PollOption o) => sum + o.votes);

  factory Poll.fromJson(Map<String, dynamic> j) => Poll(
    id: j['id']?.toString() ?? '',
    question: j['question']?.toString() ?? '',
    sport: j['sport']?.toString() ?? '',
    status: j['status']?.toString() ?? 'open',
    options: ((j['options'] as List<dynamic>?) ?? <dynamic>[])
        .map((dynamic e) => PollOption.fromJson(e as Map<String, dynamic>))
        .toList(),
    closesAt: _toDate(j['closesAt']),
  );
}

// ---------------------------------------------------------------------------
// News cards
// ---------------------------------------------------------------------------

class NewsCard {
  const NewsCard({
    required this.id,
    required this.title,
    required this.sourceName,
    required this.url,
    required this.summary,
    required this.sport,
    required this.tags,
    required this.publishedAt,
    required this.featured,
  });

  final String id;
  final String title;
  final String sourceName;
  final String url;
  final String summary;
  final String sport;
  final List<String> tags;
  final DateTime? publishedAt;
  final bool featured;

  factory NewsCard.fromJson(Map<String, dynamic> j) => NewsCard(
    id: j['id']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    sourceName: j['sourceName']?.toString() ?? '',
    url: j['url']?.toString() ?? '',
    summary: j['summary']?.toString() ?? '',
    sport: j['sport']?.toString() ?? '',
    tags: _toStringList(j['tags']),
    publishedAt: _toDate(j['publishedAt']),
    featured: j['featured'] == true,
  );
}

// ---------------------------------------------------------------------------
// High schools + games
// ---------------------------------------------------------------------------

class HighSchool {
  const HighSchool({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.sports,
    required this.khsaaUrl,
    required this.verified,
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final List<String> sports;
  final String? khsaaUrl;
  final bool verified;

  factory HighSchool.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> urls =
        (j['sourceUrls'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return HighSchool(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      city: j['city']?.toString() ?? '',
      state: j['state']?.toString() ?? '',
      sports: _toStringList(j['sports']),
      khsaaUrl: urls['khsaa']?.toString(),
      verified: j['verified'] == true,
    );
  }
}

class HighSchoolGame {
  const HighSchoolGame({
    required this.id,
    required this.schoolId,
    required this.sport,
    required this.season,
    required this.opponent,
    required this.startTime,
    required this.status,
    required this.schoolScore,
    required this.opponentScore,
    required this.sourceUrl,
  });

  final String id;
  final String schoolId;
  final String sport;
  final int season;
  final String opponent;
  final DateTime? startTime;
  final String status;
  final int? schoolScore;
  final int? opponentScore;
  final String? sourceUrl;

  factory HighSchoolGame.fromJson(Map<String, dynamic> j) => HighSchoolGame(
    id: j['id']?.toString() ?? '',
    schoolId: j['schoolId']?.toString() ?? '',
    sport: j['sport']?.toString() ?? 'football',
    season: _toInt(j['season']) ?? 0,
    opponent: j['opponent']?.toString() ?? '',
    startTime: _toDate(j['startTime']),
    status: j['status']?.toString() ?? 'scheduled',
    schoolScore: _toInt(j['schoolScore']),
    opponentScore: _toInt(j['opponentScore']),
    sourceUrl: j['sourceUrl']?.toString(),
  );
}

// ---------------------------------------------------------------------------
// Articles (AI-generated journalistic content)
// ---------------------------------------------------------------------------

/// A single narrative section with a title and body copy (e.g. tactical
/// breakdown, key moment, etc.).
class ArticleNarrativeSection {
  const ArticleNarrativeSection({required this.title, required this.narrative});

  final String title;
  final String narrative;

  factory ArticleNarrativeSection.fromJson(Map<String, dynamic> j) =>
      ArticleNarrativeSection(
        title: j['title']?.toString() ?? '',
        narrative: j['narrative']?.toString() ?? '',
      );
}

/// A bullet-list section with a title and items (e.g. "By the Numbers").
class ArticleListSection {
  const ArticleListSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  factory ArticleListSection.fromJson(Map<String, dynamic> j) =>
      ArticleListSection(
        title: j['title']?.toString() ?? '',
        items: _toStringList(j['items']),
      );
}

/// A player spotlight inside an article.
class ArticlePlayerSpotlight {
  const ArticlePlayerSpotlight({
    required this.playerId,
    required this.name,
    required this.position,
    required this.narrative,
    required this.statline,
  });

  final String? playerId;
  final String name;
  final String? position;
  final String narrative;
  final String? statline;

  factory ArticlePlayerSpotlight.fromJson(Map<String, dynamic> j) =>
      ArticlePlayerSpotlight(
        playerId: j['playerId']?.toString(),
        name: j['name']?.toString() ?? 'Player',
        position: j['position']?.toString(),
        narrative: j['narrative']?.toString() ?? '',
        statline: j['statline']?.toString(),
      );
}

/// The closing verdict of an article (preview has prediction; recap has result).
class ArticleVerdict {
  const ArticleVerdict({
    required this.title,
    required this.prediction,
    required this.result,
    required this.confidence,
    required this.narrative,
  });

  final String title;

  /// Set on preview articles.
  final String? prediction;

  /// Set on recap articles.
  final String? result;

  /// 0-100 confidence value (optional — preview typically has it, recap may not).
  final int? confidence;

  final String narrative;

  factory ArticleVerdict.fromJson(Map<String, dynamic> j) => ArticleVerdict(
    title: j['title']?.toString() ?? 'The Verdict',
    prediction: j['prediction']?.toString(),
    result: j['result']?.toString(),
    confidence: _toInt(j['confidence']),
    narrative: j['narrative']?.toString() ?? '',
  );
}

/// An AI-generated journalistic article (preview, recap, or stat story).
///
/// Mirrors the `articles` collection shape in docs/14_DATA_PERSISTENCE_AND_ARTICLES.md.
/// All fields beyond the required set are nullable so preview and recap docs
/// both parse cleanly (recap omits `tacticalBreakdown` and `theVerdict.prediction`).
class Article {
  const Article({
    required this.id,
    required this.type,
    required this.gameId,
    required this.sport,
    required this.status,
    required this.headline,
    required this.subheadline,
    required this.openingNarrative,
    required this.tacticalBreakdown,
    required this.byTheNumbers,
    required this.playerSpotlights,
    required this.theVerdict,
    required this.closingLine,
    required this.sources,
    required this.model,
    required this.generatedAt,
    required this.publishedAt,
    required this.confidence,
    required this.featured,
  });

  /// "preview" | "recap" | "stat_story"
  final String type;
  final String id;
  final String gameId;
  final String sport;

  /// "draft" | "published" | "hidden"
  final String status;

  final String headline;
  final String subheadline;
  final String openingNarrative;

  /// Optional — present on preview, absent on recap.
  final ArticleNarrativeSection? tacticalBreakdown;

  final ArticleListSection? byTheNumbers;
  final List<ArticlePlayerSpotlight> playerSpotlights;
  final ArticleVerdict? theVerdict;
  final String closingLine;
  final List<String> sources;

  /// "claude-opus-4-8", "seed_template", etc.
  final String model;

  final DateTime? generatedAt;
  final DateTime? publishedAt;
  final String confidence;
  final bool featured;

  bool get isPublished => status == 'published';
  bool get isPreview => type == 'preview';
  bool get isRecap => type == 'recap';

  factory Article.fromJson(Map<String, dynamic> j) {
    final dynamic tb = j['tacticalBreakdown'];
    final dynamic btn = j['byTheNumbers'];
    final dynamic tv = j['theVerdict'];

    return Article(
      id: j['id']?.toString() ?? '',
      type: j['type']?.toString() ?? 'preview',
      gameId: j['gameId']?.toString() ?? '',
      sport: j['sport']?.toString() ?? 'football',
      status: j['status']?.toString() ?? 'published',
      headline: j['headline']?.toString() ?? '',
      subheadline: j['subheadline']?.toString() ?? '',
      openingNarrative: j['openingNarrative']?.toString() ?? '',
      tacticalBreakdown: tb is Map<String, dynamic>
          ? ArticleNarrativeSection.fromJson(tb)
          : null,
      byTheNumbers: btn is Map<String, dynamic>
          ? ArticleListSection.fromJson(btn)
          : null,
      playerSpotlights: ((j['playerSpotlights'] as List<dynamic>?) ??
              <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(ArticlePlayerSpotlight.fromJson)
          .toList(),
      theVerdict: tv is Map<String, dynamic>
          ? ArticleVerdict.fromJson(tv)
          : null,
      closingLine: j['closingLine']?.toString() ?? '',
      sources: _toStringList(j['sources']),
      model: j['model']?.toString() ?? 'seed_template',
      generatedAt: _toDate(j['generatedAt']),
      publishedAt: _toDate(j['publishedAt']),
      confidence: j['confidence']?.toString() ?? 'demo',
      featured: j['featured'] == true,
    );
  }
}

// ---------------------------------------------------------------------------
// Recruits
// ---------------------------------------------------------------------------

class Recruit {
  const Recruit({
    required this.id,
    required this.name,
    required this.sport,
    required this.position,
    required this.classYear,
    required this.highSchoolId,
    required this.homeTown,
    required this.state,
    required this.stars,
    required this.rating,
    required this.interestLevel,
    required this.commitStatus,
    required this.committedTo,
    required this.confidence,
    required this.sourceLinks,
  });

  final String id;
  final String name;
  final String sport;
  final String position;
  final int classYear;
  final String? highSchoolId;
  final String homeTown;
  final String state;
  final int stars;
  final double rating;
  final String interestLevel;
  final String commitStatus;
  final String? committedTo;
  final String confidence;
  final List<String> sourceLinks;

  factory Recruit.fromJson(Map<String, dynamic> j) => Recruit(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    sport: j['sport']?.toString() ?? 'football',
    position: j['position']?.toString() ?? '',
    classYear: _toInt(j['classYear']) ?? 0,
    highSchoolId: j['highSchoolId']?.toString(),
    homeTown: j['homeTown']?.toString() ?? '',
    state: j['state']?.toString() ?? '',
    stars: _toInt(j['stars']) ?? 0,
    rating: _toDouble(j['rating']) ?? 0,
    interestLevel: j['interestLevel']?.toString() ?? '',
    commitStatus: j['commitStatus']?.toString() ?? 'uncommitted',
    committedTo: j['committedTo']?.toString(),
    confidence: j['confidence']?.toString() ?? 'reported_by_media',
    sourceLinks: _toStringList(j['sourceLinks']),
  );
}
