import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/typography.dart';

/// Broadcast skin primitives — Pass 3 ("Modern Broadcast", Direction A).
///
/// ESPN-caliber live-sports cues for the Gameday surfaces: navy
/// "scorebug / lower-third" panels (always [BgColors.nightGradient] with white
/// text), a thin gold rule accent (the championship-banner cue), and big SOLID
/// score numbers in the condensed broadcast face ([BgTypography.broadcast] =
/// Oswald).
///
/// Readability lesson (2025 scorebug pass): scores and key stats stay SOLID and
/// high-contrast — never glassy/translucent. Punchy, fast motion (count-up
/// scores, springy chips) — all honor reduce-motion via
/// [MediaQuery.maybeDisableAnimationsOf].

/// A thin gold rule — the "lower-third banner" accent. Defaults to a short
/// 40px underline; pass [width] = `double.infinity` for a full-width hairline.
class GoldRule extends StatelessWidget {
  const GoldRule({super.key, this.width = 40, this.height = 3});

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

/// A navy broadcast "lower-third" panel — the signature Gameday container.
///
/// Always renders on [BgColors.nightGradient] (high-contrast white text) so it
/// reads identically in light AND dark mode, like a real broadcast scorebug. A
/// thin gold rule sits under an optional [eyebrow]. Use for matchup heros, stat
/// strips, and verdict panels. Tappable surfaces get a springy press-scale.
class BroadcastPanel extends StatefulWidget {
  const BroadcastPanel({
    super.key,
    required this.child,
    this.eyebrow,
    this.eyebrowIcon,
    this.trailing,
    this.padding = const EdgeInsets.all(BgTheme.lg16),
    this.onTap,
  });

  final Widget child;

  /// Optional broadcast eyebrow (e.g. "MATCHUP VERDICT") with a gold rule.
  final String? eyebrow;
  final IconData? eyebrowIcon;

  /// Optional trailing widget shown on the eyebrow row (e.g. a status pill).
  final Widget? trailing;

  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  State<BroadcastPanel> createState() => _BroadcastPanelState();
}

class _BroadcastPanelState extends State<BroadcastPanel> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final BorderRadius radius = BorderRadius.circular(BgTheme.radiusCard);

    Widget content = widget.child;
    if (widget.eyebrow != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (widget.eyebrowIcon != null) ...<Widget>[
                Icon(widget.eyebrowIcon, size: 14, color: BgColors.goldBright),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  widget.eyebrow!.toUpperCase(),
                  style: BgTypography.eyebrow(BgColors.goldBright),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
          const SizedBox(height: 8),
          const GoldRule(),
          const SizedBox(height: 14),
          widget.child,
        ],
      );
    }

    final Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        gradient: BgColors.nightGradient,
        borderRadius: radius,
        border: Border.all(
          color: BgColors.goldBright.withValues(alpha: 0.18),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: BgColors.darkBg.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          borderRadius: radius,
          child: ClipRRect(
            borderRadius: radius,
            child: Padding(padding: widget.padding, child: content),
          ),
        ),
      ),
    );

    if (widget.onTap == null || reduceMotion) return panel;
    return AnimatedScale(
      scale: _pressed ? BgTheme.pressScale : 1.0,
      duration: BgTheme.motionMicro,
      curve: BgTheme.curveMicro,
      child: panel,
    );
  }
}

/// A big SOLID broadcast score number (Oswald, tabular) that counts up from 0
/// on first paint. Reduce-motion aware (renders the final value instantly when
/// animations are disabled). Kept solid/high-contrast — never translucent.
class CountUpScore extends StatefulWidget {
  const CountUpScore({
    super.key,
    required this.value,
    this.size = 44,
    this.color = Colors.white,
    this.duration = const Duration(milliseconds: 650),
  });

  final int value;
  final double size;
  final Color color;
  final Duration duration;

  @override
  State<CountUpScore> createState() => _CountUpScoreState();
}

class _CountUpScoreState extends State<CountUpScore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CountUpScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final TextStyle style = BgTypography.broadcast(
      widget.color,
      fontSize: widget.size,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      height: 1.0,
    ).copyWith(fontFeatures: BgTypography.tabular);

    if (reduceMotion) {
      return Text('${widget.value}', style: style);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final int shown =
            (widget.value * Curves.easeOutCubic.transform(_controller.value))
                .round();
        return Text('$shown', style: style);
      },
    );
  }
}

/// A single solid, high-contrast stat in a broadcast strip: a big Oswald value
/// over a small white-on-navy label. Optional 0..1 [meter] draws a solid fill
/// bar beneath (kept solid per the scorebug-readability rule).
class BroadcastStat extends StatelessWidget {
  const BroadcastStat({
    super.key,
    required this.value,
    required this.label,
    this.valueColor = Colors.white,
    this.meter,
    this.meterColor,
    this.valueSize = 30,
    this.alignEnd = false,
  });

  final String value;
  final String label;
  final Color valueColor;

  /// Optional 0..1 meter drawn beneath the value (solid fill).
  final double? meter;
  final Color? meterColor;
  final double valueSize;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final CrossAxisAlignment cross =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: BgTypography.eyebrow(
            Colors.white.withValues(alpha: 0.7),
          ).copyWith(letterSpacing: 1.0),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: BgTypography.broadcast(
            valueColor,
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
          ).copyWith(fontFeatures: BgTypography.tabular),
        ),
        if (meter != null) ...<Widget>[
          const SizedBox(height: 8),
          _SolidMeter(
            value: meter!.clamp(0.0, 1.0),
            color: meterColor ?? valueColor,
          ),
        ],
      ],
    );
  }
}

/// A solid (non-glassy) meter bar on a navy panel. Animates its fill in on
/// first paint, reduce-motion aware. Intentionally NOT translucent — key stat
/// bars stay high-contrast on broadcast surfaces.
class _SolidMeter extends StatefulWidget {
  const _SolidMeter({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  State<_SolidMeter> createState() => _SolidMeterState();
}

class _SolidMeterState extends State<_SolidMeter> {
  double _shown = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = widget.value);
    });
  }

  @override
  void didUpdateWidget(covariant _SolidMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() => _shown = widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final double target = reduceMotion ? widget.value : _shown;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: <Widget>[
          Container(
            height: 6,
            color: Colors.white.withValues(alpha: 0.16),
          ),
          AnimatedFractionallySizedBox(
            duration: reduceMotion ? Duration.zero : BgTheme.motionEmphasized,
            curve: BgTheme.curveEmphasized,
            widthFactor: target,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A springy broadcast chip — a small solid label that bounces on press. Used
/// for status cues (LIVE / FINAL / sport) on navy panels. Reduce-motion aware.
class BroadcastChip extends StatelessWidget {
  const BroadcastChip({
    super.key,
    required this.label,
    this.icon,
    this.color = Colors.white,
    this.background,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color? background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: BgTypography.broadcast(
              color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return _SpringyTap(onTap: onTap!, child: chip);
  }
}

/// Wraps a child with a quick springy press-scale. Reduce-motion aware.
class _SpringyTap extends StatefulWidget {
  const _SpringyTap({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_SpringyTap> createState() => _SpringyTapState();
}

class _SpringyTapState extends State<_SpringyTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: (_pressed && !reduceMotion) ? 0.93 : 1.0,
        duration: BgTheme.motionMicro,
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// A purely DECORATIVE broadcast accent line — an abstract "energy wave" drawn
/// across the bottom of a panel. This is NOT real play-by-play/score-over-time
/// data (the seed has none); it is a fixed, generative wave used only as a
/// visual broadcast cue and is hidden from semantics. Honors reduce-motion by
/// rendering statically (the wave never animates as if it were live data).
class BroadcastWaveAccent extends StatelessWidget {
  const BroadcastWaveAccent({
    super.key,
    this.height = 28,
    this.color,
  });

  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _WavePainter(
            color: color ?? BgColors.goldBright.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();
    final double midY = size.height / 2;
    const int segments = 48;
    for (int i = 0; i <= segments; i++) {
      final double x = size.width * (i / segments);
      // A fixed, non-data decorative waveform (two stacked sines).
      final double t = i / segments * math.pi * 6;
      final double y = midY +
          math.sin(t) * (size.height * 0.22) +
          math.sin(t * 2.3) * (size.height * 0.10);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color;
}
