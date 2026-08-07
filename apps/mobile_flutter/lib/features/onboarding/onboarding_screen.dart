import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/providers/data_providers.dart';
import '../../core/providers/local_state.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/widgets.dart';

/// Lightweight onboarding: welcome, pick favorite sports, disclaimer, and a
/// "continue as guest" CTA. No account required (guest-first).
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const List<({String key, IconData icon})> _sports =
      <({String key, IconData icon})>[
    (key: 'football', icon: Icons.sports_football_rounded),
    (key: 'mens_basketball', icon: Icons.sports_basketball_rounded),
    (key: 'womens_basketball', icon: Icons.sports_basketball_outlined),
    (key: 'baseball', icon: Icons.sports_baseball_rounded),
    (key: 'volleyball', icon: Icons.sports_volleyball_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> selected = ref.watch(favoriteSportsProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: BgColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 28),
              const BrandWordmark(onDark: true, markSize: 52),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'Your independent home for Kentucky stats, predictions, and gameday.',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 18, 14, 0),
                  // Theme surface (not a literal light token) so the sheet and
                  // its theme-colored text stay legible in dark mode too.
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    children: <Widget>[
                      Text('Pick your sports', style: text.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        'We will tailor your Home feed and predictions. You can change this anytime.',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          for (final ({String key, IconData icon}) s in _sports)
                            _SportChip(
                              label: Fmt.sportLabel(s.key),
                              icon: s.icon,
                              selected: selected.contains(s.key),
                              onTap: () => ref
                                  .read(favoriteSportsProvider.notifier)
                                  .toggle(s.key),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _DisclaimerCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Container(
                color: scheme.surface,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: selected.isEmpty
                              ? null
                              : () {
                                  ref
                                      .read(onboardingCompleteProvider.notifier)
                                      .complete();
                                  context.go(Routes.home);
                                },
                          child: const Text('Continue as guest'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No account needed. Predictions are free-to-play.',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SportChip extends StatelessWidget {
  const _SportChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
              width: 1.4,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: selected ? scheme.onPrimary : scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              if (selected) ...<Widget>[
                const SizedBox(width: 6),
                Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DisclaimerCard extends ConsumerWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<dynamic> config = ref.watch(appConfigProvider);
    final String disclaimer = config.maybeWhen(
      data: (dynamic c) => (c.independentFanDisclaimer as String?) ?? '',
      orElse: () => '',
    );
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return BgCard(
      color: scheme.surfaceContainerHighest,
      borderColor: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Independent fan app',
                  style: BgTypography.eyebrow(scheme.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  disclaimer.isEmpty
                      ? 'Bluegrass Gameday is an independent fan and statistics app.'
                      : disclaimer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
