import 'package:flutter/material.dart';
import 'package:stats_engine/stats_engine.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import 'bg_card.dart';
import 'confidence_label.dart';
import 'percentile_bar.dart';
import 'trend_arrow.dart';

/// The signature stat card for Bluegrass Gameday.
///
/// Shows a fan-friendly label, the value, an optional percentile bar, a
/// "What this means" explainer, an optional trend arrow, and ALWAYS the
/// source / updatedAt / confidence attribution (hard rule).
class StatCard extends StatefulWidget {
  const StatCard({
    super.key,
    required this.fanLabel,
    required this.displayName,
    required this.valueText,
    required this.explanation,
    required this.source,
    required this.updatedAt,
    required this.confidence,
    this.percentile,
    this.rankText,
    this.trend,
    this.trendGoodWhenUp = true,
    this.accent = BgColors.primary,
  });

  /// Broadcast-style short label, e.g. "Shot Quality".
  final String fanLabel;

  /// Full metric name, e.g. "Effective FG%".
  final String displayName;

  /// Pre-formatted value string, e.g. "55.2%".
  final String valueText;

  /// Plain-English "What this means" copy.
  final String explanation;

  final String source;
  final DateTime? updatedAt;
  final String confidence;

  /// Optional 0..100 national percentile.
  final int? percentile;

  /// Optional rank string, e.g. "3rd in SEC".
  final String? rankText;

  final TrendDirection? trend;
  final bool trendGoodWhenUp;
  final Color accent;

  /// Convenience constructor that pulls label + explanation from stats_engine.
  factory StatCard.fromMetric({
    Key? key,
    required String metricKey,
    required double value,
    required String source,
    required DateTime? updatedAt,
    required String confidence,
    String sport = 'football',
    int? percentile,
    String? rankText,
    TrendDirection? trend,
    Color accent = BgColors.primary,
  }) {
    final MetricLabel meta = labelFor(metricKey, sport: sport);
    return StatCard(
      key: key,
      fanLabel: meta.shortLabel,
      displayName: meta.displayName,
      valueText: formatMetricValue(metricKey, value, sport: sport),
      explanation: meta.explanation,
      source: source,
      updatedAt: updatedAt,
      confidence: confidence,
      percentile: percentile,
      rankText: rankText,
      trend: trend,
      trendGoodWhenUp: meta.higherIsBetter,
      accent: accent,
    );
  }

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    return BgCard(
      accentRail: widget.accent,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.fanLabel.toUpperCase(),
                      style: BgTypography.eyebrow(widget.accent),
                    ),
                    const SizedBox(height: 2),
                    Text(widget.displayName, style: text.titleMedium),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    widget.valueText,
                    style: BgTypography.statNumber(widget.accent, size: 32),
                  ),
                  if (widget.trend != null)
                    TrendArrow(
                      direction: widget.trend!,
                      goodWhenUp: widget.trendGoodWhenUp,
                    ),
                ],
              ),
            ],
          ),
          if (widget.rankText != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              widget.rankText!,
              style: text.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (widget.percentile != null) ...<Widget>[
            const SizedBox(height: 12),
            PercentileBar(percentile: widget.percentile!),
          ],
          const SizedBox(height: 12),
          // "What this means" expandable explainer.
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 15,
                    color: BgColors.accentGold,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'What this means',
                    style: text.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(widget.explanation, style: text.bodyMedium),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
          const Divider(height: 20),
          // REQUIRED attribution: source / updatedAt / confidence.
          SourceConfidenceRow(
            source: widget.source,
            updatedAt: widget.updatedAt,
            confidence: widget.confidence,
          ),
        ],
      ),
    );
  }
}

/// Decides which side of a metric comparison earns the highlight.
///
/// STRICT comparison: exactly equal values are a tie and neither side wins —
/// the UI must never assert a Kentucky edge the data does not support
/// (mirrors the stat-story "even" verdict semantics in the stats engine).
({bool kentuckyWins, bool tie}) compareEdge({
  required double kentucky,
  required double opponent,
  required bool higherIsBetter,
}) {
  if (kentucky == opponent) return (kentuckyWins: false, tie: true);
  return (
    kentuckyWins: higherIsBetter ? kentucky > opponent : kentucky < opponent,
    tie: false,
  );
}

/// A compact comparison row: Kentucky value vs opponent value for one metric,
/// with the winning side highlighted. On a [tie] neither side highlights —
/// both values dim to the muted on-surface color and both dots stay neutral.
/// Used in Stats Lab + Gameday compare.
class CompareRow extends StatelessWidget {
  const CompareRow({
    super.key,
    required this.label,
    required this.kentuckyText,
    required this.opponentText,
    required this.kentuckyWins,
    this.tie = false,
    this.opponentName = 'OPP',
  });

  final String label;
  final String kentuckyText;
  final String opponentText;
  final bool kentuckyWins;

  /// True when the compared values are exactly equal — no side highlights.
  final bool tie;

  final String opponentName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    // Theme-aware so the compare numbers read in light AND dark: the winning
    // side uses the brand primary / gold accent, the trailing side dims to the
    // muted on-surface color (instead of literal navy that vanished in dark).
    // On a tie there is no winning side — both stay muted (no false edge).
    final bool opponentWins = !kentuckyWins && !tie;
    final Color kyColor =
        kentuckyWins ? scheme.primary : scheme.onSurfaceVariant;
    final Color oppColor =
        opponentWins ? scheme.tertiary : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              kentuckyText,
              textAlign: TextAlign.start,
              style: BgTypography.broadcast(kyColor, fontSize: 20),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: <Widget>[
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(letterSpacing: 0.3),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _dot(kentuckyWins, scheme.primary, scheme.outline),
                    const SizedBox(width: 10),
                    _dot(opponentWins, scheme.tertiary, scheme.outline),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              opponentText,
              textAlign: TextAlign.end,
              style: BgTypography.broadcast(oppColor, fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool active, Color color, Color inactive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : inactive,
      ),
    );
  }
}
