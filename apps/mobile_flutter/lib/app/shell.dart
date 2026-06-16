import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/glass_nav_bar.dart';

/// The bottom-navigation shell hosting the five primary tabs (Pass 2 IA):
/// Home · Gameday · Vault · Preps · Profile.
///
/// Stats Lab is no longer a top-level tab — its content now lives inside the
/// Gameday hub (Breakdown · Stats · Predictions). Predictions is reachable from
/// Home and Gameday rather than from the bar. Renders the reusable [GlassNavBar]
/// (Pass 1) over the active branch.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<GlassNavDestination> _destinations =
      <GlassNavDestination>[
    GlassNavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    GlassNavDestination(
      label: 'Gameday',
      icon: Icons.stadium_outlined,
      selectedIcon: Icons.stadium_rounded,
    ),
    GlassNavDestination(
      label: 'Vault',
      icon: Icons.lock_open_outlined,
      selectedIcon: Icons.lock_open_rounded,
    ),
    GlassNavDestination(
      label: 'Preps',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school_rounded,
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
