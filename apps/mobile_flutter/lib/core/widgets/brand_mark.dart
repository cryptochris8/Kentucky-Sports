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
        gradient: BgColors.heroGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: BgColors.blueDark.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
      ..color = BgColors.bluegrassGold
      ..style = PaintingStyle.fill;
    final Paint goldBright = Paint()
      ..color = BgColors.goldBright
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

/// The full wordmark lockup: brand mark + "Bluegrass Gameday".
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.onDark = false, this.markSize = 34});

  final bool onDark;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    final Color title = onDark ? Colors.white : BgColors.ink;
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
              style: BgTypography.eyebrow(BgColors.bluegrassGold)
                  .copyWith(fontSize: 10, height: 1),
            ),
            Text(
              'Gameday',
              style: BgTypography.statNumber(title, size: 20)
                  .copyWith(height: 1),
            ),
          ],
        ),
      ],
    );
  }
}
