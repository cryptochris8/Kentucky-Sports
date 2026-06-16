// Hide Material's Badge widget so our Badge model name is unambiguous.
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/config.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/providers/vault_providers.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';
import '../shared/content_widgets.dart';
import '../shared/game_widgets.dart';

/// Home — the flagship Bento content hub (Pass 2). A greeting + a grid of
/// asymmetric tiles that surface the day's most engaging content and route into
/// the five pillars: a Gameday hero, your picks + leaderboard (→ Predictions),
/// the news/recap/stat feed, and an Explore row (Vault, Preps, + coming-soon
/// Heritage and The Porch tiles so the structure scales to the vision).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
          ref.invalidate(usersProvider);
        },
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(child: _HomeHeader(userAsync: user)),
            const SliverToBoxAdapter(child: _GamedayHeroTile()),
            const SliverToBoxAdapter(child: _PicksAndLeaderboardRow()),
            const SliverToBoxAdapter(child: _DailyDropSection()),
            const SliverToBoxAdapter(child: _PollSection()),
            const SliverToBoxAdapter(child: _FeedSection()),
            const SliverToBoxAdapter(child: _ExploreSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — greeting + a one-line "the Cats play Saturday" hook.
// ---------------------------------------------------------------------------

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.userAsync});

  final AsyncValue<AppUser> userAsync;

  String get _greeting {
    final int h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AsyncValue<Game?> next = ref.watch(nextGameProvider);

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
                  const SizedBox(height: 6),
                  _HeaderHook(next: next),
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

class _HeaderHook extends StatelessWidget {
  const _HeaderHook({required this.next});

  final AsyncValue<Game?> next;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String line = next.maybeWhen(
      data: (Game? g) {
        if (g == null) {
          return "It's the offseason — the Vault is always open.";
        }
        return 'The Cats play ${Fmt.weekday(g.startTime)} vs ${g.opponentName}.';
      },
      orElse: () => 'Loading the latest from Big Blue Nation…',
    );
    return Row(
      children: <Widget>[
        const Icon(Icons.bolt_rounded, size: 15, color: BgColors.goldBright),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            line,
            style: text.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Today's Gameday — a large hero tile → the Gameday tab.
// ---------------------------------------------------------------------------

class _GamedayHeroTile extends ConsumerWidget {
  const _GamedayHeroTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Game?> featured = ref.watch(featuredGameProvider);
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: featured.when(
        loading: () => const BgCard(
          child: SizedBox(height: 120, child: LoadingView()),
        ),
        error: (Object e, _) => const SizedBox.shrink(),
        data: (Game? game) {
          if (game == null) {
            return BgCard(
              onTap: () => context.go(Routes.gameday),
              child: Row(
                children: <Widget>[
                  Icon(Icons.stadium_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No game scheduled — explore Gameday HQ.',
                      style: text.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: BgColors.mist),
                ],
              ),
            );
          }
          return Column(
            children: <Widget>[
              _TileLabel(
                icon: Icons.stadium_rounded,
                label: "TODAY'S GAMEDAY",
                trailing: 'Open HQ',
              ),
              const SizedBox(height: 8),
              MatchupHero(
                game: game,
                onTap: () => context.go(Routes.gameday),
              ),
              const SizedBox(height: 10),
              CountdownStrip(
                target: game.startTime,
                label:
                    'Kickoff: Kentucky vs ${game.opponentName} (${Fmt.sportLabel(game.sport)})',
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Your Picks + Leaderboard — two tiles that surface Predictions.
// ---------------------------------------------------------------------------

class _PicksAndLeaderboardRow extends StatelessWidget {
  const _PicksAndLeaderboardRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: _YourPicksTile()),
            SizedBox(width: 12),
            Expanded(child: _LeaderboardTile()),
          ],
        ),
      ),
    );
  }
}

class _YourPicksTile extends ConsumerWidget {
  const _YourPicksTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppUser> user = ref.watch(currentUserProvider);
    final AsyncValue<List<Prediction>> open =
        ref.watch(openPredictionsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    final int openCount = open.maybeWhen(
      data: (List<Prediction> list) => list.length,
      orElse: () => 0,
    );
    final PredictionRecord? record = user.maybeWhen(
      data: (AppUser u) => u.predictionRecord,
      orElse: () => null,
    );

    return BgCard(
      onTap: () => context.push(Routes.predictions),
      gradient: BgColors.skyGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.task_alt_rounded,
                  size: 16, color: BgColors.goldBright),
              const SizedBox(width: 6),
              Text('YOUR PICKS', style: BgTypography.eyebrow(BgColors.goldBright)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                '$openCount',
                style: BgTypography.statNumber(Colors.white, size: 34),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  openCount == 1 ? 'pick open' : 'picks open',
                  style: text.bodySmall?.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            record == null
                ? 'Tap to play'
                : '${record.correct}–${record.total - record.correct} record · ${record.streak}🔥 streak',
            style: text.bodySmall?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends ConsumerWidget {
  const _LeaderboardTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppUser>> board = ref.watch(leaderboardProvider);
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    final Color accent = theme.colorScheme.primary;

    final ({int rank, int total})? standing = board.maybeWhen(
      data: (List<AppUser> users) {
        int rank = 0;
        for (int i = 0; i < users.length; i++) {
          if (users[i].id == AppConfig.demoUserId) {
            rank = i + 1;
            break;
          }
        }
        return (rank: rank, total: users.length);
      },
      orElse: () => null,
    );

    return BgCard(
      onTap: () => context.push(Routes.predictions),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.leaderboard_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text('LEADERBOARD', style: BgTypography.eyebrow(accent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                standing == null || standing.rank == 0
                    ? '—'
                    : '#${standing.rank}',
                style: BgTypography.statNumber(accent, size: 34),
              ),
              const SizedBox(width: 6),
              if (standing != null && standing.rank != 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'of ${standing.total}',
                    style: text.bodySmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your season rank in Big Blue Nation',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily Drop — stat-of-the-day, in the new tile style.
// ---------------------------------------------------------------------------

class _DailyDropSection extends ConsumerWidget {
  const _DailyDropSection();

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
            eyebrow: 'From Gameday Stats',
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

// ---------------------------------------------------------------------------
// Today's Poll.
// ---------------------------------------------------------------------------

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
                title: "Today's Poll",
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

// ---------------------------------------------------------------------------
// Feed — latest recap + trending news link cards.
// ---------------------------------------------------------------------------

class _FeedSection extends ConsumerWidget {
  const _FeedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NewsCard>> news = ref.watch(newsCardsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionHeader(
            title: 'The Feed',
            eyebrow: 'Around the program',
            padding: EdgeInsets.only(bottom: 10),
          ),
          news.when(
            loading: () => const BgCard(child: LoadingView()),
            error: (Object e, _) => const SizedBox.shrink(),
            data: (List<NewsCard> list) {
              if (list.isEmpty) {
                return const BgCard(child: EmptyView(title: 'No news yet'));
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

// ---------------------------------------------------------------------------
// Explore — the pillar tiles (Vault, Preps, Heritage*, The Porch*).
// ---------------------------------------------------------------------------

class _ExploreSection extends StatelessWidget {
  const _ExploreSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const <Widget>[
        SectionHeader(
          title: 'Explore',
          eyebrow: 'Everything Kentucky',
          padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(child: _VaultExploreTile()),
                SizedBox(width: 12),
                Expanded(child: _PrepsExploreTile()),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _ComingSoonTile(
                    icon: Icons.local_bar_rounded,
                    label: 'Kentucky Heritage',
                    blurb: 'Bourbon, horses & the 120 counties.',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _ComingSoonTile(
                    icon: Icons.forum_rounded,
                    label: 'The Porch',
                    blurb: 'Where Kentuckians talk.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VaultExploreTile extends ConsumerWidget {
  const _VaultExploreTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<VaultLegend>> legends =
        ref.watch(vaultLegendsProvider);
    final TextTheme text = Theme.of(context).textTheme;

    final String hook = legends.maybeWhen(
      data: (List<VaultLegend> list) =>
          list.isNotEmpty ? list.first.title : 'Eras, legends & 83 seasons.',
      orElse: () => 'Eras, legends & 83 seasons.',
    );

    return BgCard(
      onTap: () => context.go(Routes.vault),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[BgColors.blueDark, BgColors.deepBlue],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.lock_open_rounded,
              color: BgColors.goldBright, size: 22),
          const SizedBox(height: 10),
          Text('The Vault',
              style: text.titleLarge?.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            hook,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text('Open the archive',
                  style: BgTypography.eyebrow(BgColors.goldBright)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded,
                  size: 13, color: BgColors.goldBright),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrepsExploreTile extends ConsumerWidget {
  const _PrepsExploreTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<({HighSchoolGame game, HighSchool? school})>> rows =
        ref.watch(highSchoolGameRowsProvider);
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    final Color accent = theme.colorScheme.primary;

    final int games = rows.maybeWhen(
      data: (List<({HighSchoolGame game, HighSchool? school})> list) =>
          list.length,
      orElse: () => 0,
    );

    return BgCard(
      onTap: () => context.go(Routes.preps),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.school_rounded, color: accent, size: 22),
          const SizedBox(height: 10),
          Text('Bluegrass Preps', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(
            games > 0
                ? '$games on the Friday-night scoreboard.'
                : 'Kentucky high school scores & schools.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text('See the scoreboard', style: BgTypography.eyebrow(accent)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 13, color: accent),
            ],
          ),
        ],
      ),
    );
  }
}

/// A tasteful "coming soon" pillar tile so the hub scales to the vision.
class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({
    required this.icon,
    required this.label,
    required this.blurb,
  });

  final IconData icon;
  final String label;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    return BgCard(
      color: theme.colorScheme.surfaceContainerHighest,
      borderColor: theme.colorScheme.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 22),
          const SizedBox(height: 10),
          Text(label, style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            blurb,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall,
          ),
          const SizedBox(height: 8),
          Pill(
            label: 'COMING SOON',
            color: theme.colorScheme.onSurfaceVariant,
            background: theme.colorScheme.surface,
            dense: true,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small shared bits.
// ---------------------------------------------------------------------------

/// An eyebrow row used to label a bento tile group.
class _TileLabel extends StatelessWidget {
  const _TileLabel({
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: <Widget>[
        Container(
          width: 3,
          height: 18,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            gradient: BgColors.goldRule,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 6),
        Text(label, style: BgTypography.eyebrow(accent)),
        if (trailing != null) ...<Widget>[
          const Spacer(),
          Text(
            trailing!,
            style: BgTypography.eyebrow(
              Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: BgColors.mist),
        ],
      ],
    );
  }
}
