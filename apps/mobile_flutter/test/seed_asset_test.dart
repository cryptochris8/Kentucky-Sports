// Guards the single input feeding every screen: the bundled seed asset must
// load through the real MockDataSource and parse into non-empty collections.
// A malformed or drifted assets/seed/dev_seed.json fails here, not on device.

import 'package:bluegrass_gameday/core/data/mock_data_source.dart';
import 'package:bluegrass_gameday/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MockDataSource source = MockDataSource(latency: Duration.zero);

  test('bundled seed parses games with real ids and statuses', () async {
    final List<Game> games = await source.games();
    expect(games, isNotEmpty);
    expect(games.every((Game g) => g.id.isNotEmpty), isTrue);
    // The seed's one final game must carry a knowable outcome.
    final List<Game> finals = games.where((Game g) => g.isFinal).toList();
    expect(finals, isNotEmpty);
    expect(finals.every((Game g) => g.kentuckyWon != null), isTrue);
  });

  test('bundled seed parses articles with attribution fields', () async {
    final List<Article> articles = await source.articles();
    expect(articles, isNotEmpty);
    expect(articles.every((Article a) => a.confidence.isNotEmpty), isTrue);
    expect(articles.every((Article a) => a.sources.isNotEmpty), isTrue);
  });

  test('bundled seed parses team stats with source + confidence', () async {
    final List<TeamStat> stats = await source.teamStats();
    expect(stats, isNotEmpty);
    expect(stats.every((TeamStat s) => s.source.isNotEmpty), isTrue);
    expect(stats.every((TeamStat s) => s.confidence.isNotEmpty), isTrue);
  });
}
