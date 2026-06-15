import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stats_engine/stats_engine.dart';

import '../../app/router.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../shared/game_widgets.dart';
import '../shared/prediction_card.dart';

/// Gameday HQ — the hub for the featured matchup. Shows a pregame breakdown for
/// the next featured game and a postgame recap for the most recent final.
class GamedayScreen extends ConsumerWidget {
  const GamedayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Game?> featured = ref.watch(featuredGameProvider);
    final AsyncValue<Game?> lastFinal = ref.watch(lastFinalGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gameday HQ'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push(Routes.predictions),
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Prediction Center',
          ),
          IconButton(
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: featured.when(
        loading: () => const LoadingView(label: 'Building the matchup'),
        error: (Object e, _) => ErrorView(
          message: '$e',
          onRetry: () => ref.invalidate(gamesProvider),
        ),
        data: (Game? game) {
          if (game == null) {
            return _OffseasonView(lastFinal: lastFinal);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(gamesProvider);
              ref.invalidate(gameSummariesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: <Widget>[
                _PregameSection(game: game),
                const SizedBox(height: 24),
                _PostgameSection(lastFinal: lastFinal),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PregameSection extends ConsumerWidget {
  const _PregameSection({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<GameSummary?> summary =
        ref.watch(gameSummaryByIdProvider(game.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Pill(
              label: 'PREGAME',
              color: BgColors.deepBlue,
              icon: Icons.sports_rounded,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                Fmt.gameDateTime(game.startTime),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        summary.when(
          loading: () => const BgCard(child: LoadingView()),
          error: (Object e, _) =>
              MatchupHero(game: game), // hero still renders without summary
          data: (GameSummary? s) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MatchupHero(game: game, headline: s?.headline),
                const SizedBox(height: 12),
                CountdownStrip(target: game.startTime),
                if (s != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _MatchupVerdict(summary: s),
                  const SizedBox(height: 12),
                  _TeamComparisonCard(summary: s, game: game),
                  const SizedBox(height: 12),
                  _KeysToGame(keys: s.keysToGame),
                  const SizedBox(height: 12),
                  _PlayerToWatch(summary: s),
                  const SizedBox(height: 12),
                  FanConfidenceMeter(confidence: s.fanConfidence),
                  const SizedBox(height: 12),
                  _ConcernMeter(summary: s),
                ],
                const SizedBox(height: 12),
                _PredictionCta(game: game),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MatchupVerdict extends StatelessWidget {
  const _MatchupVerdict({required this.summary});

  final GameSummary summary;

  ({String label, Color color, IconData icon}) get _verdict {
    switch (summary.matchupVerdict) {
      case 'kentucky_edge':
        return (
          label: 'Kentucky Edge',
          color: BgColors.positive,
          icon: Icons.trending_up_rounded
        );
      case 'opponent_edge':
        return (
          label: 'Opponent Edge',
          color: BgColors.negative,
          icon: Icons.trending_down_rounded
        );
      case 'toss_up':
      default:
        return (
          label: 'Toss-Up',
          color: BgColors.warning,
          icon: Icons.balance_rounded
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ({String label, Color color, IconData icon}) v = _verdict;
    final TextTheme text = Theme.of(context).textTheme;
    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(v.icon, color: v.color),
              const SizedBox(width: 8),
              Text('Matchup Verdict', style: text.titleMedium),
              const Spacer(),
              Pill(label: v.label, color: v.color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _WinProb(
                  label: 'Kentucky',
                  prob: summary.kentuckyWinProb,
                  color: BgColors.deepBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WinProb(
                  label: 'Opponent',
                  prob: summary.opponentWinProb,
                  color: BgColors.bluegrassGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(summary.statStory, style: text.bodyMedium),
          const Divider(height: 22),
          SourceConfidenceRow(
            source: summary.source,
            updatedAt: summary.updatedAt,
            confidence: summary.confidence,
          ),
        ],
      ),
    );
  }
}

class _WinProb extends StatelessWidget {
  const _WinProb({required this.label, required this.prob, required this.color});

  final String label;
  final double prob;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: BgTypography.eyebrow(BgColors.slate)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              Fmt.percent(prob),
              style: BgTypography.statNumber(color, size: 26),
            ),
            const SizedBox(width: 4),
            Text('win', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 6),
        MeterBar(value: prob, color: color, height: 8),
      ],
    );
  }
}

class _TeamComparisonCard extends StatelessWidget {
  const _TeamComparisonCard({required this.summary, required this.game});

  final GameSummary summary;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TeamComparison c = summary.teamComparison;
    final List<String> keys = c.kentucky.keys
        .where((String k) => c.opponent.containsKey(k))
        .toList();

    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text('Team Comparison', style: text.titleMedium),
              const Spacer(),
              Text('UK', style: BgTypography.eyebrow(BgColors.deepBlue)),
              const SizedBox(width: 36),
              Text(
                game.opponentShort,
                style: BgTypography.eyebrow(BgColors.goldDark),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...keys.map((String key) {
            final double ky = c.kentucky[key]!;
            final double opp = c.opponent[key]!;
            final MetricLabel meta = labelFor(key, sport: game.sport);
            final bool kyWins =
                meta.higherIsBetter ? ky >= opp : ky <= opp;
            return CompareRow(
              label: meta.shortLabel,
              kentuckyText: formatMetricValue(key, ky, sport: game.sport),
              opponentText: formatMetricValue(key, opp, sport: game.sport),
              kentuckyWins: kyWins,
              opponentName: game.opponentShort,
            );
          }),
          const Divider(height: 20),
          SourceConfidenceRow(
            source: summary.source,
            updatedAt: summary.updatedAt,
            confidence: summary.confidence,
          ),
        ],
      ),
    );
  }
}

class _KeysToGame extends StatelessWidget {
  const _KeysToGame({required this.keys});

  final List<String> keys;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.vpn_key_rounded,
                  size: 18, color: BgColors.bluegrassGold),
              const SizedBox(width: 8),
              Text('3 Keys to the Game', style: text.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(keys.length, (int i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: BgColors.goldGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: BgTypography.statNumber(BgColors.blueDark,
                            size: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(keys[i], style: text.bodyMedium)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PlayerToWatch extends ConsumerWidget {
  const _PlayerToWatch({required this.summary});

  final GameSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayerToWatch? ptw = summary.playerToWatch;
    if (ptw == null) return const SizedBox.shrink();
    final AsyncValue<PlayerProfile?> player =
        ref.watch(playerByIdProvider(ptw.playerId));
    final TextTheme text = Theme.of(context).textTheme;

    return player.maybeWhen(
      data: (PlayerProfile? p) {
        if (p == null) return const SizedBox.shrink();
        return BgCard(
          onTap: () => context.push(Routes.player(p.id)),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: BgColors.heroGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    p.jersey != null ? '#${p.jersey}' : p.position,
                    style: BgTypography.statNumber(Colors.white, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'PLAYER TO WATCH',
                      style: BgTypography.eyebrow(BgColors.bluegrassGold),
                    ),
                    Text(p.name, style: text.titleLarge),
                    const SizedBox(height: 2),
                    Text(ptw.reason, style: text.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: BgColors.mist),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ConcernMeter extends StatelessWidget {
  const _ConcernMeter({required this.summary});

  final GameSummary summary;

  ({Color color, double value}) get _level {
    switch (summary.concernLevel) {
      case 'high':
        return (color: BgColors.negative, value: 0.85);
      case 'medium':
        return (color: BgColors.warning, value: 0.55);
      case 'low':
      default:
        return (color: BgColors.positive, value: 0.25);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ({Color color, double value}) l = _level;
    final TextTheme text = Theme.of(context).textTheme;
    return BgCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 18, color: l.color),
              const SizedBox(width: 8),
              Text('Concern Meter', style: text.titleMedium),
              const Spacer(),
              Pill(
                label: summary.concernLevel.toUpperCase(),
                color: l.color,
              ),
            ],
          ),
          const SizedBox(height: 10),
          MeterBar(value: l.value, color: l.color),
          const SizedBox(height: 8),
          Text(summary.concernNote, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _PredictionCta extends ConsumerWidget {
  const _PredictionCta({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Prediction>> preds =
        ref.watch(predictionsProvider);
    return preds.maybeWhen(
      data: (List<Prediction> all) {
        final List<Prediction> forGame = all
            .where((Prediction p) => p.gameId == game.id && p.isOpen)
            .toList();
        if (forGame.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(
              title: 'Make Your Picks',
              eyebrow: 'Free-to-play predictions',
              padding: EdgeInsets.only(top: 4, bottom: 10),
            ),
            for (final Prediction p in forGame)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PredictionCard(prediction: p),
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// --- Postgame ---------------------------------------------------------------

class _PostgameSection extends ConsumerWidget {
  const _PostgameSection({required this.lastFinal});

  final AsyncValue<Game?> lastFinal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return lastFinal.maybeWhen(
      data: (Game? game) {
        if (game == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(
              title: 'Last Time Out',
              eyebrow: 'Postgame recap',
              padding: EdgeInsets.only(bottom: 10),
            ),
            MatchupHero(
              game: game,
              headline: game.kentuckyWon
                  ? 'Cats take care of business at home.'
                  : 'Tough one at Kroger Field.',
            ),
            const SizedBox(height: 12),
            _PostgameResult(game: game),
            const SizedBox(height: 12),
            _PredictionResults(game: game),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _PostgameResult extends StatelessWidget {
  const _PostgameResult({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool won = game.kentuckyWon;
    return BgCard(
      color: won
          ? BgColors.positive.withValues(alpha: 0.08)
          : BgColors.negative.withValues(alpha: 0.08),
      borderColor: Colors.transparent,
      child: Row(
        children: <Widget>[
          Icon(
            won ? Icons.emoji_events_rounded : Icons.sports_score_rounded,
            color: won ? BgColors.positive : BgColors.negative,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  won ? 'Kentucky Win' : 'Kentucky Loss',
                  style: text.titleLarge?.copyWith(
                    color: won ? BgColors.positive : BgColors.negative,
                  ),
                ),
                Text(
                  'Final: Kentucky ${game.kentuckyScore} — '
                  '${game.opponentName} ${game.opponentScore}',
                  style: text.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionResults extends ConsumerWidget {
  const _PredictionResults({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Prediction>> preds = ref.watch(predictionsProvider);
    final AsyncValue<List<PredictionEntry>> myEntries =
        ref.watch(myEntriesProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return preds.maybeWhen(
      data: (List<Prediction> all) {
        final List<Prediction> scored = all
            .where((Prediction p) => p.gameId == game.id && p.isScored)
            .toList();
        if (scored.isEmpty) return const SizedBox.shrink();
        final List<PredictionEntry> entries = myEntries.maybeWhen(
          data: (List<PredictionEntry> e) => e,
          orElse: () => <PredictionEntry>[],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final Prediction p in scored)
              Builder(
                builder: (BuildContext context) {
                  PredictionEntry? mine;
                  for (final PredictionEntry e in entries) {
                    if (e.predictionId == p.id) mine = e;
                  }
                  final PredictionOption? correct =
                      p.optionById(p.correctOptionId);
                  final bool gotIt = mine?.isCorrect ?? false;
                  return BgCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(p.question, style: text.titleMedium),
                            ),
                            if (mine != null)
                              Pill(
                                label: gotIt
                                    ? '+${mine.pointsAwarded} XP'
                                    : 'Missed',
                                color: gotIt
                                    ? BgColors.positive
                                    : BgColors.negative,
                                icon: gotIt
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                dense: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.flag_rounded,
                                size: 15, color: BgColors.positive),
                            const SizedBox(width: 6),
                            Text(
                              'Correct answer: ${correct?.label ?? '—'}',
                              style: text.bodyMedium,
                            ),
                          ],
                        ),
                        if (mine != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              const Icon(Icons.person_rounded,
                                  size: 15, color: BgColors.slate),
                              const SizedBox(width: 6),
                              Text(
                                'Your pick: '
                                '${p.optionById(mine.selectedOptionId)?.label ?? '—'}',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _OffseasonView extends StatelessWidget {
  const _OffseasonView({required this.lastFinal});

  final AsyncValue<Game?> lastFinal;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const EmptyView(
          title: 'No upcoming games',
          subtitle: 'It is the offseason. Here is your last result.',
          icon: Icons.beach_access_rounded,
        ),
        const SizedBox(height: 16),
        lastFinal.maybeWhen(
          data: (Game? g) =>
              g == null ? const SizedBox.shrink() : MatchupHero(game: g),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
