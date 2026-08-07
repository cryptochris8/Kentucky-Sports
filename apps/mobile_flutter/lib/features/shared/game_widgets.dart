import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';

/// Visual treatment for [MatchupHero].
///
/// - [bento]: the original soft-gradient card used on the Bento Home and team
///   pages. Its look is intentionally preserved.
/// - [broadcast]: the "Modern Broadcast" scorebug treatment (Pass 3) used on the
///   Gameday surfaces — a navy lower-third panel, big SOLID Oswald scores
///   (count-up on finals), and a thin gold rule. High-contrast in light + dark.
enum MatchupHeroVariant { bento, broadcast }

/// A matchup hero card: Kentucky vs opponent with venue/time, broadcast, and
/// (for finals) the final score.
///
/// Two skins via [variant]: the default [MatchupHeroVariant.bento] (the soft
/// gradient card kept for Home/team pages) and [MatchupHeroVariant.broadcast]
/// (the navy scorebug used on Gameday).
class MatchupHero extends StatelessWidget {
  const MatchupHero({
    super.key,
    required this.game,
    this.headline,
    this.onTap,
    this.variant = MatchupHeroVariant.bento,
  });

  final Game game;
  final String? headline;
  final VoidCallback? onTap;
  final MatchupHeroVariant variant;

  @override
  Widget build(BuildContext context) {
    if (variant == MatchupHeroVariant.broadcast) {
      return _BroadcastMatchupHero(
        game: game,
        headline: headline,
        onTap: onTap,
      );
    }
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
                  isWinner: isFinal && game.kentuckyWon == true,
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
                  isWinner: isFinal && game.kentuckyWon == false,
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

/// The "Modern Broadcast" matchup scorebug — a navy lower-third panel with big
/// SOLID Oswald scores (count-up on finals) and a thin gold rule. Reads as a
/// premium broadcast surface in BOTH light and dark mode.
class _BroadcastMatchupHero extends StatelessWidget {
  const _BroadcastMatchupHero({
    required this.game,
    required this.headline,
    required this.onTap,
  });

  final Game game;
  final String? headline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool isFinal = game.isFinal;

    return BroadcastPanel(
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Status strip — sport · rivalry · broadcast/FINAL, broadcast-styled.
          Row(
            children: <Widget>[
              BroadcastChip(
                label: Fmt.sportLabel(game.sport),
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              if (game.rivalry != null)
                BroadcastChip(
                  label: game.rivalry!,
                  color: BgColors.goldBright,
                  icon: Icons.local_fire_department_rounded,
                ),
              const Spacer(),
              if (isFinal)
                BroadcastChip(label: 'Final', color: Colors.white)
              else
                BroadcastChip(
                  label: game.broadcast,
                  color: Colors.white,
                  icon: Icons.live_tv_rounded,
                ),
            ],
          ),
          const SizedBox(height: 6),
          const GoldRule(width: 64),
          const SizedBox(height: 14),
          // The scoreline — big solid score numbers, broadcast face.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: _BroadcastTeamRow(
                  name: 'Kentucky',
                  short: 'UK',
                  score: isFinal ? game.kentuckyScore : null,
                  isWinner: isFinal && game.kentuckyWon == true,
                  accent: BgColors.goldBright,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      isFinal ? '–' : 'VS',
                      style: BgTypography.broadcast(
                        Colors.white.withValues(alpha: 0.55),
                        fontSize: 22,
                      ),
                    ),
                    if (game.isHome && !isFinal)
                      Text(
                        'HOME',
                        style: text.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _BroadcastTeamRow(
                  name: game.opponentName,
                  short: game.opponentShort,
                  score: isFinal ? game.opponentScore : null,
                  isWinner: isFinal && game.kentuckyWon == false,
                  accent: Colors.white,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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

/// One team line inside the broadcast scorebug: jersey/short tile + name, and
/// (for finals) a big SOLID count-up score in the broadcast face.
class _BroadcastTeamRow extends StatelessWidget {
  const _BroadcastTeamRow({
    required this.name,
    required this.short,
    required this.score,
    required this.isWinner,
    required this.accent,
    this.alignEnd = false,
  });

  final String name;
  final String short;
  final int? score;
  final bool isWinner;
  final Color accent;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final Widget badge = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.6),
      ),
      child: Center(
        child: Text(
          short,
          style: BgTypography.broadcast(Colors.white, fontSize: 18),
        ),
      ),
    );
    final Widget nameText = Flexible(
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );

    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: alignEnd
              ? <Widget>[nameText, const SizedBox(width: 10), badge]
              : <Widget>[badge, const SizedBox(width: 10), nameText],
        ),
        if (score != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CountUpScore(
              value: score!,
              size: 48,
              color: isWinner ? BgColors.goldBright : Colors.white,
            ),
          ),
      ],
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

/// A segmented countdown to a game start (days / hours / minutes) that ticks
/// while on screen via a periodic [Timer] (disposed with the widget). The
/// timer only runs while there is a countdown left: an already-live target
/// schedules none, and a countdown cancels its own timer once it reaches game
/// time — the live banner is static, so further ticks would be pure churn.
/// Pass [sport] for sport-correct copy ("Kickoff" / "Tipoff" / …) — never
/// football-only wording on a basketball game.
class CountdownStrip extends StatefulWidget {
  const CountdownStrip({
    super.key,
    required this.target,
    this.label,
    this.sport,
    this.clock,
  });

  final DateTime? target;
  final String? label;

  /// Sport key (e.g. `mens_basketball`) used for the "game time" copy.
  final String? sport;

  /// Injectable time source for tests; defaults to [DateTime.now].
  @visibleForTesting
  final DateTime Function()? clock;

  @override
  State<CountdownStrip> createState() => _CountdownStripState();
}

class _CountdownStripState extends State<CountdownStrip> {
  Timer? _timer;

  /// Whether the periodic refresh timer is currently scheduled (test hook).
  @visibleForTesting
  bool get isTicking => _timer?.isActive ?? false;

  ({int days, int hours, int minutes, bool live}) get _parts =>
      Fmt.countdownParts(widget.target, from: widget.clock?.call());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _armTimer();
  }

  @override
  void didUpdateWidget(CountdownStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) _armTimer();
  }

  /// Schedules the periodic refresh, but only while a countdown is running —
  /// an already-live target renders a static banner, so no timer is needed.
  void _armTimer() {
    _timer?.cancel();
    _timer = null;
    if (_parts.live) return;
    // The display resolution is one minute, so a 30s tick keeps it accurate.
    // Reduce-motion aware: with animations disabled we refresh only once a
    // minute (content stays honest with the least possible churn).
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _timer = Timer.periodic(
      Duration(seconds: reduceMotion ? 60 : 30),
      (_) {
        // Stop ticking once game time arrives: one last rebuild flips the
        // strip to the (static) live banner, then the timer is done.
        if (_parts.live) {
          _timer?.cancel();
          _timer = null;
        }
        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ({int days, int hours, int minutes, bool live}) parts = _parts;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;

    if (parts.live) {
      final String? verb =
          widget.sport == null ? null : Fmt.startVerb(widget.sport!);
      return BgCard(
        color: BgColors.deepBlue,
        child: Row(
          children: <Widget>[
            const Icon(Icons.bolt_rounded, color: BgColors.goldBright),
            const SizedBox(width: 8),
            Text(
              verb == null ? "It's game time!" : 'Game time! $verb is here.',
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
              Icon(Icons.timer_outlined, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                widget.label ?? 'Next game starts in',
                style: BgTypography.eyebrow(scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _TimeBlock(value: parts.days, unit: 'DAYS'),
              _sep(scheme),
              _TimeBlock(value: parts.hours, unit: 'HRS'),
              _sep(scheme),
              _TimeBlock(value: parts.minutes, unit: 'MIN'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sep(ColorScheme scheme) => Text(
        ':',
        style: BgTypography.statNumber(scheme.outline, size: 28),
      );
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({required this.value, required this.unit});

  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        Text(
          value.toString().padLeft(2, '0'),
          style: BgTypography.statNumber(scheme.primary, size: 34),
        ),
        Text(unit, style: BgTypography.eyebrow(scheme.onSurfaceVariant)),
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.groups_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(title, style: text.titleMedium),
                ],
              ),
              Text(
                '$confidence%',
                style: BgTypography.statNumber(scheme.primary, size: 24),
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
