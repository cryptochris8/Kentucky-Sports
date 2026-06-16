import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/glass_nav_bar.dart';

/// The bottom-navigation shell hosting the six primary tabs:
/// Pulse · Gameday · Stats · Pipeline · Vault · Profile.
///
/// Renders the reusable [GlassNavBar] (Pass 1) over the branch content. The tab
/// list itself is unchanged this pass.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<GlassNavDestination> _destinations =
      <GlassNavDestination>[
    GlassNavDestination(
      label: 'Pulse',
      icon: Icons.bolt_outlined,
      selectedIcon: Icons.bolt_rounded,
    ),
    GlassNavDestination(
      label: 'Gameday',
      icon: Icons.stadium_outlined,
      selectedIcon: Icons.stadium_rounded,
    ),
    GlassNavDestination(
      label: 'Stats',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
    ),
    GlassNavDestination(
      label: 'Pipeline',
      icon: Icons.account_tree_outlined,
      selectedIcon: Icons.account_tree_rounded,
    ),
    GlassNavDestination(
      label: 'Vault',
      icon: Icons.lock_open_outlined,
      selectedIcon: Icons.lock_open_rounded,
    ),
    GlassNavDestination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The floating glass bar is placed as the bottomNavigationBar so the
    // Scaffold reserves its full height (margin included) — existing screens
    // keep their safe bottom inset and nothing scrolls under the chrome.
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: GlassNavBar(
        destinations: _destinations,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
      ),
    );
  }
}
