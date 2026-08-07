import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/vault_providers.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/widgets.dart';

/// Editorial season detail — shown when a row in the Season Timeline is tapped.
///
/// A textured blue masthead with the year as a big Space-Grotesk headline, an
/// editorial record display, the source / confidence attribution row (kept
/// visible), and a calm "more coming soon" note. Consistent with the Vault's
/// "Bluegrass Editorial" skin.
///
/// Route: /vault/season/:seasonId  (pushed as a full-screen detail above shell)
class VaultSeasonDetailScreen extends ConsumerWidget {
  const VaultSeasonDetailScreen({super.key, required this.seasonId});

  final String seasonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<VaultSeason?> seasonAsync =
        ref.watch(vaultSeasonByIdProvider(seasonId));

    return seasonAsync.when(
      loading: () => const Scaffold(
        body: LoadingView(label: 'Opening the Vault'),
      ),
      error: (Object e, _) => Scaffold(
        appBar: AppBar(title: const Text('The Vault')),
        body: ErrorView(message: '$e'),
      ),
      data: (VaultSeason? season) {
        if (season == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('The Vault')),
            body: const EmptyView(
              title: 'Season not found',
              icon: Icons.calendar_today_rounded,
            ),
          );
        }
        return _SeasonReader(season: season);
      },
    );
  }
}

class _SeasonReader extends StatelessWidget {
  const _SeasonReader({required this.season});

  final VaultSeason season;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _SeasonMasthead(season: season)),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                // Editorial record display.
                FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const EditorialEyebrow(label: 'Season Record'),
                      const SizedBox(height: 10),
                      Text(
                        season.record,
                        style: BgTypography.display(
                          scheme.primary,
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          height: 1.0,
                        ).copyWith(fontFeatures: BgTypography.tabular),
                      ),
                      const SizedBox(height: 12),
                      const GoldRafters(width: 48),
                      if (season.conferenceRecord != null) ...<Widget>[
                        const SizedBox(height: 16),
                        Text(
                          '${season.conference} play · ${season.conferenceRecord}',
                          style: text.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Container(height: 1, color: scheme.outline),
                      const SizedBox(height: 14),
                      SourceConfidenceRow(
                        source: season.source.toUpperCase(),
                        updatedAt: season.updatedAt,
                        confidence: season.confidence,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Coming-soon note (editorial card).
                FadeSlideIn(
                  delay: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 60),
                  child: BgCard(
                    color: scheme.surface,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.auto_stories_rounded,
                            size: 20, color: BgColors.accentGold),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('More of this chapter, soon',
                                  style: text.titleMedium),
                              const SizedBox(height: 6),
                              Text(
                                'Fuller season stats, game-by-game results, and '
                                'roster data will be layered in as modern '
                                'enrichment rolls out — especially for seasons '
                                'from ~2004 onward.',
                                style: text.bodyMedium?.copyWith(height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonMasthead extends StatelessWidget {
  const _SeasonMasthead({required this.season});

  final VaultSeason season;

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
                lineCount: 7,
                seed: season.seasonLabel.hashCode & 0x7fffffff,
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        EditorialEyebrow(
                          label: _sportLabel(season.sport),
                          color: BgColors.accentGoldBright,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          season.seasonLabel,
                          style: BgTypography.display(
                            Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            height: 1.0,
                          ).copyWith(fontFeatures: BgTypography.tabular),
                        ),
                        const SizedBox(height: 12),
                        const GoldRafters(width: 48),
                        const SizedBox(height: 12),
                        Text(
                          '${season.conference} · Kentucky Wildcats',
                          style: text.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
