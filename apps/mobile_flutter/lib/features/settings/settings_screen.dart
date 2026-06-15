import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/config.dart';
import '../../core/models/models.dart';
import '../../core/providers/data_providers.dart';
import '../../core/providers/local_state.dart';
import '../../core/widgets/widgets.dart';

/// Settings — notification toggles (local), the independent-fan disclaimer,
/// data-source attribution, and app version.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotificationPrefs prefs = ref.watch(notificationPrefsProvider);
    final NotificationPrefsNotifier notifier =
        ref.read(notificationPrefsProvider.notifier);
    final AsyncValue<AppConfigDoc> config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          const SectionHeader(
            title: 'Notifications',
            eyebrow: 'Stay in the loop',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BgCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: <Widget>[
                  _ToggleRow(
                    title: 'Morning pulse',
                    subtitle: 'Your daily Big Blue briefing',
                    value: prefs.morningPulse,
                    onChanged: notifier.setMorningPulse,
                  ),
                  _divider(),
                  _ToggleRow(
                    title: 'Game starting soon',
                    subtitle: 'A nudge before kickoff/tipoff',
                    value: prefs.gameStartingSoon,
                    onChanged: notifier.setGameStartingSoon,
                  ),
                  _divider(),
                  _ToggleRow(
                    title: 'Prediction closing soon',
                    subtitle: 'Last call to lock in a pick',
                    value: prefs.predictionClosing,
                    onChanged: notifier.setPredictionClosing,
                  ),
                  _divider(),
                  _ToggleRow(
                    title: 'Final score & results',
                    subtitle: 'How your picks did',
                    value: prefs.finalScore,
                    onChanged: notifier.setFinalScore,
                  ),
                  _divider(),
                  _ToggleRow(
                    title: 'Badge earned',
                    subtitle: 'Celebrate new badges',
                    value: prefs.badgeEarned,
                    onChanged: notifier.setBadgeEarned,
                  ),
                  _divider(),
                  _ToggleRow(
                    title: 'High school alerts',
                    subtitle: 'Updates for schools you follow',
                    value: prefs.highSchoolAlerts,
                    onChanged: notifier.setHighSchoolAlerts,
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(
            title: 'About & Legal',
            eyebrow: 'The fine print',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _DisclaimerCard(config: config),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BgCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.dataset_rounded,
                          size: 18, color: BgColors.deepBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Data sources',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Demo statistics in this build are fictional (source: '
                    'seed_demo) and clearly labeled. Production stats come from '
                    'CollegeFootballData and CollegeBasketballData via secure '
                    'server-side sync; high school info links to KHSAA. Stats '
                    'are never blended without a confidence label.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const <Widget>[
                      Pill(label: 'CFBD', color: BgColors.deepBlue, dense: true),
                      Pill(label: 'CBBD', color: BgColors.deepBlue, dense: true),
                      Pill(label: 'KHSAA', color: BgColors.goldDark, dense: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BgCard(
              child: Row(
                children: <Widget>[
                  const BrandMark(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppConfig.appName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Version ${AppConfig.version} (build ${AppConfig.buildNumber})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Made by fans, for fans. Go Big Blue.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: BgColors.deepBlue,
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.config});

  final AsyncValue<AppConfigDoc> config;

  @override
  Widget build(BuildContext context) {
    final String disclaimer = config.maybeWhen(
      data: (AppConfigDoc c) => c.independentFanDisclaimer,
      orElse: () => '',
    );
    return BgCard(
      color: BgColors.blueTint,
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.gavel_rounded, size: 18, color: BgColors.deepBlue),
              const SizedBox(width: 8),
              Text(
                'Independent Fan Disclaimer',
                style: BgTypography.eyebrow(BgColors.deepBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            disclaimer.isEmpty
                ? 'Bluegrass Gameday is an independent fan and statistics app. '
                    'It is not affiliated with, endorsed by, or sponsored by '
                    'the University of Kentucky, UK Athletics, the NCAA, SEC, '
                    'or KHSAA.'
                : disclaimer,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
