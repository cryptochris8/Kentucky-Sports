import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stats_engine/stats_engine.dart';

import '../../app/router.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../shared/article_card.dart';
import '../shared/game_widgets.dart';
import '../shared/prediction_card.dart';
import '../stats_lab/stats_lab_screen.dart';

/// Gameday HQ — the hub for the featured matchup, now with three sub-tabs
/// (Pass 2): **Breakdown · Stats · Predictions**.
///
///  - Breakdown: the pregame matchup hero + keys + gameday story (and the
///    postgame recap for the most recent final).
///  - Stats: the former Stats Lab content (Four Factors, advanced football,
///    compare, stat story) hosted via [StatsLabBody].
///  - Predictions: the open picks for the featured game, surfaced here.
class GamedayScreen extends ConsumerStatefulWidget {
  const GamedayScreen({super.key});

  @override
  ConsumerState<GamedayScreen> createState() => _GamedayScreenState();
}

class _GamedayScreenState extends ConsumerState<GamedayScreen> {
  int _tab = 0; // 0 = Breakdown, 1 = Stats, 2 = Predictions.

  @override
  Widget build(BuildContext context) {
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
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SegmentedToggle(
              segments: const <SegmentItem>[
                SegmentItem(label: 'Breakdown', icon: Icons.sports_rounded),
                SegmentItem(label: 'Stats', icon: Icons.insights_rounded),
                SegmentItem(
                  label: 'Predictions',
                  icon: Icons.task_alt_rounded,
                ),
              ],
              index: _tab,
              onChanged: (int i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const <Widget>[
                _BreakdownTab(),
                StatsLabBody(),
                _PredictionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Breakdown tab — pregame matchup + postgame recap.
// ---------------------------------------------------------------------------

class _BreakdownTab extends ConsumerWidget {
  const _BreakdownTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Game?> featured = ref.watch(featuredGameProvider);
    final AsyncValue<Game?> lastFinal = ref.watch(lastFinalGameProvider);

    return featured.when(
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: <Widget>[
              _PregameSection(game: game),
              const SizedBox(height: 24),
              _PostgameSection(lastFinal: lastFinal),
            ],
          ),
        );
      },
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
              color: Theme.of(context).colorScheme.primary,
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
          error: (Object e, _) => MatchupHero(
            game: game,
            variant: MatchupHeroVariant.broadcast,
          ), // hero still renders without summary
          data: (GameSummary? s) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MatchupHero(
                  game: game,
                  headline: s?.headline,
                  variant: MatchupHeroVariant.broadcast,
                ),
                const SizedBox(height: 12),
                CountdownStrip(target: game.startTime, sport: game.sport),
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
                _GamedayStorySection(gameId: game.id),
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
    // Win-probability win-bar tint: gold for the leader, white for the trailer.
    final bool kyAhead = summary.kentuckyWinProb >= summary.opponentWinProb;
    return BroadcastPanel(
      eyebrow: 'Matchup Verdict',
      eyebrowIcon: Icons.insights_rounded,
      trailing: BroadcastChip(
        label: v.label,
        color: BgColors.goldBright,
        icon: v.icon,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Win probability — the score-forward stat strip (big solid Oswald).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: BroadcastStat(
                  label: 'Kentucky Win',
                  value: Fmt.percent(summary.kentuckyWinProb),
                  valueColor:
                      kyAhead ? BgColors.goldBright : Colors.white,
                  meter: summary.kentuckyWinProb,
                  meterColor:
                      kyAhead ? BgColors.goldBright : Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BroadcastStat(
                  label: 'Opponent Win',
                  value: Fmt.percent(summary.opponentWinProb),
                  valueColor:
                      kyAhead ? Colors.white : BgColors.goldBright,
                  meter: summary.opponentWinProb,
                  meterColor:
                      kyAhead ? Colors.white : BgColors.goldBright,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            summary.statStory,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          // Attribution stays on every stat card (hard rule) — on a light strip
          // so the required source/confidence labels keep their AA contrast.
          _AttributionStrip(
            source: summary.source,
            updatedAt: summary.updatedAt,
            confidence: summary.confidence,
          ),
        ],
      ),
    );
  }
}

/// A light rounded strip that hosts the required [SourceConfidenceRow] inside a
/// dark broadcast panel, so the muted attribution text keeps AA contrast.
class _AttributionStrip extends StatelessWidget {
  const _AttributionStrip({
    required this.source,
    required this.updatedAt,
    required this.confidence,
  });

  final String source;
  final DateTime? updatedAt;
  final String confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
      ),
      // Force a light scheme so the muted attribution text + confidence pill
      // keep AA contrast on this white strip, even when the app is in dark mode.
      child: Theme(
        data: BgTheme.light(),
        child: SourceConfidenceRow(
          source: source,
          updatedAt: updatedAt,
          confidence: confidence,
        ),
      ),
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
              Text(
                'UK',
                style: BgTypography.eyebrow(
                    Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 36),
              Text(
                game.opponentShort,
                style: BgTypography.eyebrow(
                    Theme.of(context).colorScheme.tertiary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...keys.map((String key) {
            final double ky = c.kentucky[key]!;
            final double opp = c.opponent[key]!;
            final MetricLabel meta = labelFor(key, sport: game.sport);
            // Strict comparison — equal values are a tie, never a UK edge.
            final ({bool kentuckyWins, bool tie}) edge = compareEdge(
              kentucky: ky,
              opponent: opp,
              higherIsBetter: meta.higherIsBetter,
            );
            return CompareRow(
              label: meta.shortLabel,
              kentuckyText: formatMetricValue(key, ky, sport: game.sport),
              opponentText: formatMetricValue(key, opp, sport: game.sport),
              kentuckyWins: edge.kentuckyWins,
              tie: edge.tie,
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

// ---------------------------------------------------------------------------
// Predictions tab — open picks for the featured game (+ link to the center).
// ---------------------------------------------------------------------------

class _PredictionsTab extends ConsumerWidget {
  const _PredictionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Game?> featured = ref.watch(featuredGameProvider);
    final AsyncValue<List<Prediction>> preds = ref.watch(predictionsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return preds.when(
      loading: () => const LoadingView(label: 'Loading predictions'),
      error: (Object e, _) => ErrorView(message: '$e'),
      data: (List<Prediction> all) {
        final Game? game = featured.maybeWhen(
          data: (Game? g) => g,
          orElse: () => null,
        );
        final List<Prediction> openForGame = game == null
            ? <Prediction>[]
            : all
                .where((Prediction p) => p.gameId == game.id && p.isOpen)
                .toList();
        final List<Prediction> scoredForGame = game == null
            ? <Prediction>[]
            : all
                .where((Prediction p) => p.gameId == game.id && p.isScored)
                .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: <Widget>[
            const SectionHeader(
              title: 'Make Your Picks',
              eyebrow: 'Free-to-play predictions',
              padding: EdgeInsets.only(bottom: 10),
            ),
            if (openForGame.isEmpty)
              const BgCard(
                child: EmptyView(
                  title: 'No open picks for this matchup',
                  subtitle: 'New picks open before each Kentucky game.',
                  icon: Icons.task_alt_rounded,
                ),
              )
            else
              for (final Prediction p in openForGame)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PredictionCard(prediction: p),
                ),
            const SizedBox(height: 8),
            BroadcastPanel(
              padding: const EdgeInsets.all(14),
              onTap: () => context.push(Routes.predictions),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: BgColors.goldBright.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(Icons.leaderboard_rounded,
                        color: BgColors.goldBright),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'PREDICTION CENTER',
                          style: BgTypography.eyebrow(BgColors.goldBright),
                        ),
                        const SizedBox(height: 4),
                        const GoldRule(width: 40),
                        const SizedBox(height: 6),
                        Text(
                          'All open picks, results & the season leaderboard',
                          style: text.titleMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
            if (scoredForGame.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              const SectionHeader(
                title: 'Results',
                eyebrow: 'How this matchup scored',
                padding: EdgeInsets.only(bottom: 10),
              ),
              _PredictionResults(game: game!),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Postgame.
// ---------------------------------------------------------------------------

class _PostgameSection extends ConsumerWidget {
  const _PostgameSection({required this.lastFinal});

  final AsyncValue<Game?> lastFinal;

  /// Postgame color line derived ONLY from the game doc: outcome from
  /// [Game.kentuckyWon], location from `venue`/`isHome`. Null (no headline)
  /// when the outcome is unknown — never an asserted venue or result.
  String? _headline(Game game) {
    final bool? won = game.kentuckyWon;
    if (won == null) return null;
    final String where = game.venue.isNotEmpty
        ? ' at ${game.venue}'
        : game.isHome
            ? ' at home'
            : ' on the road';
    return won
        ? 'Cats take care of business$where.'
        : 'Tough one$where.';
  }

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
              variant: MatchupHeroVariant.broadcast,
              headline: _headline(game),
            ),
            const SizedBox(height: 12),
            _PostgameResult(game: game),
            const SizedBox(height: 12),
            _GamedayStorySection(gameId: game.id),
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
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    // Tri-state outcome: a final doc without a result or scores must read as
    // "Final", never a false "Kentucky Loss" (hard rule 6).
    final bool? won = game.kentuckyWon;
    final bool hasScores =
        game.kentuckyScore != null && game.opponentScore != null;
    final Color accent = won == null
        ? theme.colorScheme.primary
        : won
            ? BgColors.positive
            : BgColors.negative;
    return BgCard(
      color: won == null
          ? theme.colorScheme.surfaceContainerHighest
          : accent.withValues(alpha: 0.08),
      borderColor: Colors.transparent,
      child: Row(
        children: <Widget>[
          Icon(
            won == true
                ? Icons.emoji_events_rounded
                : Icons.sports_score_rounded,
            color: accent,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  won == null
                      ? 'Final'
                      : won
                          ? 'Kentucky Win'
                          : 'Kentucky Loss',
                  style: text.titleLarge?.copyWith(color: accent),
                ),
                // Only show a score line the doc can actually back up.
                if (hasScores)
                  Text(
                    'Final: Kentucky ${game.kentuckyScore} — '
                    '${game.opponentName} ${game.opponentScore}',
                    style: text.bodyMedium,
                  )
                else
                  Text(
                    'Kentucky vs ${game.opponentName} — score unavailable',
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BgCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child:
                                    Text(p.question, style: text.titleMedium),
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

// ---------------------------------------------------------------------------
// Gameday Story (article card inline in the screen)
// ---------------------------------------------------------------------------

class _GamedayStorySection extends ConsumerWidget {
  const _GamedayStorySection({required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Article?> articleAsync =
        ref.watch(articleForGameProvider(gameId));

    return articleAsync.maybeWhen(
      data: (Article? article) {
        if (article == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: article.isRecap ? 'Game Recap' : 'Gameday Story',
              eyebrow: article.isRecap
                  ? 'AI-written recap'
                  : 'AI-written preview',
              icon: Icons.article_rounded,
              padding: const EdgeInsets.only(bottom: 10),
            ),
            GamedayStoryCard(article: article),
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
          data: (Game? g) => g == null
              ? const SizedBox.shrink()
              : MatchupHero(game: g, variant: MatchupHeroVariant.broadcast),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
