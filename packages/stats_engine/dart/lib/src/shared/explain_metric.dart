/// `explainMetric()` — controlled, template-based stat explanations.
///
/// Per docs/06, explanations use a controlled template (not open-ended AI).
library;

import 'metric_labels.dart';

/// Returns the "What this means" explanation for a metric [key].
///
/// [sport] selects the correct label map. Always returns a non-empty string.
String explainMetric(String key, {String sport = 'football'}) {
  return labelFor(key, sport: sport).explanation;
}

/// Returns the fan-friendly short broadcast label for a metric [key].
String fanLabel(String key, {String sport = 'football'}) {
  return labelFor(key, sport: sport).shortLabel;
}

/// Returns the full display name for a metric [key].
String displayName(String key, {String sport = 'football'}) {
  return labelFor(key, sport: sport).displayName;
}

/// Builds a one-paragraph "stat story" comparing Kentucky vs an opponent for
/// a single metric, using the controlled template from docs/06.
///
/// The verdict is honest: an edge is only claimed for the side the values
/// actually favor (honoring [MetricLabel.higherIsBetter]); equal values read
/// as even.
///
/// PARITY: the verdict phrasing is mirrored word-for-word in the TypeScript
/// twin's explainMetric (packages/stats_engine/typescript/src/explainMetric.ts).
/// Change one side only in lockstep with the other.
///
/// Example output:
///   "Duke has the edge in Shot Quality. The Cats post 55.2% while Duke sits
///    at 56.1%. In plain English: ..."
String buildStatStory({
  required String key,
  required double kentuckyValue,
  required double opponentValue,
  required String opponentName,
  String sport = 'football',
}) {
  final MetricLabel meta = labelFor(key, sport: sport);
  final String ky = formatMetricValue(key, kentuckyValue, sport: sport);
  final String opp = formatMetricValue(key, opponentValue, sport: sport);
  final bool tie = kentuckyValue == opponentValue;
  final bool kyAhead = meta.higherIsBetter
      ? kentuckyValue > opponentValue
      : kentuckyValue < opponentValue;
  final String verdict = tie
      ? 'Kentucky and $opponentName are even in ${meta.shortLabel}.'
      : kyAhead
          ? 'Kentucky holds the edge in ${meta.shortLabel}.'
          : '$opponentName has the edge in ${meta.shortLabel}.';
  return '$verdict The Cats post $ky while $opponentName sits at $opp. '
      'In plain English: ${meta.explanation}';
}

/// Formats a raw metric [value] for display, honoring percent metrics.
String formatMetricValue(String key, double value, {String sport = 'football'}) {
  final MetricLabel meta = labelFor(key, sport: sport);
  if (meta.isPercent) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
  // Whole numbers render without decimals; otherwise one decimal place.
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
