import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

/// Direction of a trend used for the arrow + color.
enum TrendDirection { up, down, flat }

/// A small trend arrow with optional label, colored by direction and whether
/// the direction is "good" for the metric.
class TrendArrow extends StatelessWidget {
  const TrendArrow({
    super.key,
    required this.direction,
    this.goodWhenUp = true,
    this.label,
    this.size = 16,
  });

  final TrendDirection direction;

  /// Whether an upward trend is positive for this metric.
  final bool goodWhenUp;
  final String? label;
  final double size;

  Color get _color {
    if (direction == TrendDirection.flat) return BgColors.mist;
    final bool isUp = direction == TrendDirection.up;
    final bool good = isUp == goodWhenUp;
    return good ? BgColors.positive : BgColors.negative;
  }

  IconData get _icon {
    switch (direction) {
      case TrendDirection.up:
        return Icons.trending_up_rounded;
      case TrendDirection.down:
        return Icons.trending_down_rounded;
      case TrendDirection.flat:
        return Icons.trending_flat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(_icon, size: size, color: _color),
        if (label != null) ...<Widget>[
          const SizedBox(width: 3),
          Text(
            label!,
            style: TextStyle(
              color: _color,
              fontSize: size * 0.78,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
