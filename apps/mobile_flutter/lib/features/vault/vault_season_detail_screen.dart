import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/widgets/widgets.dart';

/// A simple season detail screen shown when the user taps a row in the
/// Vault season timeline.
///
/// Displays the record and a "fuller season stats coming soon" note.
/// Route: /vault/season/:seasonId  (pushed as a full-screen detail above shell)
class VaultSeasonDetailScreen extends StatelessWidget {
  const VaultSeasonDetailScreen({super.key, required this.season});

  final VaultSeason season;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: BgColors.heroGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(26)),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _sportLabel(season.sport).toUpperCase(),
                            style: BgTypography.eyebrow(BgColors.bluegrassGold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            season.seasonLabel,
                            style: text.displayLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            season.conference,
                            style: text.bodyLarge
                                ?.copyWith(color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                // Record card
                BgCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'SEASON RECORD',
                        style: BgTypography.eyebrow(BgColors.slate),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        season.record,
                        style: BgTypography.statNumber(
                          BgColors.deepBlue,
                          size: 48,
                        ),
                      ),
                      if (season.conferenceRecord != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Text(
                              '${season.conference}:  ',
                              style: text.bodySmall,
                            ),
                            Text(
                              season.conferenceRecord!,
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      SourceConfidenceRow(
                        source: season.source.toUpperCase(),
                        updatedAt: season.updatedAt,
                        confidence: season.confidence,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Coming-soon note
                BgCard(
                  color: BgColors.canvas,
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.construction_rounded,
                          size: 20, color: BgColors.bluegrassGold),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'More coming soon',
                              style: text.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fuller season stats, game-by-game results, '
                              'and roster data will be layered in as modern '
                              'enrichment rolls out — especially for seasons '
                              'from ~2004 onward.',
                              style: text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _sportLabel(String sport) {
    switch (sport) {
      case 'mens_basketball':
        return 'Men\'s Basketball';
      case 'football':
        return 'Football';
      default:
        return sport;
    }
  }
}
