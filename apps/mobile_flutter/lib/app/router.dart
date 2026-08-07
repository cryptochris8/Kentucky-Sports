import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/local_state.dart';
import '../features/badges/badges_screen.dart';
import '../features/gameday/gameday_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/pipeline/pipeline_screen.dart';
import '../features/players/player_profile_screen.dart';
import '../features/predictions/predictions_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/teams/team_page_screen.dart';
import '../features/vault/vault_legend_screen.dart';
import '../features/vault/vault_screen.dart';
import '../features/vault/vault_season_detail_screen.dart';
import 'shell.dart';

/// Route path constants to avoid stringly-typed navigation.
abstract final class Routes {
  static const String onboarding = '/onboarding';

  // 5-tab content hub (Pass 2 IA): Home · Gameday · Vault · Preps · Profile.
  static const String home = '/home';
  static const String gameday = '/gameday';
  static const String vault = '/vault';
  static const String preps = '/preps';
  static const String profile = '/profile';

  // Pushed / full-screen routes (above the shell).
  static const String badges = '/profile/badges';
  static const String predictions = '/predictions';
  static const String settings = '/settings';

  static String team(String teamId) => '/team/$teamId';
  static String player(String playerId) => '/player/$playerId';
  static String vaultLegend(String legendId) => '/vault/legend/$legendId';
  static String vaultSeason(String seasonId) => '/vault/season/$seasonId';
}

/// Builds the app [GoRouter]. Uses a [StatefulShellRoute] for the bottom nav so
/// each tab keeps its own navigation state.
GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: Routes.home,
    redirect: (BuildContext context, GoRouterState state) {
      final bool onboarded = ref.read(onboardingCompleteProvider);
      final bool atOnboarding = state.matchedLocation == Routes.onboarding;
      if (!onboarded && !atOnboarding) return Routes.onboarding;
      if (onboarded && atOnboarding) return Routes.home;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.onboarding,
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingScreen(),
      ),
      // Full-screen detail routes (pushed above the shell).
      GoRoute(
        path: '/vault/legend/:legendId',
        builder: (BuildContext context, GoRouterState state) =>
            VaultLegendScreen(legendId: state.pathParameters['legendId']!),
      ),
      GoRoute(
        path: '/vault/season/:seasonId',
        builder: (BuildContext context, GoRouterState state) =>
            VaultSeasonDetailScreen(
                seasonId: state.pathParameters['seasonId']!),
      ),
      GoRoute(
        path: '/team/:teamId',
        builder: (BuildContext context, GoRouterState state) =>
            TeamPageScreen(teamId: state.pathParameters['teamId']!),
      ),
      GoRoute(
        path: '/player/:playerId',
        builder: (BuildContext context, GoRouterState state) =>
            PlayerProfileScreen(playerId: state.pathParameters['playerId']!),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.badges,
        builder: (BuildContext context, GoRouterState state) =>
            const BadgesScreen(),
      ),
      // Predictions is a pushed route, surfaced from Home + Gameday.
      GoRoute(
        path: Routes.predictions,
        builder: (BuildContext context, GoRouterState state) =>
            const PredictionsScreen(),
      ),
      // Bottom-nav shell (5 branches).
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          // 0 · Home — the Bento content hub.
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.home,
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          // 1 · Gameday — matchup + Stats + Predictions (Stats folded in here).
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.gameday,
                builder: (BuildContext context, GoRouterState state) =>
                    const GamedayScreen(),
              ),
            ],
          ),
          // 2 · Vault — Kentucky history.
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.vault,
                builder: (BuildContext context, GoRouterState state) =>
                    const VaultScreen(),
              ),
            ],
          ),
          // 3 · Preps — Kentucky high school (the former Pipeline feature).
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.preps,
                builder: (BuildContext context, GoRouterState state) =>
                    const PipelineScreen(),
              ),
            ],
          ),
          // 4 · Profile.
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.profile,
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
