import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Slow, elegant fade + slide-up reveal for editorial blocks in The Vault.
///
/// Plays once when the widget is first built (i.e. scrolled into view, since
/// sliver children build lazily as they enter the viewport). Honors
/// reduce-motion: when animations are disabled the child is shown immediately
/// with no transform.
///
/// Motion uses [BgTheme.motionEmphasized] (~380ms easeOutQuint) to match the
/// app's emphasized token, with an optional [delay] to gently stagger a stack
/// of sections.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  final Widget child;

  /// Stagger delay before the reveal begins.
  final Duration delay;

  /// Vertical travel (logical px) the child slides up through.
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: BgTheme.motionEmphasized,
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: BgTheme.curveEmphasized,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.value = 1;
      return;
    }
    // Defer to the next frame so the reveal reads as an entrance, then apply
    // the optional stagger delay.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        Future<void>.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: _curve.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _curve.value) * widget.offset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
