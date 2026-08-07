import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stats_engine/stats_engine.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/local_state.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';

/// A tappable news link card. Per hard rules, only an admin-written summary is
/// shown — no copied article text. Tapping is a stubbed link-out (snackbar).
class NewsLinkCard extends StatelessWidget {
  const NewsLinkCard({super.key, required this.card});

  final NewsCard card;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    return BgCard(
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Opens at source: ${card.url}')),
          );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.article_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Pill(
                      label: Fmt.sportLabel(card.sport),
                      color: scheme.primary,
                      dense: true,
                    ),
                    const SizedBox(width: 6),
                    Text(card.sourceName, style: text.labelSmall),
                    const Spacer(),
                    Text(Fmt.shortDay(card.publishedAt), style: text.labelSmall),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  card.title,
                  style: text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  card.summary,
                  style: text.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Icon(Icons.open_in_new_rounded,
                        size: 13, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('Read at source', style: text.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An interactive poll card. Voting is local-only and adds session XP once.
class PollCard extends ConsumerStatefulWidget {
  const PollCard({super.key, required this.poll});

  final Poll poll;

  @override
  ConsumerState<PollCard> createState() => _PollCardState();
}

class _PollCardState extends ConsumerState<PollCard> {
  String? _voted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;
    final TextTheme text = theme.textTheme;
    final Poll poll = widget.poll;
    // Add 1 to reflect the user's local vote in the displayed totals.
    final int totalVotes = poll.totalVotes + (_voted != null ? 1 : 0);

    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.poll_rounded, size: 18, color: accent),
              const SizedBox(width: 6),
              Text('FAN POLL', style: BgTypography.eyebrow(accent)),
              const Spacer(),
              Text('${Fmt.number(totalVotes)} votes', style: text.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(poll.question, style: text.titleLarge),
          const SizedBox(height: 14),
          ...poll.options.map((PollOption opt) {
            final int votes = opt.votes + (_voted == opt.id ? 1 : 0);
            final double pct = totalVotes == 0 ? 0 : votes / totalVotes;
            final bool mine = _voted == opt.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PollOptionRow(
                label: opt.label,
                pct: pct,
                mine: mine,
                showResults: _voted != null,
                onTap: _voted != null ? null : () => _vote(opt.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _vote(String optionId) {
    setState(() => _voted = optionId);
    ref.read(sessionXpProvider.notifier).add(5);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Vote counted · +5 XP')));
  }
}

class _PollOptionRow extends StatelessWidget {
  const _PollOptionRow({
    required this.label,
    required this.pct,
    required this.mine,
    required this.showResults,
    required this.onTap,
  });

  final String label;
  final double pct;
  final bool mine;
  final bool showResults;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                mine ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 16,
                color: mine ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: mine ? FontWeight.w700 : FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (showResults)
                Text(
                  Fmt.percent(pct),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: mine ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (showResults) ...<Widget>[
            const SizedBox(height: 6),
            MeterBar(
              value: pct,
              height: 7,
              color: mine ? scheme.primary : scheme.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// A compact XP/level header chip used at the top of Pulse and Profile.
class LevelHeader extends ConsumerWidget {
  const LevelHeader({super.key, required this.user, this.onDark = true});

  final AppUser user;
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int sessionXp = ref.watch(sessionXpProvider);
    final int totalXp = user.xp + sessionXp;
    final LevelInfo info = levelInfoForXp(totalXp);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color fg = onDark ? Colors.white : scheme.onSurface;
    final TextTheme text = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: BgColors.goldGradient,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'LVL ${info.level}',
                    style: BgTypography.eyebrow(BgColors.blueDark)
                        .copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              info.name,
              style: text.titleMedium?.copyWith(color: fg),
            ),
            const Spacer(),
            Text(
              '${Fmt.number(totalXp)} XP',
              style: BgTypography.statNumber(
                onDark ? BgColors.goldBright : scheme.primary,
                size: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MeterBar(
          value: info.progress,
          color: onDark ? BgColors.goldBright : scheme.primary,
          trackColor: onDark
              ? Colors.white.withValues(alpha: 0.2)
              : scheme.outline,
        ),
        const SizedBox(height: 4),
        Text(
          info.xpRemaining > 0
              ? '${Fmt.number(info.xpRemaining)} XP to ${levelName(info.level + 1)}'
              : 'Max level reached',
          style: text.bodySmall?.copyWith(
            color: onDark
                ? Colors.white.withValues(alpha: 0.8)
                : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
