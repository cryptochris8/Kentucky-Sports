import 'package:flutter/material.dart';
import 'package:stats_engine/stats_engine.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';

/// A horizontal percentile bar (0..100) with a tier label.
///
/// Color is derived from the percentile tier so meaning is not color-only —
/// the tier label always accompanies the bar. The fill animates in on first
/// paint (reduce-motion aware).
class PercentileBar extends StatefulWidget {
  const PercentileBar({
    super.key,
    required this.percentile,
    this.showLabel = true,
    this.height = 8,
  });

  final int percentile;
  final bool showLabel;
  final double height;

  @override
  State<PercentileBar> createState() => _PercentileBarState();
}

class _PercentileBarState extends State<PercentileBar> {
  double _shown = 0;

  double get _target {
    final double pct = widget.percentile.clamp(0, 100) / 100;
    return pct == 0 ? 0.02 : pct;
  }

  Color get _color {
    switch (tierForPercentile(widget.percentile)) {
      case PercentileTier.elite:
        return BgColors.positive;
      case PercentileTier.excellent:
        return BgColors.primaryBright;
      case PercentileTier.good:
        return BgColors.primary;
      case PercentileTier.average:
        return BgColors.warning;
      case PercentileTier.belowAverage:
        return BgColors.negative;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = _target);
    });
  }

  @override
  void didUpdateWidget(covariant PercentileBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentile != widget.percentile) {
      setState(() => _shown = _target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final PercentileTier tier = tierForPercentile(widget.percentile);
    final Color color = _color;
    final Color track = Theme.of(context).colorScheme.outline;
    final double width = reduceMotion ? _target : _shown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  tier.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  '${widget.percentile}%ile',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.height),
          child: Stack(
            children: <Widget>[
              Container(height: widget.height, color: track),
              AnimatedFractionallySizedBox(
                duration:
                    reduceMotion ? Duration.zero : BgTheme.motionEmphasized,
                curve: BgTheme.curveEmphasized,
                widthFactor: width,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(widget.height),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
