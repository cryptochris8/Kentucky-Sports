// Hide Material's Badge widget so our Badge model name is unambiguous.
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../shared/content_widgets.dart';
import '../shared/game_widgets.dart';
import '../shared/prediction_card.dart';

/// Pulse Home — the daily landing screen. A scrollable feed of the day's most
/// engaging cards, tailored to the fan.
class PulseScreen extends ConsumerWidget {
  const PulseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppUser> user = ref.watch(currentUserProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gamesProvider);
          ref.invalidate(predictionsProvider);
          ref.invalidate(pollsProvider);
          ref.invalidate(newsCardsProvider);
        },
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(child: _PulseHeader(userAsync: user)),
            SliverToBoxAdapter(child: _NextGameSection()),
            const SliverToBoxAdapter(child: _DailyPulseCard()),
            const SliverToBoxAdapter(child: _StatOfTheDay()),
            const SliverToBoxAdapter(child: _PredictionPromptSection()),
            const SliverToBoxAdapter(child: _PollSection()),
            const SliverToBoxAdapter(child: _FanConfidenceSection()),
            const SliverToBoxAdapter(child: _BadgeProgressSection()),
            const SliverToBoxAdapter(child: _TrendingNewsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _PulseHeader extends StatelessWidget {
  const _PulseHeader({required this.userAsync});

  final AsyncValue<AppUser> userAsync;

  String get _greeting {
    final int h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        gradient: BgColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const BrandMark(size: 34),
                const Spacer(),
                IconButton(
                  onPressed: () => context.push(Routes.settings),
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  tooltip: 'Settings',
                ),
              ],
            ),
            userAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LoadingView(),
              ),
              error: (Object e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Welcome to Bluegrass Gameday',
                  style: text.headlineMedium?.copyWith(color: Colors.white),
                ),
              ),
              data: (AppUser user) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _greeting,
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    user.displayName,
                    style: BgTypography.statNumber(Colors.white, size: 28),
                  ),
                  const SizedBox(height: 16),
                  LevelHeader(user: user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextGameSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Game?> next = ref.watch(nextGameProvider);
    return next.when(
      loading: () => const _SectionLoader(label: 'Loading next game'),
      error: (Object e, _) => _SectionError(message: '$e'),
      data: (Game? game) {
        if (game == null) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: EmptyView(
              title: 'No games on the schedule',
              subtitle: 'Check back soon for the next Kentucky matchup.',
              icon: Icons.event_busy_rounded,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: <Widget>[
              CountdownStrip(
                target: game.startTime,
                label:
                    'Next: Kentucky vs ${game.opponentName} (${Fmt.sportLabel(game.sport)})',
              ),
              const SizedBox(height: 12),
              MatchupHero(
                game: game,
                onTap: () => context.go(Routes.gameday),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DailyPulseCard extends ConsumerWidget {
  const _DailyPulseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the first available game summary for the daily pulse story.
    final AsyncValue<List<GameSummary>> summaries =
        ref.watch(gameSummariesProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionHeader(
            title: 'Daily Pulse',
            eyebrow: 'Tonight in Big Blue',
            padding: EdgeInsets.only(bottom: 10),
          ),
          summaries.when(
            loading: () => const BgCard(child: LoadingView()),
            error: (Object e, _) => BgCard(
              child: Text('Pulse unavailable', style: text.bodyMedium),
            ),
            data: (List<GameSummary> list) {
              final String story = list.isNotEmpty
                  ? list.first.statStory
                  : 'Welcome to Bluegrass Gameday — your independent home for '
                      'Kentucky stats and predictions.';
              return BgCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: BgColors.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bolt_rounded,
                          color: BgColors.blueDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(story, style: text.bodyMedium)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatOfTheDay extends ConsumerWidget {
  const _StatOfTheDay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TeamStat>> stats = ref.watch(teamStatsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionHeader(
            title: 'Stat of the Day',
            eyebrow: 'Powered by the Stats Lab',
            padding: EdgeInsets.only(bottom: 10),
          ),
          stats.when(
            loading: () => const BgCard(child: LoadingView()),
            error: (Object e, _) => const SizedBox.shrink(),
            data: (List<TeamStat> list) {
              if (list.isEmpty) return const SizedBox.shrink();
              final TeamStat bball = list.firstWhere(
                (TeamStat s) => s.sport == 'mens_basketball',
                orElse: () => list.first,
              );
              final double efg = bball.statValue('effectiveFgPct') ?? 0.55;
              return StatCard.fromMetric(
                metricKey: 'effectiveFgPct',
                value: efg,
                sport: 'mens_basketball',
                source: bball.source,
                updatedAt: bball.updatedAt,
                confidence: bball.confidence,
                percentile: 82,
                rankText: '3rd in the SEC',
                trend: TrendDirection.up,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PredictionPromptSection extends ConsumerWidget {
  const _PredictionPromptSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Prediction>> open =
        ref.watch(openPredictionsProvider);
    return open.maybeWhen(
      data: (List<Prediction> preds) {
        if (preds.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(
                title: 'Make Your Pick',
                eyebrow: 'Daily prediction',
                padding: EdgeInsets.only(bottom: 10),
              ),
              PredictionPrompt(
                prediction: preds.first,
                onTap: () => context.push(Routes.predictions),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _PollSection extends ConsumerWidget {
  const _PollSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Poll>> polls = ref.watch(pollsProvider);
    return polls.maybeWhen(
      data: (List<Poll> list) {
        final List<Poll> open =
            list.where((Poll p) => p.status == 'open').toList();
        if (open.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeader(
                title: 'Today\'s Poll',
                eyebrow: 'Join the conversation',
                padding: EdgeInsets.only(bottom: 10),
              ),
              PollCard(poll: open.first),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _FanConfidenceSection extends ConsumerWidget {
  const _FanConfidenceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<GameSummary>> summaries =
        ref.watch(gameSummariesProvider);
    return summaries.maybeWhen(
      data: (List<GameSummary> list) {
        if (list.isEmpty) return const SizedBox.shrink();
        final GameSummary s = list.first;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: FanConfidenceMeter(
            confidence: s.fanConfidence,
            subtitle: s.headline,
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _BadgeProgressSection extends ConsumerWidget {
  const _BadgeProgressSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Badge>> badges = ref.watch(badgesProvider);
    final AsyncValue<Set<String>> earned = ref.watch(myEarnedBadgeIdsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return badges.maybeWhen(
      data: (List<Badge> all) {
        final Set<String> earnedIds =
            earned.maybeWhen(data: (Set<String> s) => s, orElse: () => <String>{});
        final int earnedCount = earnedIds.length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SectionHeader(
                title: 'Badge Progress',
                eyebrow: '$earnedCount of ${all.length} earned',
                padding: const EdgeInsets.only(bottom: 10),
                trailing: TextButton(
                  onPressed: () => context.push(Routes.badges),
                  child: const Text('View all'),
                ),
              ),
              BgCard(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text('Collection', style: text.titleMedium),
                        const Spacer(),
                        Text(
                          Fmt.percent(
                            all.isEmpty ? 0 : earnedCount / all.length,
                          ),
                          style: BgTypography.statNumber(
                            BgColors.deepBlue,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MeterBar(
                      value: all.isEmpty ? 0 : earnedCount / all.length,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: all.length.clamp(0, 8),
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (BuildContext context, int i) {
                          final Badge b = all[i];
                          final bool got = earnedIds.contains(b.id);
                          return _MiniBadge(badge: b, earned: got);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.badge, required this.earned});

  final Badge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final Color c = BgColors.rarity(badge.rarity);
    return Tooltip(
      message: '${badge.name}${earned ? '' : ' (locked)'}',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: earned
              ? LinearGradient(
                  colors: <Color>[c.withValues(alpha: 0.85), c],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: earned ? null : BgColors.canvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: earned ? Colors.transparent : BgColors.hairline,
          ),
        ),
        child: Icon(
          earned ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
          color: earned ? Colors.white : BgColors.mist,
          size: 24,
        ),
      ),
    );
  }
}

class _TrendingNewsSection extends ConsumerWidget {
  const _TrendingNewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NewsCard>> news = ref.watch(newsCardsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionHeader(
            title: 'Trending',
            eyebrow: 'Around the program',
            padding: EdgeInsets.only(bottom: 10),
          ),
          news.when(
            loading: () => const BgCard(child: LoadingView()),
            error: (Object e, _) => const SizedBox.shrink(),
            data: (List<NewsCard> list) {
              if (list.isEmpty) {
                return const EmptyView(title: 'No news yet');
              }
              return Column(
                children: <Widget>[
                  for (final NewsCard c in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NewsLinkCard(card: c),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionLoader extends StatelessWidget {
  const _SectionLoader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: LoadingView(label: label),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ErrorView(message: message),
    );
  }
}
