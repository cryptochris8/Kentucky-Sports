// Hide Material's Badge widget so our Badge model name is unambiguous.
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stats_engine/stats_engine.dart';

import '../../app/router.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/providers/local_state.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';

/// Profile — XP/level, prediction record, earned badges, and followed teams.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppUser> user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: user.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(message: '$e'),
        data: (AppUser u) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: <Widget>[
            _ProfileHeader(user: u),
            const SizedBox(height: 16),
            _PredictionRecordCard(user: u),
            const SizedBox(height: 16),
            _EarnedBadges(),
            const SizedBox(height: 16),
            _FollowedTeams(user: u),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int sessionXp = ref.watch(sessionXpProvider);
    final int totalXp = user.xp + sessionXp;
    final LevelInfo info = levelInfoForXp(totalXp);
    final TextTheme text = Theme.of(context).textTheme;

    return BgCard(
      gradient: BgColors.heroGradient,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: BgTypography.statNumber(Colors.white, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.displayName,
                      style: BgTypography.statNumber(Colors.white, size: 24),
                    ),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: BgColors.goldGradient,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'LVL ${info.level}',
                            style: BgTypography.eyebrow(BgColors.blueDark)
                                .copyWith(fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            info.name,
                            style: text.titleMedium
                                ?.copyWith(color: BgColors.goldBright),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MeterBar(
            value: info.progress,
            color: BgColors.goldBright,
            trackColor: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${Fmt.number(totalXp)} XP',
                style: text.bodySmall?.copyWith(color: Colors.white),
              ),
              Text(
                info.xpRemaining > 0
                    ? '${Fmt.number(info.xpRemaining)} to ${levelName(info.level + 1)}'
                    : 'Max level',
                style: text.bodySmall
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PredictionRecordCard extends StatelessWidget {
  const _PredictionRecordCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final PredictionRecord r = user.predictionRecord;
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(
          title: 'Prediction Record',
          padding: EdgeInsets.only(bottom: 10),
        ),
        BgCard(
          child: Row(
            children: <Widget>[
              Expanded(
                child: _RecordStat(
                  value: '${r.correct}/${r.total}',
                  label: 'Correct',
                  color: BgColors.deepBlue,
                ),
              ),
              _vDivider(),
              Expanded(
                child: _RecordStat(
                  value: Fmt.percent(r.accuracy),
                  label: 'Accuracy',
                  color: BgColors.positive,
                ),
              ),
              _vDivider(),
              Expanded(
                child: _RecordStat(
                  value: '${r.streak}',
                  label: 'Streak',
                  color: BgColors.goldDark,
                  icon: r.streak > 0 ? Icons.local_fire_department_rounded : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Make more picks in the Prediction Center to build your record.',
          style: text.bodySmall,
        ),
      ],
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 40,
        color: BgColors.hairline,
      );
}

class _RecordStat extends StatelessWidget {
  const _RecordStat({
    required this.value,
    required this.label,
    required this.color,
    this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 2),
            ],
            Text(value, style: BgTypography.statNumber(color, size: 24)),
          ],
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _EarnedBadges extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Badge>> badges = ref.watch(badgesProvider);
    final AsyncValue<Set<String>> earned = ref.watch(myEarnedBadgeIdsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: 'My Badges',
          padding: const EdgeInsets.only(bottom: 10),
          trailing: TextButton(
            onPressed: () => context.push(Routes.badges),
            child: const Text('See all'),
          ),
        ),
        badges.when(
          loading: () => const BgCard(child: LoadingView()),
          error: (Object e, _) => const SizedBox.shrink(),
          data: (List<Badge> all) {
            final Set<String> ids = earned.maybeWhen(
              data: (Set<String> s) => s,
              orElse: () => <String>{},
            );
            final List<Badge> mine =
                all.where((Badge b) => ids.contains(b.id)).toList();
            if (mine.isEmpty) {
              return const EmptyView(
                title: 'No badges yet',
                subtitle: 'Earn your first badge by making a prediction.',
                icon: Icons.workspace_premium_outlined,
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (final Badge b in mine) _EarnedBadgeChip(badge: b),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EarnedBadgeChip extends StatelessWidget {
  const _EarnedBadgeChip({required this.badge});

  final Badge badge;

  @override
  Widget build(BuildContext context) {
    final Color c = BgColors.rarity(badge.rarity);
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BgColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[c.withValues(alpha: 0.85), c],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.workspace_premium_rounded, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BgColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowedTeams extends ConsumerWidget {
  const _FollowedTeams({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Team>> teams = ref.watch(teamsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(
          title: 'Followed Teams',
          padding: EdgeInsets.only(bottom: 10),
        ),
        teams.when(
          loading: () => const BgCard(child: LoadingView()),
          error: (Object e, _) => const SizedBox.shrink(),
          data: (List<Team> all) {
            // Show Kentucky teams whose sport is in the user's favorites.
            final List<Team> followed = all
                .where((Team t) => user.favoriteSports.contains(t.sport))
                .toList();
            final List<Team> show = followed.isEmpty ? all : followed;
            return Column(
              children: <Widget>[
                for (final Team t in show)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BgCard(
                      onTap: () => context.push(Routes.team(t.id)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: <Widget>[
                          const BrandMark(size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${t.school} ${t.nickname}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  '${Fmt.sportLabel(t.sport)} · ${t.conference}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: BgColors.mist),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
