import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A faint, original topographic / contour-line texture for The Vault's
/// "Bluegrass Editorial" skin.
///
/// This is an ORIGINAL abstract pattern — layered sine "ridgelines" reminiscent
/// of an almanac / heritage map. It is NOT a University of Kentucky mark and
/// carries no logo or trademarked art. Drawn with [CustomPainter] (cheap, no
/// images, no blur) so it is safe behind scrolling feature sections.
///
/// Tune the mood with [color] and [opacity]; the painter stays faint by design
/// so body copy laid over it remains WCAG-AA legible.
class ContourTexture extends StatelessWidget {
  const ContourTexture({
    super.key,
    this.color,
    this.opacity = 0.05,
    this.lineCount = 7,
    this.seed = 7,
  });

  /// Base line color. Defaults to the theme primary so it adapts to light/dark.
  final Color? color;

  /// Master opacity for the whole texture (kept low for legibility).
  final double opacity;

  /// How many contour ridgelines to draw.
  final int lineCount;

  /// Deterministic seed so the texture is stable across rebuilds.
  final int seed;

  @override
  Widget build(BuildContext context) {
    final Color base = color ?? Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ContourPainter(
            color: base,
            opacity: opacity,
            lineCount: lineCount,
            seed: seed,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ContourPainter extends CustomPainter {
  _ContourPainter({
    required this.color,
    required this.opacity,
    required this.lineCount,
    required this.seed,
  });

  final Color color;
  final double opacity;
  final int lineCount;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final math.Random rnd = math.Random(seed);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final double spacing = size.height / (lineCount + 1);
    const int samples = 48;

    for (int i = 0; i < lineCount; i++) {
      // Each ridgeline gets its own gentle wave parameters.
      final double baseY = spacing * (i + 1);
      final double amp = spacing * (0.45 + rnd.nextDouble() * 0.7);
      final double freq = 1.1 + rnd.nextDouble() * 1.6;
      final double phase = rnd.nextDouble() * math.pi * 2;

      // Fade the outermost lines a touch so the texture feels hand-drawn.
      final double edgeFade =
          1 - (((i - (lineCount - 1) / 2).abs()) / lineCount) * 0.5;
      paint.color = color.withValues(alpha: opacity * edgeFade);

      final Path path = Path();
      for (int s = 0; s <= samples; s++) {
        final double t = s / samples;
        final double x = t * size.width;
        final double y = baseY +
            math.sin(t * math.pi * freq + phase) * amp +
            math.sin(t * math.pi * freq * 2.3 + phase * 1.7) * amp * 0.25;
        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContourPainter old) =>
      old.color != color ||
      old.opacity != opacity ||
      old.lineCount != lineCount ||
      old.seed != seed;
}
