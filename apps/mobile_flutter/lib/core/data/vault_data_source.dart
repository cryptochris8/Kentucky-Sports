import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/models.dart';

/// Loads the two Vault assets from the bundle.
///
/// Separate from [SeedLoader] / [MockDataSource] because the Vault assets are
/// self-contained JSON files, not part of the dev_seed collection envelope.
/// A tiny simulated latency keeps loading states visible during dev.
class VaultDataSource {
  VaultDataSource({this.latency = const Duration(milliseconds: 200)});

  final Duration latency;

  static const String _seasonsPath = 'assets/vault/vault_seasons.json';
  static const String _legendsPath = 'assets/vault/vault_legends.json';

  Map<String, dynamic>? _seasonsCache;
  Map<String, dynamic>? _legendsCache;

  Future<Map<String, dynamic>> _loadJson(String path) async {
    final String raw = await rootBundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<VaultSeason>> seasons() async {
    _seasonsCache ??= await _loadJson(_seasonsPath);
    await Future<void>.delayed(latency);
    final dynamic list = _seasonsCache!['vault_seasons'];
    if (list is! List) return const <VaultSeason>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(VaultSeason.fromJson)
        .toList();
  }

  Future<List<VaultLegend>> legends() async {
    _legendsCache ??= await _loadJson(_legendsPath);
    await Future<void>.delayed(latency);
    final dynamic list = _legendsCache!['vault_legends'];
    if (list is! List) return const <VaultLegend>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(VaultLegend.fromJson)
        .toList();
  }
}
