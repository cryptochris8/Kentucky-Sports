import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config.dart';
import 'router.dart';
import 'theme/theme.dart';

/// Holds the app's [GoRouter], built once with access to providers.
final routerProvider = Provider<GoRouter>((Ref ref) => buildRouter(ref));

/// Root widget for Bluegrass Gameday.
class BluegrassGamedayApp extends ConsumerWidget {
  const BluegrassGamedayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: BgTheme.light(),
      darkTheme: BgTheme.dark(),
      themeMode: BgTheme.themeMode,
      routerConfig: router,
    );
  }
}
