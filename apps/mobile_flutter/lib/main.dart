// Bluegrass Gameday — an independent Kentucky sports fan & statistics app.
// NOT affiliated with, endorsed by, or sponsored by the University of Kentucky.
//
// Phase 1 runs with ZERO backend: data is loaded from the bundled seed JSON
// (assets/seed/dev_seed.json) via MockDataSource. Firebase is intentionally
// NOT initialized here and Firestore is gated behind AppConfig.useFirestore.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  // No Firebase.initializeApp — Phase 1 is seed-only by design.
  runApp(const ProviderScope(child: BluegrassGamedayApp()));
}
