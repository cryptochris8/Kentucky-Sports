import 'package:flutter/material.dart';
import 'package:stats_engine/stats_engine.dart';

import '../../app/theme/colors.dart';

/// A horizontal percentile bar (0..100) with a tier label.
///
/// Color is derived from the percentile tier so meaning is not color-only —
/// the tier label always accompanies the bar.
class PercentileBar extends StatelessWidget {
  const PercentileBar({
    super.key,
    required this.percentile,
    this.showLabel = true,
    this.height = 8,
  });

  final int percentile;
  final bool showLabel;
  final double height;

  Color get _color {
    switch (tierForPercentile(percentile)) {
      case PercentileTier.elite:
        return BgColors.positive;
      case PercentileTier.excellent:
        return BgColors.blueBright;
      case PercentileTier.good:
        return BgColors.deepBlue;
      case PercentileTier.average:
        return BgColors.warning;
      case PercentileTier.belowAverage:
        return BgColors.negative;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double pct = (percentile.clamp(0, 100)) / 100;
    final PercentileTier tier = tierForPercentile(percentile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  tier.label,
                  style: TextStyle(
                    color: _color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  '$percentile%ile',
                  style: const TextStyle(
                    color: BgColors.slate,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Stack(
            children: <Widget>[
              Container(height: height, color: BgColors.hairline),
              FractionallySizedBox(
                widthFactor: pct == 0 ? 0.02 : pct,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(height),
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
