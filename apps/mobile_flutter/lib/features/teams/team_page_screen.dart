import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stats_engine/stats_engine.dart';

import '../../app/router.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../shared/game_widgets.dart';

/// Team Page for Kentucky football & men's basketball. Tabs: Overview,
/// Schedule, Roster, Stats.
class TeamPageScreen extends ConsumerWidget {
  const TeamPageScreen({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Team?> team = ref.watch(teamByIdProvider(teamId));

    return team.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (Object e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: '$e'),
      ),
      data: (Team? t) {
        if (t == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyView(title: 'Team not found'),
          );
        }
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool _) =>
                  <Widget>[_TeamHeader(team: t)],
              body: Column(
                children: <Widget>[
                  const Material(
                    color: BgColors.surface,
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: <Widget>[
                        Tab(text: 'Overview'),
                        Tab(text: 'Schedule'),
                        Tab(text: 'Roster'),
                        Tab(text: 'Stats'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: <Widget>[
                        _OverviewTab(team: t),
                        _ScheduleTab(teamId: teamId),
                        _RosterTab(teamId: teamId),
                        _StatsTab(teamId: teamId, sport: t.sport),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TeamHeader extends StatelessWidget {
  const _TeamHeader({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SliverAppBar(
      expandedHeight: 168,
      pinned: true,
      foregroundColor: Colors.white,
      backgroundColor: BgColors.deepBlue,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('${team.school} ${Fmt.sportLabel(team.sport)}'),
        titlePadding: const EdgeInsets.only(left: 52, bottom: 14, right: 16),
        background: DecoratedBox(
          decoration: const BoxDecoration(gradient: BgColors.heroGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 44),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Pill(
                        label: team.conference,
                        color: Colors.white,
                        background: Colors.white.withValues(alpha: 0.18),
                        dense: true,
                      ),
                      const SizedBox(width: 8),
                      Pill(
                        label: team.nickname,
                        color: BgColors.goldBright,
                        background:
                            BgColors.goldBright.withValues(alpha: 0.16),
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    team.school,
                    style: BgTypography.statNumber(Colors.white, size: 30),
                  ),
                  Text(
                    'Independent fan page · ${Fmt.sportLabel(team.sport)}',
                    style: text.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TeamStat?> stat =
        ref.watch(teamStatForTeamProvider(team.id));
    final AsyncValue<Game?> next = ref.watch(featuredGameProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        stat.when(
          loading: () => const BgCard(child: LoadingView()),
          error: (Object e, _) => const SizedBox.shrink(),
          data: (TeamStat? s) {
            if (s == null) {
              return const EmptyView(title: 'No team stats yet');
            }
            return _RecordCard(stat: s, sport: team.sport);
          },
        ),
        const SizedBox(height: 16),
        next.maybeWhen(
          data: (Game? g) {
            if (g == null || g.sport != team.sport) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionHeader(
                  title: 'Next Up',
                  padding: EdgeInsets.only(bottom: 10),
                ),
                MatchupHero(game: g),
              ],
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.stat, required this.sport});

  final TeamStat stat;
  final String sport;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool fb = sport == 'football';
    final List<({String key, String label})> highlights = fb
        ? <({String key, String label})>[
            (key: 'pointsPerGame', label: 'PPG'),
            (key: 'pointsAllowedPerGame', label: 'Opp PPG'),
            (key: 'yardsPerPlay', label: 'Yds/Play'),
          ]
        : <({String key, String label})>[
            (key: 'pointsPerGame', label: 'PPG'),
            (key: 'effectiveFgPct', label: 'eFG%'),
            (key: 'adjNetRating', label: 'Net Rtg'),
          ];

    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('RECORD', style: BgTypography.eyebrow(BgColors.slate)),
                  Text(
                    stat.record,
                    style: BgTypography.statNumber(BgColors.deepBlue, size: 34),
                  ),
                ],
              ),
              const Spacer(),
              Pill(
                label: '${stat.season} season',
                color: BgColors.deepBlue,
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: <Widget>[
              for (final ({String key, String label}) h in highlights)
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        stat.statValue(h.key) == null
                            ? '—'
                            : formatMetricValue(
                                h.key,
                                stat.statValue(h.key)!,
                                sport: sport,
                              ),
                        style: BgTypography.statNumber(BgColors.ink, size: 20),
                      ),
                      Text(h.label, style: text.labelSmall),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 22),
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

class _ScheduleTab extends ConsumerWidget {
  const _ScheduleTab({required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Game>> games =
        ref.watch(gamesForTeamProvider(teamId));
    return games.when(
      loading: () => const LoadingView(),
      error: (Object e, _) => ErrorView(message: '$e'),
      data: (List<Game> list) {
        if (list.isEmpty) {
          return const EmptyView(
            title: 'No games scheduled',
            icon: Icons.event_busy_rounded,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int i) =>
              _ScheduleRow(game: list[i]),
        );
      },
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isFinal = game.isFinal;
    return BgCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            child: Column(
              children: <Widget>[
                Text(
                  Fmt.shortDay(game.startTime).split(' ').first.toUpperCase(),
                  style: BgTypography.eyebrow(BgColors.slate),
                ),
                Text(
                  game.startTime?.day.toString() ?? '–',
                  style: BgTypography.statNumber(BgColors.deepBlue, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      game.isHome ? 'vs' : '@',
                      style: text.bodySmall,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        game.opponentName,
                        style: text.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (game.rivalry != null) ...<Widget>[
                      const SizedBox(width: 6),
                      const Icon(Icons.local_fire_department_rounded,
                          size: 14, color: BgColors.goldDark),
                    ],
                  ],
                ),
                Text(
                  '${Fmt.time(game.startTime)} · ${game.broadcast}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          if (isFinal)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  game.kentuckyWon ? 'W' : 'L',
                  style: BgTypography.statNumber(
                    game.kentuckyWon ? BgColors.positive : BgColors.negative,
                    size: 18,
                  ),
                ),
                Text(
                  '${game.kentuckyScore}-${game.opponentScore}',
                  style: text.bodySmall,
                ),
              ],
            )
          else
            Pill(label: 'Upcoming', color: BgColors.blueBright, dense: true),
        ],
      ),
    );
  }
}

class _RosterTab extends ConsumerWidget {
  const _RosterTab({required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PlayerProfile>> players =
        ref.watch(playersForTeamProvider(teamId));
    return players.when(
      loading: () => const LoadingView(),
      error: (Object e, _) => ErrorView(message: '$e'),
      data: (List<PlayerProfile> list) {
        if (list.isEmpty) {
          return const EmptyView(
            title: 'Roster coming soon',
            icon: Icons.groups_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (BuildContext context, int i) {
            final PlayerProfile p = list[i];
            return BgCard(
              onTap: () => context.push(Routes.player(p.id)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: BgColors.blueTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        p.jersey != null ? '${p.jersey}' : p.position,
                        style:
                            BgTypography.statNumber(BgColors.deepBlue, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(p.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${p.position} · ${p.classYear} · ${p.height}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    p.hometown,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, color: BgColors.mist),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatsTab extends ConsumerWidget {
  const _StatsTab({required this.teamId, required this.sport});

  final String teamId;
  final String sport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TeamStat?> stat =
        ref.watch(teamStatForTeamProvider(teamId));
    return stat.when(
      loading: () => const LoadingView(),
      error: (Object e, _) => ErrorView(message: '$e'),
      data: (TeamStat? s) {
        if (s == null) {
          return const EmptyView(title: 'No stats available');
        }
        final List<String> keys = _statKeysFor(sport);
        final List<String> present =
            keys.where((String k) => s.statValue(k) != null).toList();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: present.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int i) {
            final String key = present[i];
            return StatCard.fromMetric(
              metricKey: key,
              value: s.statValue(key)!,
              sport: sport,
              source: s.source,
              updatedAt: s.updatedAt,
              confidence: s.confidence,
              rankText: _rankText(s, key),
            );
          },
        );
      },
    );
  }

  String? _rankText(TeamStat s, String key) {
    // Map a few known SEC ranking keys onto their metric.
    final Map<String, String> rankKeys = <String, String>{
      'pointsPerGame': 'pointsPerGameSEC',
      'yardsPerPlay': 'yardsPerPlaySEC',
      'turnoverMargin': 'turnoverMarginSEC',
      'effectiveFgPct': 'effectiveFgPctSEC',
      'adjNetRating': 'adjNetRatingNational',
      'tempo': 'tempoNational',
    };
    final String? rk = rankKeys[key];
    if (rk == null) return null;
    final int? rank = s.rankings[rk];
    if (rank == null) return null;
    final String scope = rk.endsWith('National') ? 'nationally' : 'in the SEC';
    return '#$rank $scope';
  }

  List<String> _statKeysFor(String sport) {
    if (sport.contains('basketball')) {
      return <String>[
        'effectiveFgPct',
        'adjNetRating',
        'adjOffRating',
        'adjDefRating',
        'tempo',
        'offReboundRate',
        'turnoverRate',
        'threePointPct',
        'assistRate',
      ];
    }
    return <String>[
      'pointsPerGame',
      'pointsAllowedPerGame',
      'yardsPerPlay',
      'thirdDownPct',
      'redZoneScorePct',
      'turnoverMargin',
      'explosivePlayRate',
      'successRate',
      'sacksPerGame',
    ];
  }
}
