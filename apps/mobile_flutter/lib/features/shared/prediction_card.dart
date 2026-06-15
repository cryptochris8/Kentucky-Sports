import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/local_state.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';

/// An interactive prediction card. Tapping an option records an optimistic
/// local pick (no backend) and awards session XP. Free-to-play language only.
class PredictionCard extends ConsumerWidget {
  const PredictionCard({super.key, required this.prediction, this.compact = false});

  final Prediction prediction;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final Map<String, String> picks = ref.watch(localPicksProvider);
    final String? selected = picks[prediction.id];
    final bool locked = !prediction.isOpen;

    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Pill(
                label: '+${prediction.points} XP',
                color: BgColors.goldDark,
                background: BgColors.bluegrassGold.withValues(alpha: 0.18),
                icon: Icons.bolt_rounded,
                dense: true,
              ),
              const SizedBox(width: 8),
              Pill(
                label: Fmt.sportLabel(prediction.sport),
                color: BgColors.deepBlue,
                dense: true,
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  Icon(
                    locked ? Icons.lock_rounded : Icons.schedule_rounded,
                    size: 13,
                    color: locked ? BgColors.mist : BgColors.slate,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locked ? 'Closed' : Fmt.closesIn(prediction.closesAt),
                    style: text.labelSmall?.copyWith(
                      color: locked ? BgColors.mist : BgColors.slate,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(prediction.question, style: text.titleLarge),
          const SizedBox(height: 14),
          ...prediction.options.map((PredictionOption opt) {
            final bool isSelected = selected == opt.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionButton(
                label: opt.label,
                selected: isSelected,
                locked: locked,
                onTap: locked
                    ? null
                    : () => _pick(ref, context, opt.id, isSelected),
              ),
            );
          }),
          if (selected != null && !locked)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.check_circle_rounded,
                      size: 15, color: BgColors.positive),
                  const SizedBox(width: 6),
                  Text(
                    'Pick locked in locally — earn it back on gameday!',
                    style: text.bodySmall?.copyWith(color: BgColors.positive),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _pick(WidgetRef ref, BuildContext context, String optionId, bool already) {
    if (already) return;
    final bool firstPick =
        ref.read(localPicksProvider)[prediction.id] == null;
    ref.read(localPicksProvider.notifier).pick(prediction.id, optionId);
    if (firstPick) {
      ref.read(sessionXpProvider.notifier).add(prediction.points);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Pick saved · +${prediction.points} XP'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = selected ? BgColors.deepBlue : BgColors.hairline;
    final Color fill =
        selected ? BgColors.deepBlue.withValues(alpha: 0.08) : BgColors.surface;
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: selected ? 1.8 : 1.2),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? BgColors.deepBlue : BgColors.mist,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: locked ? BgColors.slate : BgColors.ink,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact "prediction prompt" used on Pulse to nudge a daily pick.
class PredictionPrompt extends StatelessWidget {
  const PredictionPrompt({
    super.key,
    required this.prediction,
    required this.onTap,
  });

  final Prediction prediction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return BgCard(
      gradient: const LinearGradient(
        colors: <Color>[BgColors.blueMid, BgColors.deepBlue],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.task_alt_rounded, color: BgColors.goldBright),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'TODAY\'S PICK · +${prediction.points} XP',
                  style: BgTypography.eyebrow(BgColors.goldBright),
                ),
                const SizedBox(height: 2),
                Text(
                  prediction.question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    );
  }
}
