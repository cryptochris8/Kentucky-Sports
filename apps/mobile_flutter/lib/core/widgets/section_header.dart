import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';

/// A broadcast-style section header with an optional gold accent bar, eyebrow,
/// and trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
    this.icon,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 10),
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final IconData? icon;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 3,
            height: 24,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              gradient: BgColors.goldRule,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (eyebrow != null)
                  Text(
                    eyebrow!.toUpperCase(),
                    style: BgTypography.eyebrow(BgColors.accentGold),
                  ),
                Row(
                  children: <Widget>[
                    if (icon != null) ...<Widget>[
                      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        style: text.headlineMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
