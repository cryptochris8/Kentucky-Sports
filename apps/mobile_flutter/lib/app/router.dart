import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/local_state.dart';
import '../features/badges/badges_screen.dart';
import '../features/gameday/gameday_screen.dart';
import '../features/home/pulse_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/pipeline/pipeline_screen.dart';
import '../features/players/player_profile_screen.dart';
import '../features/predictions/predictions_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stats_lab/stats_lab_screen.dart';
import '../features/teams/team_page_screen.dart';
import 'shell.dart';

/// Route path constants to avoid stringly-typed navigation.
abstract final class Routes {
  static const String onboarding = '/onboarding';
  static const String pulse = '/pulse';
  static const String gameday = '/gameday';
  static const String stats = '/stats';
  static const String pipeline = '/pipeline';
  static const String profile = '/profile';
  static const String badges = '/profile/badges';
  static const String predictions = '/predictions';
  static const String settings = '/settings';

  static String team(String teamId) => '/team/$teamId';
  static String player(String playerId) => '/player/$playerId';
}

/// Builds the app [GoRouter]. Uses a [StatefulShellRoute] for the bottom nav so
/// each tab keeps its own navigation state.
GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: Routes.pulse,
    redirect: (BuildContext context, GoRouterState state) {
      final bool onboarded = ref.read(onboardingCompleteProvider);
      final bool atOnboarding = state.matchedLocation == Routes.onboarding;
      if (!onboarded && !atOnboarding) return Routes.onboarding;
      if (onboarded && atOnboarding) return Routes.pulse;
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
      GoRoute(
        path: Routes.predictions,
        builder: (BuildContext context, GoRouterState state) =>
            const PredictionsScreen(),
      ),
      // Bottom-nav shell.
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.pulse,
                builder: (BuildContext context, GoRouterState state) =>
                    const PulseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.gameday,
                builder: (BuildContext context, GoRouterState state) =>
                    const GamedayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.stats,
                builder: (BuildContext context, GoRouterState state) =>
                    const StatsLabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.pipeline,
                builder: (BuildContext context, GoRouterState state) =>
                    const PipelineScreen(),
              ),
            ],
          ),
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
