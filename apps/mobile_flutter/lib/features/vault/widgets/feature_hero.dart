import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/theme.dart';
import '../../../app/theme/typography.dart';
import 'contour_texture.dart';
import 'editorial_widgets.dart';

/// Full-bleed editorial hero for the Legend reader — the magazine cover.
///
/// A [SliverPersistentHeader] that:
///   * fills the top of the page with a deep Kentucky-blue scrim
///     ([BgColors.skyGradient] in light, [BgColors.nightGradient] in dark) so
///     white display type stays WCAG-AA legible;
///   * lays a faint, original contour texture behind the type (heritage/almanac
///     feel) via [ContourTexture] (CustomPainter, no images/blur);
///   * carries the eyebrow (sport · era), the big Space-Grotesk headline, the
///     subtitle, the gold "rafters" rule, and the subject byline;
///   * adds a gentle PARALLAX: the content drifts up at half-scroll speed as the
///     header collapses, and a compact pinned title cross-fades in;
///   * is reduce-motion aware (no parallax / no cross-fade when disabled).
class FeatureHero extends SliverPersistentHeaderDelegate {
  FeatureHero({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.byline,
    required this.collapsedTitle,
    required this.reduceMotion,
    required this.topPadding,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String byline;
  final String collapsedTitle;
  final bool reduceMotion;

  /// The status-bar inset (passed in from the screen's MediaQuery).
  final double topPadding;

  static const double _expanded = 340;

  @override
  double get maxExtent => _expanded + topPadding;

  @override
  double get minExtent => kToolbarHeight + topPadding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final double range = maxExtent - minExtent;
    final double t = range <= 0 ? 0 : (shrinkOffset / range).clamp(0.0, 1.0);

    // Content fades out and the collapsed title fades in over the back half of
    // the collapse so the two never both read at full strength.
    final double contentOpacity = reduceMotion ? 1 : (1 - t * 1.6).clamp(0.0, 1.0);
    final double collapsedOpacity =
        reduceMotion ? 0 : ((t - 0.55) / 0.45).clamp(0.0, 1.0);
    // Parallax: content drifts up at ~40% of the scroll speed.
    final double parallax = reduceMotion ? 0 : -shrinkOffset * 0.4;

    final Gradient scrim = dark ? BgColors.nightGradient : BgColors.skyGradient;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Blue scrim base.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: scrim,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(BgTheme.radiusHero),
            ),
          ),
        ),
        // Faint contour texture behind the type (clipped to the rounded scrim).
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(BgTheme.radiusHero),
            ),
            child: Opacity(
              opacity: contentOpacity,
              child: const ContourTexture(
                color: Colors.white,
                opacity: 0.07,
                lineCount: 8,
              ),
            ),
          ),
        ),
        // A soft darkening at the bottom so the subtitle/byline keep contrast
        // over the texture.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(BgTheme.radiusHero),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  BgColors.blueDark.withValues(alpha: dark ? 0.0 : 0.28),
                ],
                stops: const <double>[0.55, 1.0],
              ),
            ),
          ),
        ),

        // Expanded editorial content (parallax + fade).
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Transform.translate(
            offset: Offset(0, parallax),
            child: Opacity(
              opacity: contentOpacity,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    EditorialEyebrow(
                      label: eyebrow,
                      color: BgColors.accentGoldBright,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: BgTypography.display(
                        Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.03,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Gold rafters rule — the championship-banner cue.
                    const GoldRafters(width: 56),
                    const SizedBox(height: 14),
                    Text(
                      subtitle,
                      style: text.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.45,
                      ),
                    ),
                    if (byline.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(
                        byline.toUpperCase(),
                        style: BgTypography.eyebrow(
                          Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Collapsed pinned bar (compact title), cross-fading in.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: minExtent,
          child: IgnorePointer(
            ignoring: collapsedOpacity < 0.5,
            child: Opacity(
              opacity: collapsedOpacity,
              child: Padding(
                padding: EdgeInsets.only(top: topPadding),
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 52),
                    Expanded(
                      child: Text(
                        collapsedTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Back button (always tappable, sits above everything).
        Positioned(
          top: topPadding + math.max(0, (kToolbarHeight - 40) / 2),
          left: 4,
          child: Material(
            type: MaterialType.transparency,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant FeatureHero old) =>
      old.title != title ||
      old.subtitle != subtitle ||
      old.eyebrow != eyebrow ||
      old.byline != byline ||
      old.collapsedTitle != collapsedTitle ||
      old.reduceMotion != reduceMotion ||
      old.topPadding != topPadding;
}
