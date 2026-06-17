import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/vault_providers.dart';
import '../../core/widgets/widgets.dart';
import 'vault_season_detail_screen.dart';
import 'widgets/widgets.dart';

/// The Vault — Kentucky History, rendered as a premium "Bluegrass Editorial"
/// almanac.
///
/// Two sections:
///   1. Eras & Legends rail — horizontal scroll of editorial feature cards.
///   2. Season Timeline — Football / Men's Basketball toggle, an editorial
///      list/table with tabular W-L figures.
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  // 0 = Football, 1 = Men's Basketball
  int _sportIndex = 0;

  String get _sport => _sportIndex == 0 ? 'football' : 'mens_basketball';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vaultSeasonsProvider);
          ref.invalidate(vaultLegendsProvider);
        },
        child: CustomScrollView(
          slivers: <Widget>[
            // Editorial masthead.
            const SliverToBoxAdapter(child: _VaultMasthead()),

            // Eras & Legends rail.
            const SliverToBoxAdapter(
              child: _EditorialSectionHeader(
                eyebrow: 'Feature reads',
                title: 'Eras & Legends',
              ),
            ),
            const SliverToBoxAdapter(child: _LegendsRail()),

            // Season Timeline + sport toggle.
            SliverToBoxAdapter(
              child: _SeasonTimelineHeader(
                index: _sportIndex,
                onChanged: (int i) => setState(() => _sportIndex = i),
              ),
            ),
            _SeasonList(sport: _sport),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Masthead
// ---------------------------------------------------------------------------

class _VaultMasthead extends StatelessWidget {
  const _VaultMasthead();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius radius = const BorderRadius.vertical(
      bottom: Radius.circular(BgTheme.radiusHero),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: dark ? BgColors.nightGradient : BgColors.skyGradient,
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ContourTexture(
                color: Colors.white,
                opacity: 0.07,
                lineCount: 8,
                seed: 3,
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.menu_book_rounded,
                            color: BgColors.accentGoldBright, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'THE VAULT',
                          style: BgTypography.eyebrow(
                            BgColors.accentGoldBright,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Kentucky History.',
                      style: BgTypography.display(
                        Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const GoldRafters(width: 56),
                    const SizedBox(height: 12),
                    Text(
                      'Season records, eras & legends — the full UK story, '
                      'told like an almanac.',
                      style: text.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editorial section header (gold rafters + eyebrow + Space-Grotesk title)
// ---------------------------------------------------------------------------

class _EditorialSectionHeader extends StatelessWidget {
  const _EditorialSectionHeader({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          EditorialEyebrow(label: eyebrow),
          const SizedBox(height: 8),
          Text(title, style: text.displayMedium?.copyWith(fontSize: 28)),
          const SizedBox(height: 10),
          const GoldRafters(width: 44),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legends rail
// ---------------------------------------------------------------------------

class _LegendsRail extends ConsumerWidget {
  const _LegendsRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<VaultLegend>> legendsAsync =
        ref.watch(vaultLegendsProvider);

    return legendsAsync.when(
      loading: () => const SizedBox(
        height: 240,
        child: LoadingView(label: 'Loading features'),
      ),
      error: (Object e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: ErrorView(message: '$e'),
      ),
      data: (List<VaultLegend> legends) {
        if (legends.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: EmptyView(
              title: 'No legends published yet',
              icon: Icons.history_edu_rounded,
            ),
          );
        }
        return SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            itemCount: legends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (BuildContext context, int i) {
              final VaultLegend legend = legends[i];
              return EditorialFeatureCard(
                eyebrow: '${_sportLabel(legend.sport)} · ${legend.era}',
                title: legend.title,
                subtitle: legend.subtitle,
                isDraft: legend.isDraft,
                onTap: () => context.push(Routes.vaultLegend(legend.id)),
              );
            },
          ),
        );
      },
    );
  }

  String _sportLabel(String sport) {
    switch (sport) {
      case 'mens_basketball':
        return "Men's Basketball";
      case 'football':
        return 'Football';
      default:
        return sport;
    }
  }
}

// ---------------------------------------------------------------------------
// Season Timeline header (editorial header + segmented sport toggle)
// ---------------------------------------------------------------------------

class _SeasonTimelineHeader extends StatelessWidget {
  const _SeasonTimelineHeader({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _EditorialSectionHeader(
          eyebrow: 'The record book',
          title: 'Season Timeline',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SegmentedToggle(
            index: index,
            onChanged: onChanged,
            segments: const <SegmentItem>[
              SegmentItem(
                  label: 'Football', icon: Icons.sports_football_rounded),
              SegmentItem(
                  label: 'Basketball', icon: Icons.sports_basketball_rounded),
            ],
          ),
        ),
        // Column captions for the table.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 64,
                child: Text('SEASON',
                    style: BgTypography.eyebrow(
                        Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('RECORD',
                    style: BgTypography.eyebrow(
                        Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
              Text('SOURCE',
                  style: BgTypography.eyebrow(
                      Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Season list (editorial table)
// ---------------------------------------------------------------------------

class _SeasonList extends ConsumerWidget {
  const _SeasonList({required this.sport});

  final String sport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<VaultSeason>> seasonsAsync =
        ref.watch(vaultSeasonsBySportProvider(sport));

    return seasonsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: LoadingView(label: 'Loading seasons'),
        ),
      ),
      error: (Object e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ErrorView(message: '$e'),
        ),
      ),
      data: (List<VaultSeason> seasons) {
        if (seasons.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyView(
              title: 'No seasons found',
              icon: Icons.calendar_today_rounded,
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: seasons.length,
            separatorBuilder: (BuildContext context, _) => Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outline,
            ),
            itemBuilder: (BuildContext context, int i) =>
                _SeasonRow(season: seasons[i]),
          ),
        );
      },
    );
  }
}

class _SeasonRow extends StatelessWidget {
  const _SeasonRow({required this.season});

  final VaultSeason season;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool isBasketball = season.sport == 'mens_basketball';

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VaultSeasonDetailScreen(season: season),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: <Widget>[
            // Season label — tabular so years align in the column.
            SizedBox(
              width: 64,
              child: Text(
                season.seasonLabel,
                style: BgTypography.display(
                  scheme.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.25,
                ).copyWith(fontFeatures: BgTypography.tabular),
              ),
            ),
            const SizedBox(width: 12),
            // Record + conference line.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    season.record,
                    style: text.titleMedium?.copyWith(
                      fontSize: 16,
                      fontFeatures: BgTypography.tabular,
                    ),
                  ),
                  if (season.conferenceRecord != null || !isBasketball) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(_confLine(season), style: text.bodySmall),
                  ],
                ],
              ),
            ),
            // Source confidence + chevron.
            ConfidenceLabel(confidence: season.confidence),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: scheme.outline),
          ],
        ),
      ),
    );
  }

  String _confLine(VaultSeason s) {
    final StringBuffer buf = StringBuffer(s.conference);
    if (s.conferenceRecord != null) buf.write(' · ${s.conferenceRecord}');
    return buf.toString();
  }
}
