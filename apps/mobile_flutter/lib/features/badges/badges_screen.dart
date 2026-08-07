// Hide Material's Badge widget so our Badge model name is unambiguous.
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/data_providers.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';

/// Badges — the full collectible grid, grouped by category, with earned vs
/// locked styling and rarity colors.
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Badge>> badges = ref.watch(badgesProvider);
    final AsyncValue<Set<String>> earned = ref.watch(myEarnedBadgeIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Badge Collection')),
      body: badges.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(message: '$e'),
        data: (List<Badge> all) {
          if (all.isEmpty) {
            return const EmptyView(title: 'No badges defined');
          }
          final Set<String> earnedIds = earned.maybeWhen(
            data: (Set<String> s) => s,
            orElse: () => <String>{},
          );
          final Map<String, List<Badge>> byCat = <String, List<Badge>>{};
          for (final Badge b in all) {
            byCat.putIfAbsent(b.category, () => <Badge>[]).add(b);
          }
          final List<String> cats = byCat.keys.toList()..sort();

          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: <Widget>[
              _ProgressBanner(
                earned: earnedIds.length,
                total: all.length,
              ),
              for (final String cat in cats) ...<Widget>[
                SectionHeader(
                  title: _categoryLabel(cat),
                  eyebrow:
                      '${byCat[cat]!.where((Badge b) => earnedIds.contains(b.id)).length}'
                      ' of ${byCat[cat]!.length}',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: byCat[cat]!.length,
                    itemBuilder: (BuildContext context, int i) {
                      final Badge b = byCat[cat]![i];
                      return _BadgeCard(
                        badge: b,
                        earned: earnedIds.contains(b.id),
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'prediction':
        return 'Prediction Badges';
      case 'stats':
        return 'Stats Badges';
      case 'gameday':
        return 'Gameday Badges';
      case 'high_school':
        return 'Bluegrass Pipeline';
      default:
        return Fmt.sportLabel(cat);
    }
  }
}

class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: BgColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: BgColors.goldGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: BgColors.blueDark, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'COLLECTION',
                  style: BgTypography.eyebrow(BgColors.goldBright),
                ),
                Text(
                  '$earned of $total earned',
                  style: BgTypography.statNumber(Colors.white, size: 22),
                ),
                const SizedBox(height: 8),
                MeterBar(
                  value: total == 0 ? 0 : earned / total,
                  color: BgColors.goldBright,
                  trackColor: Colors.white.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.earned});

  final Badge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final Color c = BgColors.rarity(badge.rarity);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: earned ? scheme.surface : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: earned ? c.withValues(alpha: 0.5) : scheme.outline,
            width: earned ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: earned
                        ? LinearGradient(
                            colors: <Color>[c.withValues(alpha: 0.85), c],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: earned ? null : scheme.outline,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    earned
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_outline_rounded,
                    color: earned ? Colors.white : scheme.onSurfaceVariant,
                    size: 30,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium?.copyWith(
                color: earned ? scheme.onSurface : scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Pill(
              label: badge.rarity.toUpperCase(),
              color: c,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final Color c = BgColors.rarity(badge.rarity);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: earned
                      ? LinearGradient(
                          colors: <Color>[c.withValues(alpha: 0.85), c])
                      : null,
                  color: earned ? null : scheme.outline,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  earned
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                  color: earned ? Colors.white : scheme.onSurfaceVariant,
                  size: 40,
                ),
              ),
              const SizedBox(height: 14),
              Text(badge.name,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Pill(label: badge.rarity.toUpperCase(), color: c),
              const SizedBox(height: 12),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      earned ? Icons.check_circle_rounded : Icons.flag_rounded,
                      size: 16,
                      color: earned ? BgColors.positive : scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        earned
                            ? 'Earned! Great work, Big Blue.'
                            : 'Goal: ${badge.criteriaThreshold} '
                                '${badge.criteriaType.replaceAll('_', ' ')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
