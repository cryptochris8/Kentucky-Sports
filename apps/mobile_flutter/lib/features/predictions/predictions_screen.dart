import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stats_engine/stats_engine.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/config.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/local_state.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../shared/prediction_card.dart';

/// Prediction Center — open picks, scored results, and the season leaderboard.
/// Picks are local-only (no backend) per the build spec.
class PredictionsScreen extends ConsumerWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Predictions'),
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Open'),
              Tab(text: 'Results'),
              Tab(text: 'Leaderboard'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _OpenTab(),
            _ResultsTab(),
            _LeaderboardTab(),
          ],
        ),
      ),
    );
  }
}

class _OpenTab extends ConsumerWidget {
  const _OpenTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Prediction>> open =
        ref.watch(openPredictionsProvider);
    final int sessionXp = ref.watch(sessionXpProvider);

    return open.when(
      loading: () => const LoadingView(label: 'Loading predictions'),
      error: (Object e, _) => ErrorView(message: '$e'),
      data: (List<Prediction> preds) {
        if (preds.isEmpty) {
          return const EmptyView(
            title: 'No open predictions',
            subtitle: 'New picks open before each Kentucky game.',
            icon: Icons.task_alt_rounded,
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: <Widget>[
            if (sessionXp > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BgCard(
                  color: BgColors.positive.withValues(alpha: 0.08),
                  borderColor: Colors.transparent,
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.bolt_rounded, color: BgColors.positive),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have earned +$sessionXp XP this session. Keep picking!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (final Prediction p in preds)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PredictionCard(prediction: p),
              ),
          ],
        );
      },
    );
  }
}

class _ResultsTab extends ConsumerWidget {
  const _ResultsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Prediction>> scored =
        ref.watch(scoredPredictionsProvider);
    final AsyncValue<List<PredictionEntry>> myEntries =
        ref.watch(myEntriesProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return scored.when(
      loading: () => const LoadingView(),
      error: (Object e, _) => ErrorView(message: '$e'),
      data: (List<Prediction> preds) {
        if (preds.isEmpty) {
          return const EmptyView(
            title: 'No results yet',
            subtitle: 'Scored predictions show up here after games finish.',
            icon: Icons.scoreboard_outlined,
          );
        }
        final List<PredictionEntry> entries = myEntries.maybeWhen(
          data: (List<PredictionEntry> e) => e,
          orElse: () => <PredictionEntry>[],
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: <Widget>[
            for (final Prediction p in preds)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ResultCard(
                  prediction: p,
                  entry: _entryFor(entries, p.id),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Results are scored from demo seed data. In production, Cloud '
              'Functions score predictions and award XP/badges.',
              style: text.bodySmall,
            ),
          ],
        );
      },
    );
  }

  PredictionEntry? _entryFor(List<PredictionEntry> entries, String predId) {
    for (final PredictionEntry e in entries) {
      if (e.predictionId == predId) return e;
    }
    return null;
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.prediction, required this.entry});

  final Prediction prediction;
  final PredictionEntry? entry;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final PredictionOption? correct =
        prediction.optionById(prediction.correctOptionId);
    final bool gotIt = entry?.isCorrect ?? false;
    final bool played = entry != null;

    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(prediction.question, style: text.titleMedium)),
              if (played)
                Pill(
                  label: gotIt ? '+${entry!.pointsAwarded} XP' : 'Missed',
                  color: gotIt ? BgColors.positive : BgColors.negative,
                  icon: gotIt
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  dense: true,
                )
              else
                Pill(label: 'Final', color: BgColors.slate, dense: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(Icons.verified_rounded,
                  size: 16, color: BgColors.positive),
              const SizedBox(width: 6),
              Text('Correct: ${correct?.label ?? '—'}', style: text.bodyMedium),
            ],
          ),
          if (played) ...<Widget>[
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Icon(
                  gotIt ? Icons.thumb_up_rounded : Icons.person_rounded,
                  size: 16,
                  color: gotIt ? BgColors.positive : BgColors.slate,
                ),
                const SizedBox(width: 6),
                Text(
                  'Your pick: '
                  '${prediction.optionById(entry!.selectedOptionId)?.label ?? '—'}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppUser>> board = ref.watch(leaderboardProvider);
    return board.when(
      loading: () => const LoadingView(),
      error: (Object e, _) => ErrorView(message: '$e'),
      data: (List<AppUser> users) {
        if (users.isEmpty) {
          return const EmptyView(title: 'No fans on the board yet');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int i) =>
              _LeaderRow(rank: i + 1, user: users[i]),
        );
      },
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.rank, required this.user});

  final int rank;
  final AppUser user;

  Color get _rankColor {
    switch (rank) {
      case 1:
        return BgColors.bluegrassGold;
      case 2:
        return BgColors.mist;
      case 3:
        return BgColors.goldDark;
      default:
        return BgColors.slate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final bool isMe = user.id == AppConfig.demoUserId;
    final LevelInfo info = levelInfoForXp(user.xp);

    return BgCard(
      // Theme-aware "me" highlight so the row reads in light AND dark.
      color: isMe ? scheme.primary.withValues(alpha: 0.10) : scheme.surface,
      borderColor: isMe ? scheme.primary : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 32,
            child: rank <= 3
                ? Icon(Icons.emoji_events_rounded, color: _rankColor, size: 24)
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: BgTypography.broadcast(
                      scheme.onSurfaceVariant,
                      fontSize: 18,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.primary,
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        isMe ? '${user.displayName} (you)' : user.displayName,
                        style: text.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Lvl ${info.level} · ${info.name} · '
                  '${user.predictionRecord.correct}/${user.predictionRecord.total} correct',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                Fmt.number(user.xp),
                style: BgTypography.broadcast(scheme.primary, fontSize: 20),
              ),
              Text('XP', style: text.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
