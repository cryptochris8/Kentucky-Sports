import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';

/// Bluegrass Pipeline — Kentucky high school sports. School/team level only:
/// followed schools, KHSAA link cards, and a Friday-night scoreboard. No DMs,
/// no individual minor rankings (safety per CLAUDE.md hard rules).
class PipelineScreen extends ConsumerWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluegrass Pipeline')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(highSchoolsProvider);
          ref.invalidate(highSchoolGamesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: const <Widget>[
            _SafetyBanner(),
            _FollowedSchools(),
            _FridayScoreboard(),
            _KhsaaLinks(),
          ],
        ),
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: BgCard(
        color: BgColors.blueTint,
        borderColor: Colors.transparent,
        child: Row(
          children: <Widget>[
            const Icon(Icons.shield_rounded, color: BgColors.deepBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'School and team coverage only. We focus on schedules, scores, '
                'and public KHSAA links — no direct messaging.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowedSchools extends ConsumerWidget {
  const _FollowedSchools();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HighSchool>> schools =
        ref.watch(highSchoolsProvider);
    final AsyncValue<AppUser> user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(
          title: 'Kentucky High Schools',
          eyebrow: 'Follow your school',
        ),
        schools.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: LoadingView(),
          ),
          error: (Object e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: ErrorView(message: '$e'),
          ),
          data: (List<HighSchool> list) {
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: EmptyView(title: 'No schools listed yet'),
              );
            }
            final Set<String> followed = user.maybeWhen(
              data: (AppUser u) => u.favoriteHighSchools.toSet(),
              orElse: () => <String>{},
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  for (final HighSchool s in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SchoolCard(
                        school: s,
                        following: followed.contains(s.id),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SchoolCard extends StatefulWidget {
  const _SchoolCard({required this.school, required this.following});

  final HighSchool school;
  final bool following;

  @override
  State<_SchoolCard> createState() => _SchoolCardState();
}

class _SchoolCardState extends State<_SchoolCard> {
  late bool _following = widget.following;

  @override
  Widget build(BuildContext context) {
    final HighSchool s = widget.school;
    final TextTheme text = Theme.of(context).textTheme;
    return BgCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BgColors.blueTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: BgColors.deepBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(s.name, style: text.titleMedium),
                Text(
                  '${s.city}, ${s.state} · ${s.sports.length} sports',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              setState(() => _following = !_following);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      _following
                          ? 'Following ${s.name} · +5 XP'
                          : 'Unfollowed ${s.name}',
                    ),
                  ),
                );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: _following ? BgColors.deepBlue : null,
              foregroundColor: _following ? Colors.white : BgColors.deepBlue,
            ),
            child: Text(_following ? 'Following' : 'Follow'),
          ),
        ],
      ),
    );
  }
}

class _FridayScoreboard extends ConsumerWidget {
  const _FridayScoreboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<({HighSchoolGame game, HighSchool? school})>> rows =
        ref.watch(highSchoolGameRowsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(
          title: 'Friday Night Scoreboard',
          eyebrow: 'Across the Commonwealth',
        ),
        rows.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: LoadingView(),
          ),
          error: (Object e, _) => const SizedBox.shrink(),
          data: (List<({HighSchoolGame game, HighSchool? school})> list) {
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: EmptyView(
                  title: 'No games this week',
                  icon: Icons.sports_football_outlined,
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  for (final ({HighSchoolGame game, HighSchool? school}) r
                      in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HsGameRow(row: r),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HsGameRow extends StatelessWidget {
  const _HsGameRow({required this.row});

  final ({HighSchoolGame game, HighSchool? school}) row;

  @override
  Widget build(BuildContext context) {
    final HighSchoolGame g = row.game;
    final String schoolName = row.school?.name ?? 'School';
    final TextTheme text = Theme.of(context).textTheme;
    final bool isFinal = g.status == 'final';

    return BgCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 44,
            child: Column(
              children: <Widget>[
                Icon(
                  g.sport == 'football'
                      ? Icons.sports_football_rounded
                      : Icons.sports_basketball_rounded,
                  color: BgColors.deepBlue,
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  Fmt.shortDay(g.startTime),
                  style: text.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(schoolName, style: text.titleMedium),
                Text('vs ${g.opponent}', style: text.bodySmall),
              ],
            ),
          ),
          if (isFinal)
            Text(
              '${g.schoolScore} - ${g.opponentScore}',
              style: BgTypography.statNumber(BgColors.deepBlue, size: 18),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(Fmt.time(g.startTime), style: text.bodySmall),
                Pill(label: 'Scheduled', color: BgColors.blueBright, dense: true),
              ],
            ),
        ],
      ),
    );
  }
}

class _KhsaaLinks extends ConsumerWidget {
  const _KhsaaLinks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<NewsCard>> news = ref.watch(newsCardsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(
          title: 'KHSAA & Local Links',
          eyebrow: 'Official sources',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BgCard(
            onTap: () => _open(context, 'https://khsaa.org/'),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: BgColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.link_rounded,
                      color: BgColors.blueDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('KHSAA.org',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        'Official schedules, brackets, and stat leaders.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new_rounded, color: BgColors.mist),
              ],
            ),
          ),
        ),
        news.maybeWhen(
          data: (List<NewsCard> list) {
            final List<NewsCard> hs = list
                .where((NewsCard c) => c.sport == 'high_school')
                .toList();
            if (hs.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: <Widget>[
                  for (final NewsCard c in hs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LinkCard(card: c),
                    ),
                ],
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _open(BuildContext context, String url) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Opens at source: $url')));
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.card});

  final NewsCard card;

  @override
  Widget build(BuildContext context) {
    return BgCard(
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Opens at source: ${card.url}')));
      },
      child: Row(
        children: <Widget>[
          const Icon(Icons.article_outlined, color: BgColors.deepBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(card.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text('${card.sourceName} · ${Fmt.shortDay(card.publishedAt)}',
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, color: BgColors.mist),
        ],
      ),
    );
  }
}
