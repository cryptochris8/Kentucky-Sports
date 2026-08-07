import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only UI state (no backend). Most of it is in-memory; the onboarding
/// flag is additionally persisted via [SharedPreferences] so first-run setup
/// is not forced on every launch.
///
/// Picks made in the Prediction Center are stored here optimistically. They are
/// intentionally local-only for Phase 1 — that's fine per the build spec.

/// The [SharedPreferences] instance loaded in `main()` before `runApp`.
///
/// Overridden with a real instance at startup; the null default keeps tests
/// and headless usage fully in-memory with zero platform channels.
final sharedPreferencesProvider =
    Provider<SharedPreferences?>((Ref ref) => null);

/// Maps `predictionId -> selectedOptionId` for the current session.
class LocalPicksNotifier extends StateNotifier<Map<String, String>> {
  LocalPicksNotifier() : super(const <String, String>{});

  /// Records (or replaces) the user's pick for a prediction.
  void pick(String predictionId, String optionId) {
    state = <String, String>{...state, predictionId: optionId};
  }

  /// Clears a pick (e.g. to change one before close).
  void clear(String predictionId) {
    final Map<String, String> next = <String, String>{...state}
      ..remove(predictionId);
    state = next;
  }

  String? selectionFor(String predictionId) => state[predictionId];
}

final localPicksProvider =
    StateNotifierProvider<LocalPicksNotifier, Map<String, String>>(
        (Ref ref) => LocalPicksNotifier());

/// Local XP earned this session from making picks (optimistic, additive to the
/// seed user's base XP for display only).
class SessionXpNotifier extends StateNotifier<int> {
  SessionXpNotifier() : super(0);

  void add(int amount) => state = state + amount;
}

final sessionXpProvider =
    StateNotifierProvider<SessionXpNotifier, int>((Ref ref) => SessionXpNotifier());

/// Local notification preferences (Settings screen toggles).
class NotificationPrefs {
  const NotificationPrefs({
    this.morningPulse = true,
    this.gameStartingSoon = true,
    this.predictionClosing = true,
    this.finalScore = true,
    this.badgeEarned = true,
    this.highSchoolAlerts = false,
  });

  final bool morningPulse;
  final bool gameStartingSoon;
  final bool predictionClosing;
  final bool finalScore;
  final bool badgeEarned;
  final bool highSchoolAlerts;

  NotificationPrefs copyWith({
    bool? morningPulse,
    bool? gameStartingSoon,
    bool? predictionClosing,
    bool? finalScore,
    bool? badgeEarned,
    bool? highSchoolAlerts,
  }) {
    return NotificationPrefs(
      morningPulse: morningPulse ?? this.morningPulse,
      gameStartingSoon: gameStartingSoon ?? this.gameStartingSoon,
      predictionClosing: predictionClosing ?? this.predictionClosing,
      finalScore: finalScore ?? this.finalScore,
      badgeEarned: badgeEarned ?? this.badgeEarned,
      highSchoolAlerts: highSchoolAlerts ?? this.highSchoolAlerts,
    );
  }
}

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  NotificationPrefsNotifier() : super(const NotificationPrefs());

  void setMorningPulse(bool v) => state = state.copyWith(morningPulse: v);
  void setGameStartingSoon(bool v) =>
      state = state.copyWith(gameStartingSoon: v);
  void setPredictionClosing(bool v) =>
      state = state.copyWith(predictionClosing: v);
  void setFinalScore(bool v) => state = state.copyWith(finalScore: v);
  void setBadgeEarned(bool v) => state = state.copyWith(badgeEarned: v);
  void setHighSchoolAlerts(bool v) =>
      state = state.copyWith(highSchoolAlerts: v);
}

final notificationPrefsProvider =
    StateNotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
        (Ref ref) => NotificationPrefsNotifier());

/// Whether onboarding has been completed. Persisted via [SharedPreferences]
/// (when available) so the welcome flow only ever runs once per install;
/// falls back to in-memory when no prefs instance was provided (tests).
class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier(this._prefs) : super(_prefs?.getBool(_key) ?? false);

  static const String _key = 'onboardingComplete';

  final SharedPreferences? _prefs;

  void complete() {
    state = true;
    _prefs?.setBool(_key, true);
  }
}

final onboardingCompleteProvider =
    StateNotifierProvider<OnboardingNotifier, bool>(
        (Ref ref) => OnboardingNotifier(ref.watch(sharedPreferencesProvider)));

/// Local follow/unfollow overrides for high schools (Preps), keyed by school
/// id. Layered over the seed user's `favoriteHighSchools` so follow state
/// survives rebuilds and stays reachable from the Riverpod graph. Persisting
/// to the user document is a Phase 2 concern.
class FollowedSchoolsNotifier extends StateNotifier<Map<String, bool>> {
  FollowedSchoolsNotifier() : super(const <String, bool>{});

  void setFollowing(String schoolId, bool following) {
    state = <String, bool>{...state, schoolId: following};
  }
}

final followedSchoolsProvider =
    StateNotifierProvider<FollowedSchoolsNotifier, Map<String, bool>>(
        (Ref ref) => FollowedSchoolsNotifier());

/// Favorite sports chosen during onboarding (in-memory).
class FavoriteSportsNotifier extends StateNotifier<Set<String>> {
  FavoriteSportsNotifier()
      : super(const <String>{'football', 'mens_basketball'});

  void toggle(String sport) {
    final Set<String> next = <String>{...state};
    if (next.contains(sport)) {
      next.remove(sport);
    } else {
      next.add(sport);
    }
    state = next;
  }
}

final favoriteSportsProvider =
    StateNotifierProvider<FavoriteSportsNotifier, Set<String>>(
        (Ref ref) => FavoriteSportsNotifier());
