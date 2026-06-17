import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/typography.dart';
import 'contour_texture.dart';

/// Editorial component kit for The Vault's "Bluegrass Editorial" skin.
///
/// These are VAULT-LOCAL widgets (not shared) so the magazine treatment can
/// evolve without touching the app-wide design system. They lean on the shared
/// tokens (Space Grotesk via [BgTypography], [BgColors.goldRule], depth
/// shadows, the dark scheme) rather than redefining them.

// ---------------------------------------------------------------------------
// Eyebrow + gold "rafters" rule
// ---------------------------------------------------------------------------

/// A spaced, uppercase eyebrow (e.g. "MEN'S BASKETBALL · 1930–1972").
class EditorialEyebrow extends StatelessWidget {
  const EditorialEyebrow({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? Theme.of(context).colorScheme.primary;
    return Text(label.toUpperCase(), style: BgTypography.eyebrow(c));
  }
}

/// The thin gold "rafters" rule placed under headlines — the
/// championship-banner cue. A short gradient bar, never a large fill.
class GoldRafters extends StatelessWidget {
  const GoldRafters({super.key, this.width = 48, this.height = 3});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: BgColors.goldRule,
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section block — magazine headings + airy long-form body
// ---------------------------------------------------------------------------

/// A narrative section: a Space-Grotesk heading with a gold rafters rule, then
/// airy Inter body at long-form leading (~1.6). [isLead] enlarges the body for
/// the opening section (a magazine "standfirst").
class EditorialSection extends StatelessWidget {
  const EditorialSection({
    super.key,
    required this.heading,
    required this.body,
    this.isLead = false,
  });

  final String heading;
  final String body;
  final bool isLead;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          heading,
          style: text.titleLarge?.copyWith(fontSize: 22, height: 1.15),
        ),
        const SizedBox(height: 10),
        const GoldRafters(width: 40),
        const SizedBox(height: 14),
        Text(
          body,
          style: isLead
              ? text.bodyLarge?.copyWith(fontSize: 17, height: 1.55)
              : text.bodyLarge?.copyWith(height: 1.62),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pull-quote
// ---------------------------------------------------------------------------

/// A large editorial pull-quote: an oversized Space-Grotesk quotation mark, the
/// quote in the brand blue (or light blue in dark mode), framed by hairline
/// rules above and below for a calm, almanac feel.
class EditorialPullQuote extends StatelessWidget {
  const EditorialPullQuote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color accent = dark ? scheme.primary : BgColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outline),
          bottom: BorderSide(color: scheme.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Oversized opening quotation mark in gold.
          Text(
            '“',
            style: BgTypography.display(
              BgColors.accentGold,
              fontSize: 52,
              fontWeight: FontWeight.w700,
              height: 0.9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: BgTypography.display(
              accent,
              fontSize: 23,
              fontWeight: FontWeight.w600,
              height: 1.32,
              letterSpacing: -0.25,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// By the Numbers
// ---------------------------------------------------------------------------

/// An elegant "By the Numbers" list. Each row leads with a small gold tick and
/// renders the line at airy leading; the whole block sits on a faint blue tint
/// with a contour wash behind it for an almanac stat-box feel. Tabular figures
/// keep any numerals aligned.
class ByTheNumbersList extends StatelessWidget {
  const ByTheNumbersList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final BorderRadius radius = BorderRadius.circular(BgTheme.radiusHero);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark
            ? scheme.surfaceContainerHighest
            : BgColors.surfaceAlt,
        borderRadius: radius,
        border: Border.all(color: scheme.outline),
        boxShadow: BgTheme.e1(dark: dark),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ContourTexture(
                color: scheme.primary,
                opacity: dark ? 0.05 : 0.06,
                lineCount: 6,
                seed: 21,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const EditorialEyebrow(label: 'By the Numbers'),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (int i = 0; i < items.length; i++) ...<Widget>[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(height: 1, color: scheme.outline),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(top: 7, right: 12),
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            gradient: BgColors.goldRule,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            items[i],
                            style: text.bodyLarge?.copyWith(
                              height: 1.5,
                              fontFeatures: BgTypography.tabular,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Draft badge
// ---------------------------------------------------------------------------

/// The `status: draft` editorial label — a calm, framed note that the piece is
/// AI-drafted from sourced research and pending editor review. Attribution that
/// must stay visible.
class EditorialDraftBadge extends StatelessWidget {
  const EditorialDraftBadge({super.key, required this.model});

  final String model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BgColors.warning.withValues(alpha: 0.10),
        border: Border.all(color: BgColors.warning.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(BgTheme.radiusButton),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.edit_note_rounded, size: 18, color: BgColors.warning),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'DRAFT · AI-drafted from sourced research, pending editor review',
              style: TextStyle(
                color: BgColors.warning,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                height: 1.3,
              ),
            ),
          ),
          if (model.isNotEmpty) ...<Widget>[
            const SizedBox(width: 8),
            Text(
              model,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sources + attribution footer
// ---------------------------------------------------------------------------

/// The sources list + independent-coverage attribution footer. This MUST stay
/// visible — the Vault carries source / confidence / model attribution on every
/// piece. Rendered as a quiet, end-of-article colophon.
class EditorialSourcesFooter extends StatelessWidget {
  const EditorialSourcesFooter({
    super.key,
    required this.sources,
    required this.confidence,
    required this.model,
    this.generatedAt,
  });

  final List<String> sources;
  final String confidence;
  final String model;
  final DateTime? generatedAt;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (sources.isNotEmpty) ...<Widget>[
          const EditorialEyebrow(label: 'Sources'),
          const SizedBox(height: 12),
          for (final String url in sources)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.link_rounded,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      url,
                      style: text.bodySmall?.copyWith(
                        color: scheme.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
        Container(height: 1, color: scheme.outline),
        const SizedBox(height: 14),
        Text(
          'Independent fan coverage · no official UK affiliation',
          style: text.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          <String>[
            'Confidence: $confidence',
            if (model.isNotEmpty) 'Model: $model',
            if (generatedAt != null) 'Generated ${_fmtDate(generatedAt!)}',
          ].join('  ·  '),
          style: text.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Feature card (Vault index — Eras & Legends rail)
// ---------------------------------------------------------------------------

/// A large rounded (28px) editorial feature card for the Eras & Legends rail:
/// a blue-scrimmed surface with a faint contour wash, the era/sport eyebrow, an
/// optional draft chip, a Space-Grotesk headline, a gold rafters rule, and a
/// "Read the feature →" affordance. Full-bleed feel, depth shadow, press scale.
class EditorialFeatureCard extends StatefulWidget {
  const EditorialFeatureCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDraft = false,
    this.width = 290,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDraft;
  final double width;

  @override
  State<EditorialFeatureCard> createState() => _EditorialFeatureCardState();
}

class _EditorialFeatureCardState extends State<EditorialFeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final BorderRadius radius = BorderRadius.circular(BgTheme.radiusHero);
    final Gradient scrim =
        dark ? BgColors.nightGradient : BgColors.skyGradient;

    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        gradient: scrim,
        borderRadius: radius,
        boxShadow: BgTheme.e2(dark: dark),
        border: dark ? Border.all(color: BgColors.darkHairline) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          borderRadius: radius,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: ContourTexture(
                    color: Colors.white,
                    opacity: 0.07,
                    lineCount: 7,
                    // Vary the texture per-card by hashing the title.
                    seed: widget.title.hashCode & 0x7fffffff,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: EditorialEyebrow(
                              label: widget.eyebrow,
                              color: BgColors.accentGoldBright,
                            ),
                          ),
                          if (widget.isDraft) ...<Widget>[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    BgColors.warning.withValues(alpha: 0.22),
                                borderRadius:
                                    BorderRadius.circular(BgTheme.radiusChip),
                              ),
                              child: const Text(
                                'DRAFT',
                                style: TextStyle(
                                  color: BgColors.accentGoldBright,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // The headline block flexes so the card never overflows
                      // under a tight rail height.
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                widget.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: BgTypography.display(
                                  Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                  height: 1.12,
                                  letterSpacing: -0.25,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const GoldRafters(width: 36),
                            const SizedBox(height: 10),
                            Text(
                              widget.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.74),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Text(
                            'Read the feature',
                            style: BgTypography.eyebrow(
                              BgColors.accentGoldBright,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 14, color: BgColors.accentGoldBright),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      width: widget.width,
      child: AnimatedScale(
        scale: (_pressed && !reduceMotion) ? BgTheme.pressScale : 1.0,
        duration: BgTheme.motionMicro,
        curve: BgTheme.curveMicro,
        child: card,
      ),
    );
  }
}
