import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers/vault_providers.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/widgets.dart';

/// Full-screen editorial reader for a single Vault Legend feature — the
/// flagship of The Vault's "Bluegrass Editorial" skin.
///
/// The Adolph Rupp "Baron of the Bluegrass" piece renders here: a full-bleed
/// blue-scrimmed hero with parallax + gold rafters rule + contour texture, a
/// sectioned magazine body (Space Grotesk headings, airy Inter body), a
/// pull-quote, an elegant "By the Numbers" list, and — kept visible — the
/// `status: draft` label and the sources / attribution colophon.
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
    final MediaQueryData mq = MediaQuery.of(context);
    final bool reduceMotion = mq.disableAnimations;
    final double topPadding = mq.padding.top;

    // A faint contour wash behind the whole article body (almanac feel),
    // painted once under the scrolling content (no blur, cheap CustomPainter).
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ContourTexture(
              color: Theme.of(context).colorScheme.primary,
              opacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.035
                  : 0.04,
              lineCount: 9,
              seed: 99,
            ),
          ),
          CustomScrollView(
            slivers: <Widget>[
              // Full-bleed editorial hero (parallax + collapsing title).
              SliverPersistentHeader(
                pinned: true,
                delegate: FeatureHero(
                  eyebrow: '${_sportLabel(legend.sport)} · ${legend.era}',
                  title: legend.title,
                  subtitle: legend.subtitle,
                  byline: legend.subject,
                  collapsedTitle: legend.title,
                  reduceMotion: reduceMotion,
                  topPadding: topPadding,
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildBody(context, reduceMotion),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, bool reduceMotion) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<Widget> children = <Widget>[];

    // Stagger helper: each block reveals slightly after the previous one.
    int step = 0;
    Widget reveal(Widget child) {
      final Widget wrapped = FadeSlideIn(
        delay: reduceMotion
            ? Duration.zero
            : Duration(milliseconds: 40 * step.clamp(0, 6)),
        child: child,
      );
      step++;
      return wrapped;
    }

    // Draft badge (attribution — keep visible).
    if (legend.isDraft) {
      children
        ..add(reveal(EditorialDraftBadge(model: legend.model)))
        ..add(const SizedBox(height: 24));
    }

    // Pull quote near the top, magazine-style.
    if (legend.pullQuote.isNotEmpty) {
      children
        ..add(reveal(EditorialPullQuote(text: legend.pullQuote)))
        ..add(const SizedBox(height: 28));
    }

    // Narrative sections (first one reads as the lead / standfirst).
    for (int i = 0; i < legend.sections.length; i++) {
      final VaultLegendSection section = legend.sections[i];
      children
        ..add(reveal(EditorialSection(
          heading: section.heading,
          body: section.body,
          isLead: i == 0,
        )))
        ..add(const SizedBox(height: 28));
    }

    // By the Numbers.
    if (legend.byTheNumbers.isNotEmpty) {
      children
        ..add(reveal(ByTheNumbersList(items: legend.byTheNumbers)))
        ..add(const SizedBox(height: 28));
    }

    // Closing line — an italic editorial sign-off.
    if (legend.closingLine.isNotEmpty) {
      children
        ..add(reveal(Text(
          legend.closingLine,
          style: text.bodyLarge?.copyWith(
            fontStyle: FontStyle.italic,
            height: 1.55,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        )))
        ..add(const SizedBox(height: 32));
    }

    // Sources + attribution colophon (keep visible).
    children.add(reveal(EditorialSourcesFooter(
      sources: legend.sources,
      confidence: legend.confidence,
      model: legend.model,
      generatedAt: legend.generatedAt,
    )));

    return children;
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
