import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vault_data_source.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// Data source (singleton per provider container)
// ---------------------------------------------------------------------------

final _vaultDataSourceProvider = Provider<VaultDataSource>((Ref ref) {
  return VaultDataSource();
});

// ---------------------------------------------------------------------------
// Raw collection providers
// ---------------------------------------------------------------------------

/// All vault seasons (both sports), as loaded from vault_seasons.json.
final vaultSeasonsProvider = FutureProvider<List<VaultSeason>>((Ref ref) {
  return ref.watch(_vaultDataSourceProvider).seasons();
});

/// All vault legend features, as loaded from vault_legends.json.
final vaultLegendsProvider = FutureProvider<List<VaultLegend>>((Ref ref) {
  return ref.watch(_vaultDataSourceProvider).legends();
});

// ---------------------------------------------------------------------------
// Derived / filtered providers
// ---------------------------------------------------------------------------

/// Vault seasons filtered to a given sport ("football" | "mens_basketball"),
/// sorted newest-first.
final vaultSeasonsBySportProvider =
    FutureProvider.family<List<VaultSeason>, String>(
        (Ref ref, String sport) async {
  final List<VaultSeason> all = await ref.watch(vaultSeasonsProvider.future);
  return all
      .where((VaultSeason s) => s.sport == sport)
      .toList()
    ..sort((VaultSeason a, VaultSeason b) => b.season.compareTo(a.season));
});

/// All football seasons newest-first.
final footballSeasonsProvider = FutureProvider<List<VaultSeason>>((Ref ref) {
  return ref.watch(vaultSeasonsBySportProvider('football').future);
});

/// All men's basketball seasons newest-first.
final basketballSeasonsProvider = FutureProvider<List<VaultSeason>>((Ref ref) {
  return ref.watch(vaultSeasonsBySportProvider('mens_basketball').future);
});

/// A single vault legend by id, or null if not found.
final vaultLegendByIdProvider =
    FutureProvider.family<VaultLegend?, String>((Ref ref, String id) async {
  final List<VaultLegend> all = await ref.watch(vaultLegendsProvider.future);
  for (final VaultLegend l in all) {
    if (l.id == id) return l;
  }
  return null;
});
