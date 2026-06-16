import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/vault_providers.dart';
import '../../core/widgets/widgets.dart';

/// Full-screen reader for a single Vault Legend feature.
///
/// Route: /vault/legend/:legendId
class VaultLegendScreen extends ConsumerWidget {
  const VaultLegendScreen({super.key, required this.legendId});

  final String legendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<VaultLegend?> legendAsync =
        ref.watch(vaultLegendByIdProvider(legendId));

    return legendAsync.when(
      loading: () => const Scaffold(
        body: LoadingView(label: 'Opening the Vault'),
      ),
      error: (Object e, _) => Scaffold(
        appBar: AppBar(title: const Text('The Vault')),
        body: ErrorView(message: '$e'),
      ),
      data: (VaultLegend? legend) {
        if (legend == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('The Vault')),
            body: const EmptyView(
              title: 'Legend not found',
              icon: Icons.history_edu_rounded,
            ),
          );
        }
        return _LegendReader(legend: legend);
      },
    );
  }
}

class _LegendReader extends StatelessWidget {
  const _LegendReader({required this.legend});

  final VaultLegend legend;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          // Hero header
          SliverToBoxAdapter(
            child: _LegendHeroHeader(legend: legend),
          ),
          // Draft badge
          if (legend.isDraft)
            SliverToBoxAdapter(
              child: _DraftBadge(model: legend.model),
            ),
          // Body content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                // Pull quote
                if (legend.pullQuote.isNotEmpty) ...<Widget>[
                  _PullQuote(text: legend.pullQuote),
                  const SizedBox(height: 24),
                ],
                // Narrative sections
                for (final VaultLegendSection section in legend.sections) ...<Widget>[
                  _SectionBlock(section: section),
                  const SizedBox(height: 20),
                ],
                // By the Numbers
                if (legend.byTheNumbers.isNotEmpty) ...<Widget>[
                  _ByTheNumbers(items: legend.byTheNumbers),
                  const SizedBox(height: 24),
                ],
                // Closing line
                if (legend.closingLine.isNotEmpty) ...<Widget>[
                  Text(
                    legend.closingLine,
                    style: text.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: BgColors.slate,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                // Sources
                if (legend.sources.isNotEmpty) ...<Widget>[
                  _SourcesList(sources: legend.sources),
                  const SizedBox(height: 24),
                ],
                // Attribution footer
                _AttributionFooter(legend: legend),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero header
// ---------------------------------------------------------------------------

class _LegendHeroHeader extends StatelessWidget {
  const _LegendHeroHeader({required this.legend});

  final VaultLegend legend;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        gradient: BgColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Back button
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Era + sport chips
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      Pill(
                        label: legend.era,
                        color: BgColors.bluegrassGold,
                        dense: true,
                      ),
                      Pill(
                        label: _sportLabel(legend.sport),
                        color: Colors.white70,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    legend.title,
                    style: text.displayLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    legend.subtitle,
                    style: text.bodyLarge?.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    legend.subject.toUpperCase(),
                    style: BgTypography.eyebrow(BgColors.bluegrassGold),
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
        return 'Men\'s Basketball';
      case 'football':
        return 'Football';
      default:
        return sport;
    }
  }
}

// ---------------------------------------------------------------------------
// Draft badge
// ---------------------------------------------------------------------------

class _DraftBadge extends StatelessWidget {
  const _DraftBadge({required this.model});

  final String model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BgColors.warning.withValues(alpha: 0.10),
          border: Border.all(color: BgColors.warning.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.edit_note_rounded,
                size: 18, color: BgColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'AI-drafted from sourced research · pending editor review',
                style: TextStyle(
                  color: BgColors.warning,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              model,
              style: const TextStyle(
                color: BgColors.mist,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pull quote
// ---------------------------------------------------------------------------

class _PullQuote extends StatelessWidget {
  const _PullQuote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            BgColors.blueDark.withValues(alpha: 0.08),
            BgColors.deepBlue.withValues(alpha: 0.04),
          ],
        ),
        border: const Border(
          left: BorderSide(color: BgColors.bluegrassGold, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Text(
        '“$text”',
        style: GoogleFontsStyle.oswald(
          color: BgColors.blueDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          height: 1.35,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Narrative section
// ---------------------------------------------------------------------------

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});

  final VaultLegendSection section;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(section.heading, style: text.titleLarge),
        const SizedBox(height: 8),
        Text(
          section.body,
          style: text.bodyLarge?.copyWith(height: 1.6),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// By the Numbers
// ---------------------------------------------------------------------------

class _ByTheNumbers extends StatelessWidget {
  const _ByTheNumbers({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return BgCard(
      color: BgColors.blueTint,
      borderColor: BgColors.deepBlue.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.bar_chart_rounded,
                  size: 16, color: BgColors.deepBlue),
              const SizedBox(width: 6),
              Text(
                'BY THE NUMBERS',
                style: BgTypography.eyebrow(BgColors.deepBlue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final String item in items) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: BgColors.bluegrassGold,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: text.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sources list
// ---------------------------------------------------------------------------

class _SourcesList extends StatelessWidget {
  const _SourcesList({required this.sources});

  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.link_rounded, size: 15, color: BgColors.mist),
            const SizedBox(width: 6),
            Text(
              'SOURCES',
              style: BgTypography.eyebrow(BgColors.mist),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final String url in sources)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              url,
              style: text.bodySmall?.copyWith(
                color: BgColors.deepBlue,
                decoration: TextDecoration.underline,
                decorationColor: BgColors.deepBlue,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Attribution footer
// ---------------------------------------------------------------------------

class _AttributionFooter extends StatelessWidget {
  const _AttributionFooter({required this.legend});

  final VaultLegend legend;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BgColors.canvas,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Independent fan coverage · no official UK affiliation',
            style: text.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Confidence: ${legend.confidence}  ·  Model: ${legend.model}',
            style: text.bodySmall?.copyWith(fontSize: 10.5),
          ),
          if (legend.generatedAt != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              'Generated ${_fmtDate(legend.generatedAt!)}',
              style: text.bodySmall?.copyWith(fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Minimal Oswald helper (avoids importing google_fonts directly in widget)
// ---------------------------------------------------------------------------

/// Thin wrapper so _PullQuote can get an Oswald TextStyle without importing
/// google_fonts into the widget file (keeps the dependency visible via theme).
abstract final class GoogleFontsStyle {
  static TextStyle oswald({
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    FontStyle fontStyle = FontStyle.normal,
    double? height,
  }) {
    // Fallback to a serif-like system font — google_fonts is a dep of the app,
    // but we import it here cleanly.
    return TextStyle(
      fontFamily: 'Oswald',
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      height: height,
    );
  }
}
