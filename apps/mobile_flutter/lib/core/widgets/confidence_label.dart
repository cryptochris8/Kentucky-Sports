import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../utils/format.dart';

/// A compact attribution row showing `source`, `updatedAt`, and `confidence`.
///
/// REQUIRED on every stat card (hard rule). Renders a small, low-emphasis strip
/// so users always know where a number came from and how trustworthy it is.
class SourceConfidenceRow extends StatelessWidget {
  const SourceConfidenceRow({
    super.key,
    required this.source,
    required this.updatedAt,
    required this.confidence,
  });

  final String source;
  final DateTime? updatedAt;
  final String confidence;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 10.5,
        color: BgColors.mist,
        fontWeight: FontWeight.w600,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          _chip(Icons.source_rounded, 'Source: $source'),
          if (updatedAt != null)
            _chip(Icons.update_rounded, 'Updated ${Fmt.shortDay(updatedAt)}'),
          ConfidenceLabel(confidence: confidence),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 12, color: BgColors.mist),
        const SizedBox(width: 3),
        Text(text),
      ],
    );
  }
}

/// A pill conveying the confidence level of a stat (demo/estimated/verified).
class ConfidenceLabel extends StatelessWidget {
  const ConfidenceLabel({super.key, required this.confidence});

  final String confidence;

  ({Color color, IconData icon, String label}) get _style {
    switch (confidence.toLowerCase()) {
      case 'verified':
      case 'official':
        return (
          color: BgColors.positive,
          icon: Icons.verified_rounded,
          label: 'Verified'
        );
      case 'estimated':
      case 'reported_by_media':
        return (
          color: BgColors.warning,
          icon: Icons.timeline_rounded,
          label: 'Estimated'
        );
      case 'fan_rumor':
        return (
          color: BgColors.negative,
          icon: Icons.forum_rounded,
          label: 'Fan-reported'
        );
      case 'demo':
      default:
        return (
          color: BgColors.blueBright,
          icon: Icons.science_rounded,
          label: 'Demo data'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ({Color color, IconData icon, String label}) s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(s.icon, size: 11, color: s.color),
          const SizedBox(width: 3),
          Text(
            s.label,
            style: TextStyle(
              color: s.color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
