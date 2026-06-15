import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stats_engine/stats_engine.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/data_providers.dart';
import '../../core/widgets/widgets.dart';

/// Stats Lab — the analytics hub. Football and basketball sub-tabs each show a
/// Kentucky-vs-opponent compare, Four Factors / advanced cards, and explainers.
class StatsLabScreen extends ConsumerWidget {
  const StatsLabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stats Lab'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Basketball', icon: Icon(Icons.sports_basketball_rounded)),
              Tab(text: 'Football', icon: Icon(Icons.sports_football_rounded)),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _BasketballLab(),
            _FootballLab(),
          ],
        ),
      ),
    );
  }
}

// --- Basketball -------------------------------------------------------------

class _BasketballLab extends ConsumerWidget {
  const _BasketballLab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TeamStat>> stats = ref.watch(teamStatsProvider);
    final AsyncValue<List<GameSummary>> summaries =
        ref.watch(gameSummariesProvider);

    return stats.when(
      loading: () => const LoadingView(label: 'Crunching numbers'),
      error: (Object e, _) => ErrorView(message: '$e'),
      data: (List<TeamStat> list) {
        final TeamStat? bball = _firstSport(list, 'mens_basketball');
        if (bball == null) {
          return const EmptyView(title: 'No basketball stats yet');
        }
        final GameSummary? summary = summaries.maybeWhen(
          data: (List<GameSummary> s) => s
              .where((GameSummary g) => g.gameId.contains('mbb'))
              .cast<GameSummary?>()
              .firstWhere((GameSummary? g) => true, orElse: () => null),
          orElse: () => null,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: <Widget>[
            if (summary != null) ...<Widget>[
              const SectionHeader(
                title: 'Kentucky vs Opponent',
                eyebrow: 'Head-to-head compare',
                padding: EdgeInsets.only(bottom: 10),
              ),
              _CompareCard(summary: summary, sport: 'mens_basketball'),
              const SizedBox(height: 8),
            ],
            const SectionHeader(
              title: 'The Four Factors',
              eyebrow: 'What wins basketball games',
              padding: EdgeInsets.only(bottom: 10),
            ),
            _FourFactorsCards(stat: bball),
            const SizedBox(height: 8),
            const SectionHeader(
              title: 'Advanced Profile',
              eyebrow: 'Efficiency & tempo',
              padding: EdgeInsets.only(bottom: 10),
            ),
            _AdvancedBasketball(stat: bball),
          ],
        );
      },
    );
  }
}

class _FourFactorsCards extends StatelessWidget {
  const _FourFactorsCards({required this.stat});

  final TeamStat stat;

  /// Demo percentiles for the Four Factors (seed has no per-factor percentile).
  static const Map<String, int> _demoPercentiles = <String, int>{
    'effectiveFgPct': 82,
    'turnoverRate': 70,
    'offReboundRate': 88,
    'freeThrowRate': 61,
  };

  @override
  Widget build(BuildContext context) {
    final List<FourFactorValue> factors =
        extractFourFactors(stat.stats, percentiles: _demoPercentiles);
    return Column(
      children: <Widget>[
        for (final FourFactorValue f in factors)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FourFactorCard(value: f, stat: stat),
          ),
      ],
    );
  }
}

class _FourFactorCard extends StatelessWidget {
  const _FourFactorCard({required this.value, required this.stat});

  final FourFactorValue value;
  final TeamStat stat;

  @override
  Widget build(BuildContext context) {
    final FourFactor f = value.factor;
    final TextTheme text = Theme.of(context).textTheme;
    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BgColors.blueTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(f.weight * 100).round()}%',
                  style: BgTypography.statNumber(BgColors.deepBlue, size: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      f.fanLabel.toUpperCase(),
                      style: BgTypography.eyebrow(BgColors.deepBlue),
                    ),
                    Text(f.title, style: text.titleMedium),
                  ],
                ),
              ),
              Text(
                value.display,
                style: BgTypography.statNumber(BgColors.deepBlue, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PercentileBar(percentile: value.percentile),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BgColors.canvas,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 15, color: BgColors.bluegrassGold),
                const SizedBox(width: 6),
                Expanded(child: Text(f.explanation, style: text.bodySmall)),
              ],
            ),
          ),
          const Divider(height: 20),
          SourceConfidenceRow(
            source: stat.source,
            updatedAt: stat.updatedAt,
            confidence: stat.confidence,
          ),
        ],
      ),
    );
  }
}

class _AdvancedBasketball extends StatelessWidget {
  const _AdvancedBasketball({required this.stat});

  final TeamStat stat;

  static const List<({String key, int pct})> _metrics =
      <({String key, int pct})>[
    (key: 'adjNetRating', pct: 92),
    (key: 'adjOffRating', pct: 84),
    (key: 'adjDefRating', pct: 79),
    (key: 'tempo', pct: 58),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final ({String key, int pct}) m in _metrics)
          if (stat.statValue(m.key) != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StatCard.fromMetric(
                metricKey: m.key,
                value: stat.statValue(m.key)!,
                sport: 'mens_basketball',
                source: stat.source,
                updatedAt: stat.updatedAt,
                confidence: stat.confidence,
                percentile: m.pct,
                rankText: _rank(m.key),
              ),
            ),
      ],
    );
  }

  String? _rank(String key) {
    final int? rank = key == 'adjNetRating'
        ? stat.rankings['adjNetRatingNational']
        : key == 'tempo'
            ? stat.rankings['tempoNational']
            : null;
    if (rank == null) return null;
    return '#$rank nationally';
  }
}

// --- Football ---------------------------------------------------------------

class _FootballLab extends ConsumerWidget {
  const _FootballLab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TeamStat>> stats = ref.watch(teamStatsProvider);
    final AsyncValue<List<GameSummary>> summaries =
        ref.watch(gameSummariesProvider);

    return stats.when(
      loading: () => const LoadingView(label: 'Crunching numbers'),
      error: (Object e, _) => ErrorView(message: '$e'),
      data: (List<TeamStat> list) {
        final TeamStat? fb = _firstSport(list, 'football');
        if (fb == null) {
          return const EmptyView(title: 'No football stats yet');
        }
        final GameSummary? summary = summaries.maybeWhen(
          data: (List<GameSummary> s) => s
              .where((GameSummary g) => g.gameId.contains('fb'))
              .cast<GameSummary?>()
              .firstWhere((GameSummary? g) => true, orElse: () => null),
          orElse: () => null,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: <Widget>[
            if (summary != null) ...<Widget>[
              const SectionHeader(
                title: 'Kentucky vs Opponent',
                eyebrow: 'Head-to-head compare',
                padding: EdgeInsets.only(bottom: 10),
              ),
              _CompareCard(summary: summary, sport: 'football'),
              const SizedBox(height: 8),
            ],
            const SectionHeader(
              title: 'Advanced Metrics',
              eyebrow: 'Beyond the box score',
              padding: EdgeInsets.only(bottom: 10),
            ),
            _AdvancedFootball(stat: fb),
          ],
        );
      },
    );
  }
}

class _AdvancedFootball extends StatelessWidget {
  const _AdvancedFootball({required this.stat});

  final TeamStat stat;

  /// Demo percentiles keyed by metric (seed has SEC ranks, not percentiles).
  static const Map<String, int> _demoPct = <String, int>{
    'successRate': 68,
    'explosivePlayRate': 74,
    'ppaOffense': 71,
    'ppaDefense': 66,
    'turnoverMargin': 80,
    'redZoneScorePct': 90,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final FootballMetric m in advancedFootballMetrics)
          if (stat.statValue(m.key) != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StatCard.fromMetric(
                metricKey: m.key,
                value: stat.statValue(m.key)!,
                sport: 'football',
                source: stat.source,
                updatedAt: stat.updatedAt,
                confidence: stat.confidence,
                percentile: _demoPct[m.key],
                rankText: _rank(m.key),
              ),
            ),
      ],
    );
  }

  String? _rank(String key) {
    final Map<String, String> rk = <String, String>{
      'turnoverMargin': 'turnoverMarginSEC',
    };
    final String? k = rk[key];
    if (k == null) return null;
    final int? rank = stat.rankings[k];
    return rank == null ? null : '#$rank in the SEC';
  }
}

// --- Shared compare ---------------------------------------------------------

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.summary, required this.sport});

  final GameSummary summary;
  final String sport;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TeamComparison c = summary.teamComparison;
    final List<String> keys = c.kentucky.keys
        .where((String k) => c.opponent.containsKey(k))
        .toList();

    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(summary.headline, style: text.titleMedium),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Text('Kentucky', style: BgTypography.eyebrow(BgColors.deepBlue)),
              const Spacer(),
              Text('Opponent', style: BgTypography.eyebrow(BgColors.goldDark)),
            ],
          ),
          const Divider(height: 16),
          ...keys.map((String key) {
            final double ky = c.kentucky[key]!;
            final double opp = c.opponent[key]!;
            final MetricLabel meta = labelFor(key, sport: sport);
            final bool kyWins = meta.higherIsBetter ? ky >= opp : ky <= opp;
            return CompareRow(
              label: meta.shortLabel,
              kentuckyText: formatMetricValue(key, ky, sport: sport),
              opponentText: formatMetricValue(key, opp, sport: sport),
              kentuckyWins: kyWins,
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BgColors.canvas,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(summary.statStory, style: text.bodySmall),
          ),
          const Divider(height: 20),
          SourceConfidenceRow(
            source: summary.source,
            updatedAt: summary.updatedAt,
            confidence: summary.confidence,
          ),
        ],
      ),
    );
  }
}

TeamStat? _firstSport(List<TeamStat> list, String sport) {
  for (final TeamStat s in list) {
    if (s.sport == sport) return s;
  }
  return null;
}
