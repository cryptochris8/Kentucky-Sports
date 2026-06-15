import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';

/// A matchup hero card: Kentucky vs opponent with a deep-blue gradient,
/// venue/time, broadcast, and (for finals) the final score.
class MatchupHero extends StatelessWidget {
  const MatchupHero({
    super.key,
    required this.game,
    this.headline,
    this.onTap,
  });

  final Game game;
  final String? headline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isFinal = game.isFinal;

    return BgCard(
      gradient: BgColors.heroGradient,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Pill(
                label: Fmt.sportLabel(game.sport).toUpperCase(),
                color: Colors.white,
                background: Colors.white.withValues(alpha: 0.18),
                dense: true,
              ),
              const SizedBox(width: 8),
              if (game.rivalry != null)
                Pill(
                  label: game.rivalry!.toUpperCase(),
                  color: BgColors.goldBright,
                  background: BgColors.goldBright.withValues(alpha: 0.18),
                  icon: Icons.local_fire_department_rounded,
                  dense: true,
                ),
              const Spacer(),
              if (isFinal)
                Pill(
                  label: 'FINAL',
                  color: Colors.white,
                  background: Colors.white.withValues(alpha: 0.2),
                  dense: true,
                )
              else
                Pill(
                  label: game.broadcast,
                  color: Colors.white,
                  background: Colors.white.withValues(alpha: 0.14),
                  icon: Icons.live_tv_rounded,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _TeamColumn(
                  name: 'Kentucky',
                  short: 'UK',
                  score: isFinal ? game.kentuckyScore : null,
                  isWinner: isFinal && game.kentuckyWon,
                  accent: BgColors.goldBright,
                ),
              ),
              Column(
                children: <Widget>[
                  Text(
                    'VS',
                    style: BgTypography.statNumber(
                      Colors.white.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ),
                  if (game.isHome)
                    Text(
                      'HOME',
                      style: text.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: _TeamColumn(
                  name: game.opponentName,
                  short: game.opponentShort,
                  score: isFinal ? game.opponentScore : null,
                  isWinner: isFinal && !game.kentuckyWon,
                  accent: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.event_rounded, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isFinal
                        ? Fmt.dayMonthYear(game.startTime)
                        : Fmt.gameDateTime(game.startTime),
                    style: text.bodySmall?.copyWith(color: Colors.white),
                  ),
                ),
                const Icon(Icons.place_rounded, size: 15, color: Colors.white),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    game.venue,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          if (headline != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              headline!,
              style: text.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.name,
    required this.short,
    required this.score,
    required this.isWinner,
    required this.accent,
  });

  final String name;
  final String short;
  final int? score;
  final bool isWinner;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.6), width: 2),
          ),
          child: Center(
            child: Text(
              short,
              style: BgTypography.statNumber(Colors.white, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        if (score != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '$score',
              style: BgTypography.statNumber(
                isWinner ? BgColors.goldBright : Colors.white,
                size: 30,
              ),
            ),
          ),
      ],
    );
  }
}

/// A segmented countdown to a game start (days / hours / minutes).
class CountdownStrip extends StatelessWidget {
  const CountdownStrip({super.key, required this.target, this.label});

  final DateTime? target;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final ({int days, int hours, int minutes, bool live}) parts =
        Fmt.countdownParts(target);
    final TextTheme text = Theme.of(context).textTheme;

    if (parts.live) {
      return BgCard(
        color: BgColors.deepBlue,
        child: Row(
          children: <Widget>[
            const Icon(Icons.bolt_rounded, color: BgColors.goldBright),
            const SizedBox(width: 8),
            Text(
              'Game time! Kickoff is here.',
              style: text.titleMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.timer_outlined,
                  size: 16, color: BgColors.deepBlue),
              const SizedBox(width: 6),
              Text(
                label ?? 'Next game starts in',
                style: BgTypography.eyebrow(BgColors.slate),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _TimeBlock(value: parts.days, unit: 'DAYS'),
              _sep(),
              _TimeBlock(value: parts.hours, unit: 'HRS'),
              _sep(),
              _TimeBlock(value: parts.minutes, unit: 'MIN'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sep() => Text(
        ':',
        style: BgTypography.statNumber(BgColors.hairline, size: 28),
      );
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({required this.value, required this.unit});

  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value.toString().padLeft(2, '0'),
          style: BgTypography.statNumber(BgColors.deepBlue, size: 34),
        ),
        Text(unit, style: BgTypography.eyebrow(BgColors.mist)),
      ],
    );
  }
}

/// A labeled "fan confidence" meter (0..100).
class FanConfidenceMeter extends StatelessWidget {
  const FanConfidenceMeter({
    super.key,
    required this.confidence,
    this.title = 'Fan Confidence',
    this.subtitle,
  });

  final int confidence;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.groups_rounded,
                      size: 18, color: BgColors.deepBlue),
                  const SizedBox(width: 6),
                  Text(title, style: text.titleMedium),
                ],
              ),
              Text(
                '$confidence%',
                style: BgTypography.statNumber(BgColors.deepBlue, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MeterBar(value: confidence / 100),
          const SizedBox(height: 8),
          Text(
            subtitle ??
                'How confident the Big Blue Nation feels about this matchup.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}
