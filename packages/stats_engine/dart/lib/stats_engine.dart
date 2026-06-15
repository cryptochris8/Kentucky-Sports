/// Bluegrass Gameday stat engine (Dart).
///
/// Fan-friendly stat labels, plain-English explanations, basketball Four
/// Factors, football basic/advanced helpers, percentile ranking, and XP/level
/// math. The TypeScript twin of this package runs in Cloud Functions; this
/// Dart build powers the Flutter app's rendering and the Stats Lab.
///
/// See docs/06 (Stats Engine Design) and docs/07 (Gamification).
library;

export 'src/shared/metric_labels.dart';
export 'src/shared/explain_metric.dart';
export 'src/shared/percentile_rank.dart';
export 'src/shared/level_calc.dart';
export 'src/basketball/four_factors.dart';
export 'src/football/football_metrics.dart';
