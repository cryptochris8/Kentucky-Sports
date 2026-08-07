// Bluegrass Gameday — an independent Kentucky sports fan & statistics app.
// NOT affiliated with, endorsed by, or sponsored by the University of Kentucky.
//
// Phase 1 runs with ZERO backend: data is loaded from the bundled seed JSON
// (assets/seed/dev_seed.json) via MockDataSource. Firebase is intentionally
// NOT initialized here and Firestore is gated behind AppConfig.useFirestore.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/providers/local_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Local prefs (onboarding flag). No Firebase.initializeApp — Phase 1 is
  // seed-only by design.
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BluegrassGamedayApp(),
    ),
  );
}
