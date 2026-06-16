import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// One segment of a [SegmentedToggle].
class SegmentItem {
  const SegmentItem({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

/// A reusable pill-style segmented control (Pass 1 design language).
///
/// A rounded track on the theme's surface-alt with a springy, soft-blue active
/// pill that slides between segments. Used for the Gameday sub-tabs and the
/// Stats Lab sport toggle. Reduce-motion aware and AA-legible in light + dark.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.segments,
    required this.index,
    required this.onChanged,
  });

  final List<SegmentItem> segments;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final Color track = scheme.surfaceContainerHighest;
    final Color pill = dark
        ? scheme.primary.withValues(alpha: 0.22)
        : scheme.surface;
    final Color selectedFg = scheme.primary;
    final Color unselectedFg = scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(BgTheme.radiusChip),
        border: Border.all(color: scheme.outline),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double segW = constraints.maxWidth / segments.length;
          return Stack(
            children: <Widget>[
              // Sliding active pill.
              AnimatedAlign(
                duration: reduceMotion ? Duration.zero : BgTheme.motionStandard,
                curve: BgTheme.curveEmphasized,
                alignment: Alignment(
                  segments.length == 1
                      ? 0
                      : -1 + (2 * index / (segments.length - 1)),
                  0,
                ),
                child: Container(
                  width: segW,
                  height: 38,
                  decoration: BoxDecoration(
                    color: pill,
                    borderRadius: BorderRadius.circular(BgTheme.radiusChip),
                    boxShadow: BgTheme.e1(dark: dark),
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (int i = 0; i < segments.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == index,
                        label: segments[i].label,
                        child: InkWell(
                          onTap: () => onChanged(i),
                          borderRadius:
                              BorderRadius.circular(BgTheme.radiusChip),
                          child: SizedBox(
                            height: 38,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                if (segments[i].icon != null) ...<Widget>[
                                  Icon(
                                    segments[i].icon,
                                    size: 16,
                                    color: i == index
                                        ? selectedFg
                                        : unselectedFg,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    segments[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: i == index
                                          ? selectedFg
                                          : unselectedFg,
                                      fontWeight: i == index
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
