import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';

/// A rounded surface card with soft tinted-shadow depth and a faint hairline —
/// the app's default container for grouped content.
///
/// Upgrades (Pass 1): 20px radius, soft [BgTheme.e1] elevation (or [BgTheme.e2]
/// when [elevated]), a springy press-scale on tap (reduce-motion aware), and an
/// optional 2px left accent rail. Surfaces and hairlines come from the active
/// theme so the card looks right in light AND dark mode.
class BgCard extends StatefulWidget {
  const BgCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BgTheme.lg16),
    this.onTap,
    this.gradient,
    this.color,
    this.borderColor,
    this.accentRail,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;

  /// Optional 2px left accent rail color (e.g. an accent or semantic tint).
  final Color? accentRail;

  /// Use the raised [BgTheme.e2] shadow instead of the resting [BgTheme.e1].
  final bool elevated;

  @override
  State<BgCard> createState() => _BgCardState();
}

class _BgCardState extends State<BgCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final bool reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final BorderRadius radius = BorderRadius.circular(BgTheme.radiusCard);

    final Color surface = widget.color ?? theme.colorScheme.surface;
    final Color border =
        widget.borderColor ??
        (widget.gradient != null
            ? Colors.transparent
            : theme.colorScheme.outline);

    Widget content = Padding(padding: widget.padding, child: widget.child);

    // Optional 2px left accent rail (kept inside the clip). IntrinsicHeight
    // lets the rail match the content height even in unbounded (scroll view)
    // contexts without forcing an infinite height.
    if (widget.accentRail != null) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(width: 2, color: widget.accentRail),
            Expanded(child: content),
          ],
        ),
      );
    }

    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        gradient: widget.gradient,
        color: widget.gradient == null ? surface : null,
        borderRadius: radius,
        border: Border.all(color: border),
        boxShadow: widget.elevated
            ? BgTheme.e2(dark: dark)
            : BgTheme.e1(dark: dark),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          borderRadius: radius,
          child: ClipRRect(borderRadius: radius, child: content),
        ),
      ),
    );

    if (widget.onTap == null || reduceMotion) return card;

    return AnimatedScale(
      scale: _pressed ? BgTheme.pressScale : 1.0,
      duration: BgTheme.motionMicro,
      curve: BgTheme.curveMicro,
      child: card,
    );
  }
}

/// A small rounded pill/badge for labels (sport, status, tags).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.color = BgColors.primary,
    this.background,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(BgTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 11 : 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled horizontal meter (0..1) used for confidence / fan meters.
///
/// Animates its fill on first paint (reduce-motion aware) so meters feel alive.
class MeterBar extends StatefulWidget {
  const MeterBar({
    super.key,
    required this.value,
    this.color = BgColors.primary,
    this.height = 10,
    this.trackColor,
    this.animate = true,
  });

  /// 0.0..1.0 fill.
  final double value;
  final Color color;
  final double height;
  final Color? trackColor;
  final bool animate;

  @override
  State<MeterBar> createState() => _MeterBarState();
}

class _MeterBarState extends State<MeterBar> {
  double _shown = 0;

  @override
  void initState() {
    super.initState();
    _shown = widget.animate ? 0 : widget.value;
    if (widget.animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _shown = widget.value);
      });
    }
  }

  @override
  void didUpdateWidget(covariant MeterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() => _shown = widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final double target = (reduceMotion ? widget.value : _shown)
        .clamp(0.0, 1.0);
    final Color track =
        widget.trackColor ?? Theme.of(context).colorScheme.outline;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height),
      child: Stack(
        children: <Widget>[
          Container(height: widget.height, color: track),
          AnimatedFractionallySizedBox(
            duration: reduceMotion ? Duration.zero : BgTheme.motionEmphasized,
            curve: BgTheme.curveEmphasized,
            widthFactor: target,
            alignment: Alignment.centerLeft,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    widget.color.withValues(alpha: 0.75),
                    widget.color,
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.height),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
