import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';

/// A single destination for [GlassNavBar].
class GlassNavDestination {
  const GlassNavDestination({
    required this.label,
    required this.icon,
    IconData? selectedIcon,
  }) : selectedIcon = selectedIcon ?? icon;

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// A reusable floating, frosted bottom navigation bar.
///
/// Design (Pass 1): a single [BackdropFilter] blur over a translucent surface
/// (~80%), a 28px rounded shell, a hairline top border, a soft [BgTheme.e2]
/// shadow, and a springy soft-blue pill behind the selected item. It is a
/// drop-in for any number of [destinations]; the navigation pass can wire it to
/// real routes.
///
/// Performance: the [BackdropFilter] is confined to this chrome only — never
/// place this inside a scrolling list. Blur is dropped when reduce-motion /
/// disable-animations is requested.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  });

  final List<GlassNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final BorderRadius radius = BorderRadius.circular(BgTheme.radiusHero);
    // Translucent surface (~80%) so the blur reads through it.
    final Color shell = scheme.surface.withValues(alpha: 0.80);

    final Widget bar = DecoratedBox(
      decoration: BoxDecoration(
        color: shell,
        borderRadius: radius,
        border: Border.all(color: scheme.outline),
        boxShadow: BgTheme.e2(dark: dark),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            for (int i = 0; i < destinations.length; i++)
              Expanded(
                child: _GlassNavItem(
                  destination: destinations[i],
                  selected: i == selectedIndex,
                  reduceMotion: reduceMotion,
                  onTap: () => onDestinationSelected(i),
                ),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: reduceMotion
            ? bar
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: bar,
              ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.destination,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool dark = theme.brightness == Brightness.dark;

    final Color selectedFg = scheme.primary;
    final Color unselectedFg = scheme.onSurfaceVariant;
    // Soft-blue pill behind the active item.
    final Color pill = dark
        ? scheme.primary.withValues(alpha: 0.22)
        : BgColors.surfaceAlt;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BgTheme.radiusChip),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: reduceMotion ? Duration.zero : BgTheme.motionStandard,
                curve: BgTheme.curveEmphasized,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected ? pill : Colors.transparent,
                  borderRadius: BorderRadius.circular(BgTheme.radiusChip),
                ),
                child: AnimatedScale(
                  scale: selected && !reduceMotion ? 1.06 : 1.0,
                  duration: BgTheme.motionStandard,
                  curve: BgTheme.curveEmphasized,
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 24,
                    color: selected ? selectedFg : unselectedFg,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? selectedFg : unselectedFg,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
