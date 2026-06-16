import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/vault_providers.dart';
import '../../core/widgets/widgets.dart';
import 'vault_season_detail_screen.dart';

/// The Vault — Kentucky History.
///
/// Two sections:
///   1. Eras & Legends rail — horizontal scroll of narrative feature cards.
///   2. Season timeline — Football / Men's Basketball toggle, scrollable list.
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
            // Header
            SliverToBoxAdapter(child: _VaultHeader()),

            // Eras & Legends rail
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Eras & Legends',
                eyebrow: 'Feature reads',
                icon: Icons.history_edu_rounded,
              ),
            ),
            const SliverToBoxAdapter(child: _LegendsRail()),

            // Sport toggle + season spine
            SliverToBoxAdapter(
              child: _SportToggle(
                index: _sportIndex,
                onChanged: (int i) => setState(() => _sportIndex = i),
              ),
            ),
            _SeasonList(sport: _sport),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _VaultHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        gradient: BgColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(Icons.lock_open_rounded,
                    color: BgColors.bluegrassGold, size: 22),
                const SizedBox(width: 8),
                Text(
                  'THE VAULT',
                  style: BgTypography.eyebrow(BgColors.bluegrassGold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Kentucky History.',
              style: text.displayLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Season records, eras & legends — the full UK story.',
              style: text.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
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
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
      error: (Object e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorView(message: '$e'),
      ),
      data: (List<VaultLegend> legends) {
        if (legends.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: EmptyView(
              title: 'No legends published yet',
              icon: Icons.history_edu_rounded,
            ),
          );
        }
        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: legends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int i) =>
                _LegendCard(legend: legends[i]),
          ),
        );
      },
    );
  }
}

class _LegendCard extends StatelessWidget {
  const _LegendCard({required this.legend});

  final VaultLegend legend;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return SizedBox(
      width: 260,
      child: BgCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[BgColors.blueDark, BgColors.deepBlue],
        ),
        onTap: () => context.push(Routes.vaultLegend(legend.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Wrap(
              spacing: 6,
              children: <Widget>[
                Pill(
                  label: legend.era,
                  color: BgColors.bluegrassGold,
                  dense: true,
                ),
                if (legend.isDraft)
                  const Pill(
                    label: 'DRAFT',
                    color: BgColors.warning,
                    dense: true,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              legend.title,
              style: text.titleLarge?.copyWith(
                color: Colors.white,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              legend.subtitle,
              style: text.bodySmall?.copyWith(
                color: Colors.white60,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: BgColors.bluegrassGold),
                const SizedBox(width: 4),
                Text(
                  'Read the feature',
                  style: BgTypography.eyebrow(BgColors.bluegrassGold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sport toggle
// ---------------------------------------------------------------------------

class _SportToggle extends StatelessWidget {
  const _SportToggle({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: <Widget>[
          // Gold bar accent (matches SectionHeader style)
          Container(
            width: 4,
            height: 22,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: BgColors.goldGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Text(
            'Season Timeline',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          _SportChip(
            label: 'Football',
            icon: Icons.sports_football_rounded,
            selected: index == 0,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 8),
          _SportChip(
            label: 'Basketball',
            icon: Icons.sports_basketball_rounded,
            selected: index == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _SportChip extends StatelessWidget {
  const _SportChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? BgColors.deepBlue : BgColors.canvas,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? BgColors.deepBlue : BgColors.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14,
                color: selected ? Colors.white : BgColors.slate),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : BgColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Season list
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
          padding: const EdgeInsets.all(16),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: seasons.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
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
    final TextTheme text = Theme.of(context).textTheme;
    final bool isBasketball = season.sport == 'mens_basketball';

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VaultSeasonDetailScreen(season: season),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: <Widget>[
            // Year label
            SizedBox(
              width: 70,
              child: Text(
                season.seasonLabel,
                style: BgTypography.statNumber(BgColors.deepBlue, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            // Record + conference
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    season.record,
                    style: text.titleMedium,
                  ),
                  if (season.conferenceRecord != null || !isBasketball)
                    Text(
                      _confLine(season),
                      style: text.bodySmall,
                    ),
                ],
              ),
            ),
            // Source chip + chevron
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ConfidenceLabel(confidence: season.confidence),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: BgColors.mist),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _confLine(VaultSeason s) {
    final StringBuffer buf = StringBuffer(s.conference);
    if (s.conferenceRecord != null) buf.write(' ${s.conferenceRecord}');
    return buf.toString();
  }
}
