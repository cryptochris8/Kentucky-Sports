import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final Color muted = scheme.onSurfaceVariant;
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
                color: scheme.primary,
                dense: true,
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  Icon(
                    locked ? Icons.lock_rounded : Icons.schedule_rounded,
                    size: 13,
                    color: muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locked ? 'Closed' : Fmt.closesIn(prediction.closesAt),
                    style: text.labelSmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(prediction.question, style: text.titleLarge),
          const SizedBox(height: 8),
          // Thin gold rule — the broadcast "banner" cue under the prompt.
          const GoldRule(width: 44),
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

/// A pick option button. Theme-aware (legible in light + dark) with a quick
/// springy press cue on the active selection — the broadcast skin's punchy
/// feedback. Reduce-motion aware.
class _OptionButton extends StatefulWidget {
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
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool selected = widget.selected;
    final Color border = selected ? scheme.primary : scheme.outline;
    final Color fill = selected
        ? scheme.primary.withValues(alpha: 0.10)
        : scheme.surface;
    final Color labelColor =
        widget.locked ? scheme.onSurfaceVariant : scheme.onSurface;

    final Widget button = Material(
      color: fill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: widget.onTap == null ? null : (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
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
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: labelColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (reduceMotion || widget.onTap == null) return button;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutBack,
      child: button,
    );
  }

  void _set(bool value) {
    if (widget.onTap == null) return;
    if (_pressed != value) setState(() => _pressed = value);
  }
}
