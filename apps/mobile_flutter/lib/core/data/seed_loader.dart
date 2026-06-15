// -----------------------------------------------------------------------------
// BUILD-TIME COPY NOTICE
//
// This loader reads `assets/seed/dev_seed.json`, which is a build-time copy of
// the CANONICAL seed at the repo root: `seed_data/dev_seed.json`.
//
// All stat values in that file are FICTIONAL demo data (source: "seed_demo").
// If the canonical seed changes, re-copy it into assets and re-register it in
// pubspec.yaml. Do NOT hand-edit the asset copy — edit the canonical file.
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../config.dart';

/// Loads and caches the bundled seed JSON as a decoded map.
class SeedLoader {
  SeedLoader._();
  static final SeedLoader instance = SeedLoader._();

  Map<String, dynamic>? _cache;

  /// Returns the decoded seed JSON, loading + caching on first call.
  Future<Map<String, dynamic>> load() async {
    final Map<String, dynamic>? cached = _cache;
    if (cached != null) return cached;
    final String raw = await rootBundle.loadString(AppConfig.seedAssetPath);
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    _cache = decoded;
    return decoded;
  }

  /// Returns a top-level collection array as a list of maps.
  Future<List<Map<String, dynamic>>> collection(String key) async {
    final Map<String, dynamic> seed = await load();
    final dynamic raw = seed[key];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }
}
