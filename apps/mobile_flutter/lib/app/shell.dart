import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme/colors.dart';

/// The bottom-navigation shell hosting the six primary tabs:
/// Pulse · Gameday · Stats · Pipeline · Vault · Profile.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<_NavDest> _destinations = <_NavDest>[
    _NavDest('Pulse', Icons.bolt_outlined, Icons.bolt_rounded),
    _NavDest('Gameday', Icons.stadium_outlined, Icons.stadium_rounded),
    _NavDest('Stats', Icons.insights_outlined, Icons.insights_rounded),
    _NavDest('Pipeline', Icons.account_tree_outlined, Icons.account_tree_rounded),
    _NavDest('Vault', Icons.lock_open_outlined, Icons.lock_open_rounded),
    _NavDest('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: BgColors.hairline)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          destinations: <Widget>[
            for (final _NavDest d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavDest {
  const _NavDest(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
