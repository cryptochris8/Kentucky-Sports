import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stats_engine/stats_engine.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/widgets.dart';

/// Player profile: bio, season stats, and a related-news teaser. College
/// player content is limited to public bio + season stat lines.
class PlayerProfileScreen extends ConsumerWidget {
  const PlayerProfileScreen({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PlayerProfile?> player =
        ref.watch(playerByIdProvider(playerId));
    final AsyncValue<PlayerStat?> stat =
        ref.watch(playerStatByPlayerProvider(playerId));

    return Scaffold(
      body: player.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorView(message: '$e'),
        ),
        data: (PlayerProfile? p) {
          if (p == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const EmptyView(title: 'Player not found'),
            );
          }
          return CustomScrollView(
            slivers: <Widget>[
              _PlayerHeader(player: p),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    _BioCard(player: p),
                    const SizedBox(height: 16),
                    const SectionHeader(
                      title: 'Season Stats',
                      eyebrow: 'Per game · demo data',
                      padding: EdgeInsets.only(bottom: 10),
                    ),
                    stat.when(
                      loading: () => const BgCard(child: LoadingView()),
                      error: (Object e, _) =>
                          const EmptyView(title: 'No stats available'),
                      data: (PlayerStat? s) {
                        if (s == null) {
                          return const EmptyView(
                            title: 'No stats yet',
                            subtitle:
                                'Season stats will appear once the year starts.',
                          );
                        }
                        return _PlayerStatGrid(stat: s, sport: p.sport);
                      },
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({required this.player});

  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      foregroundColor: Colors.white,
      backgroundColor: BgColors.deepBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: DecoratedBox(
          decoration: const BoxDecoration(gradient: BgColors.heroGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: BgColors.goldBright.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        player.jersey != null
                            ? '#${player.jersey}'
                            : player.position,
                        style: BgTypography.statNumber(Colors.white, size: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '${player.position} · ${player.classYear}',
                          style: BgTypography.eyebrow(BgColors.goldBright),
                        ),
                        Text(
                          player.name,
                          style: BgTypography.statNumber(Colors.white, size: 26),
                        ),
                      ],
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

class _BioCard extends StatelessWidget {
  const _BioCard({required this.player});

  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    final List<({String label, String value})> rows =
        <({String label, String value})>[
      (label: 'Position', value: player.position),
      (label: 'Class', value: player.classYear),
      (label: 'Height', value: player.height),
      (label: 'Weight', value: player.weight.isEmpty ? '—' : '${player.weight} lb'),
      (label: 'Hometown', value: player.hometown),
    ];
    return BgCard(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            Row(
              children: <Widget>[
                Text(
                  rows[i].label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  rows[i].value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (i < rows.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _PlayerStatGrid extends StatelessWidget {
  const _PlayerStatGrid({required this.stat, required this.sport});

  final PlayerStat stat;
  final String sport;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, dynamic>> entries = stat.stats.entries
        .where((MapEntry<String, dynamic> e) => e.value is num)
        .toList();

    return Column(
      children: <Widget>[
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
          ),
          itemCount: entries.length,
          itemBuilder: (BuildContext context, int i) {
            final MapEntry<String, dynamic> e = entries[i];
            final MetricLabel meta = playerLabelFor(e.key);
            return BgCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    meta.shortLabel.toUpperCase(),
                    style: BgTypography.eyebrow(BgColors.slate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    formatMetricValue(e.key, (e.value as num).toDouble(),
                        sport: sport),
                    style: BgTypography.statNumber(BgColors.deepBlue, size: 24),
                  ),
                  Text(
                    meta.displayName,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        BgCard(
          color: BgColors.blueTint,
          borderColor: Colors.transparent,
          child: SourceConfidenceRow(
            source: stat.source,
            updatedAt: stat.updatedAt,
            confidence: stat.confidence,
          ),
        ),
      ],
    );
  }
}
