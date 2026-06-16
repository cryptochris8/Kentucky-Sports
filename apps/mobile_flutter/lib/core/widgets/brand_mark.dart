import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';

/// An ORIGINAL, abstract bluegrass-inspired brand mark (NOT a UK logo/mascot).
///
/// A blue rounded-square emblem with an abstract gold "blade of grass" /
/// upward chevron motif. Purely geometric — no copyrighted marks.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: BgColors.skyGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: BgColors.primary.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.56, size * 0.56),
          painter: _BladePainter(),
        ),
      ),
    );
  }
}

class _BladePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint gold = Paint()
      ..color = BgColors.accentGold
      ..style = PaintingStyle.fill;
    final Paint goldBright = Paint()
      ..color = BgColors.accentGoldBright
      ..style = PaintingStyle.fill;

    // Abstract upward chevron / blade of grass (three rising strokes).
    final double w = size.width;
    final double h = size.height;

    final Path center = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.66, h * 0.55)
      ..lineTo(w * 0.5, h)
      ..lineTo(w * 0.34, h * 0.55)
      ..close();
    canvas.drawPath(center, goldBright);

    final Path left = Path()
      ..moveTo(w * 0.18, h * 0.28)
      ..lineTo(w * 0.34, h * 0.62)
      ..lineTo(w * 0.26, h)
      ..lineTo(w * 0.06, h * 0.6)
      ..close();
    canvas.drawPath(left, gold);

    final Path right = Path()
      ..moveTo(w * 0.82, h * 0.28)
      ..lineTo(w * 0.66, h * 0.62)
      ..lineTo(w * 0.74, h)
      ..lineTo(w * 0.94, h * 0.6)
      ..close();
    canvas.drawPath(right, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A faint, large-scale "blades" texture for hero corners / banners.
///
/// Repeats the abstract chevron motif at a very low opacity (2-4%) so it reads
/// as a premium watermark rather than a logo. Decorative only — never a fill.
/// Wrap behind hero content; it ignores pointer events.
class BladesTexture extends StatelessWidget {
  const BladesTexture({
    super.key,
    this.color,
    this.opacity = 0.03,
    this.bladeCount = 5,
  });

  /// Defaults to the gold accent (the "championship banner" cue).
  final Color? color;
  final double opacity;
  final int bladeCount;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _BladesTexturePainter(
          color: (color ?? BgColors.accentGold).withValues(alpha: opacity),
          bladeCount: bladeCount,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _BladesTexturePainter extends CustomPainter {
  _BladesTexturePainter({required this.color, required this.bladeCount});

  final Color color;
  final int bladeCount;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // A field of tall, slim upward blades fanning from the bottom edge.
    final double step = size.width / (bladeCount + 1);
    for (int i = 1; i <= bladeCount; i++) {
      final double x = step * i;
      final double bladeW = step * 0.34;
      final double top = size.height * (0.18 + (i.isEven ? 0.10 : 0.0));
      final Path blade = Path()
        ..moveTo(x, top)
        ..lineTo(x + bladeW, size.height)
        ..lineTo(x - bladeW, size.height)
        ..close();
      canvas.drawPath(blade, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BladesTexturePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bladeCount != bladeCount;
}

/// The full wordmark lockup: brand mark + "Bluegrass Gameday".
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.onDark = false, this.markSize = 34});

  final bool onDark;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    final Color title = onDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        BrandMark(size: markSize),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'BLUEGRASS',
              style: BgTypography.eyebrow(
                BgColors.accentGold,
              ).copyWith(fontSize: 10, height: 1),
            ),
            Text(
              'Gameday',
              style: BgTypography.statNumber(title, size: 20).copyWith(
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
