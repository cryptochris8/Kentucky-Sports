import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/typography.dart';
import '../../core/models/models.dart';
import '../../core/widgets/widgets.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Full-detail Gameday Story card for pregame (preview) and postgame (recap)
/// articles. Shows headline, opening narrative, tactical breakdown (if present),
/// By the Numbers bullets, player spotlights, verdict, and the AI attribution
/// footer. Hide the whole card when [article] is null.
class GamedayStoryCard extends StatefulWidget {
  const GamedayStoryCard({super.key, required this.article});

  final Article article;

  @override
  State<GamedayStoryCard> createState() => _GamedayStoryCardState();
}

class _GamedayStoryCardState extends State<GamedayStoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final Article a = widget.article;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final bool isRecap = a.isRecap;

    return BgCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header band.
          _ArticleHeader(article: a),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Headline.
                Text(a.headline, style: text.titleLarge),
                if (a.subheadline.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    a.subheadline,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Opening narrative.
                Text(a.openingNarrative, style: text.bodyMedium),

                // Tactical breakdown (preview only).
                if (!isRecap && a.tacticalBreakdown != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _NarrativeSection(section: a.tacticalBreakdown!),
                ],

                // By the Numbers.
                if (a.byTheNumbers != null &&
                    a.byTheNumbers!.items.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _ByTheNumbers(section: a.byTheNumbers!),
                ],

                // Expand/collapse player spotlights + verdict.
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    children: <Widget>[
                      Text(
                        _expanded ? 'Show less' : 'Read full story',
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: scheme.primary,
                        size: 18,
                      ),
                    ],
                  ),
                ),

                if (_expanded) ...<Widget>[
                  const SizedBox(height: 12),

                  // Player spotlights.
                  if (a.playerSpotlights.isNotEmpty) ...<Widget>[
                    _SectionLabel(
                      icon: Icons.person_pin_rounded,
                      label: 'Player Spotlights',
                    ),
                    const SizedBox(height: 8),
                    ...a.playerSpotlights.map(
                      (ArticlePlayerSpotlight p) =>
                          _PlayerSpotlightRow(spotlight: p),
                    ),
                  ],

                  // Verdict.
                  if (a.theVerdict != null) ...<Widget>[
                    const SizedBox(height: 12),
                    _VerdictSection(verdict: a.theVerdict!, isRecap: isRecap),
                  ],

                  // Closing line.
                  if (a.closingLine.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      '"${a.closingLine}"',
                      style: text.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),

          // AI attribution footer.
          _AiAttributionFooter(article: a),
        ],
      ),
    );
  }
}

/// Compact Stats Lab "Stat Story" tile that shows the opening narrative and
/// By the Numbers bullets for a game. Tap expands in-place.
class StatStoryTile extends StatefulWidget {
  const StatStoryTile({super.key, required this.article});

  final Article article;

  @override
  State<StatStoryTile> createState() => _StatStoryTileState();
}

class _StatStoryTileState extends State<StatStoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final Article a = widget.article;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextTheme text = theme.textTheme;

    return BgCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Label + chevron.
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'STAT STORY',
                      style: BgTypography.eyebrow(BgColors.bluegrassGold),
                    ),
                    Text(
                      a.headline,
                      style: text.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: BgColors.mist,
              ),
            ],
          ),

          if (_expanded) ...<Widget>[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Opening narrative.
            Text(a.openingNarrative, style: text.bodyMedium),

            // By the Numbers.
            if (a.byTheNumbers != null &&
                a.byTheNumbers!.items.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _ByTheNumbers(section: a.byTheNumbers!),
            ],

            const SizedBox(height: 12),
          ],

          const Divider(height: 20),
          _AiAttributionFooter(article: a, inline: true),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _ArticleHeader extends StatelessWidget {
  const _ArticleHeader({required this.article});

  final Article article;

  ({Color color, IconData icon, String label}) _type(ColorScheme scheme) {
    switch (article.type) {
      case 'recap':
        return (
          color: BgColors.positive,
          icon: Icons.emoji_events_rounded,
          label: 'GAME RECAP',
        );
      case 'stat_story':
        return (
          color: BgColors.info,
          icon: Icons.bar_chart_rounded,
          label: 'STAT STORY',
        );
      case 'preview':
      default:
        return (
          color: scheme.primary,
          icon: Icons.article_rounded,
          label: 'GAMEDAY STORY',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ({Color color, IconData icon, String label}) t =
        _type(Theme.of(context).colorScheme);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            t.color.withValues(alpha: 0.12),
            t.color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: <Widget>[
          Icon(t.icon, size: 15, color: t.color),
          const SizedBox(width: 6),
          Text(
            t.label,
            style: BgTypography.eyebrow(t.color),
          ),
          const Spacer(),
          Pill(
            label: 'Bluegrass Gameday AI',
            color: BgColors.bluegrassGold,
            icon: Icons.smart_toy_outlined,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _NarrativeSection extends StatelessWidget {
  const _NarrativeSection({required this.section});

  final ArticleNarrativeSection section;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.military_tech_rounded,
                size: 15,
                color: BgColors.bluegrassGold,
              ),
              const SizedBox(width: 6),
              Text(
                section.title.toUpperCase(),
                style: BgTypography.eyebrow(BgColors.goldDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(section.narrative, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _ByTheNumbers extends StatelessWidget {
  const _ByTheNumbers({required this.section});

  final ArticleListSection section;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionLabel(
          icon: Icons.format_list_numbered_rounded,
          label: section.title,
        ),
        const SizedBox(height: 8),
        ...section.items.asMap().entries.map(
          (MapEntry<int, String> entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: BgColors.goldGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: BgTypography.statNumber(
                        BgColors.blueDark,
                        size: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(entry.value, style: text.bodySmall),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerSpotlightRow extends StatelessWidget {
  const _PlayerSpotlightRow({required this.spotlight});

  final ArticlePlayerSpotlight spotlight;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: BgColors.heroGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                spotlight.position ?? '—',
                style: BgTypography.statNumber(Colors.white, size: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(spotlight.name, style: text.titleMedium),
                Text(spotlight.narrative, style: text.bodySmall),
                if (spotlight.statline != null &&
                    spotlight.statline!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    spotlight.statline!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: BgColors.mist,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictSection extends StatelessWidget {
  const _VerdictSection({
    required this.verdict,
    required this.isRecap,
  });

  final ArticleVerdict verdict;
  final bool isRecap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme text = theme.textTheme;
    final Color accentColor =
        isRecap ? BgColors.positive : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accentColor.withValues(alpha: 0.10),
            accentColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                isRecap ? Icons.flag_rounded : Icons.gavel_rounded,
                size: 16,
                color: accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                verdict.title.toUpperCase(),
                style: BgTypography.eyebrow(accentColor),
              ),
              if (!isRecap && verdict.confidence != null) ...<Widget>[
                const Spacer(),
                Pill(
                  label: '${verdict.confidence}% confidence',
                  color: accentColor,
                  dense: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (verdict.prediction != null) ...<Widget>[
            Text(
              verdict.prediction!,
              style: BgTypography.statNumber(accentColor, size: 18),
            ),
            const SizedBox(height: 6),
          ],
          if (verdict.result != null) ...<Widget>[
            Text(
              verdict.result!,
              style: BgTypography.statNumber(accentColor, size: 18),
            ),
            const SizedBox(height: 6),
          ],
          Text(verdict.narrative, style: text.bodySmall),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: accent),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: BgTypography.eyebrow(accent),
        ),
      ],
    );
  }
}

/// AI attribution footer — required on every article render per the hard rules.
class _AiAttributionFooter extends StatelessWidget {
  const _AiAttributionFooter({required this.article, this.inline = false});

  final Article article;
  final bool inline;

  /// The provenance line derives from the article's own confidence so the
  /// footer never overclaims its inputs (hard rule 6). The wording mirrors
  /// the pipeline's confidence tiers (demo / fan_rumor < researched <
  /// official) and [ConfidenceLabel]: only a truly 'official' article may
  /// say "official stats"; anything unrecognized falls back to a neutral
  /// claim rather than an inflated one.
  String get _attribution {
    switch (article.confidence.toLowerCase()) {
      case 'official':
      case 'verified':
        return 'Generated by Bluegrass Gameday AI from official stats';
      case 'researched':
        return 'Generated by Bluegrass Gameday AI from researched stats';
      case 'demo':
        return 'Generated by Bluegrass Gameday AI from demo stats';
      default:
        // fan_rumor + unknown tiers — neutral wording that never oversells.
        return 'Generated by Bluegrass Gameday AI from stored stats';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (inline) {
      return _inlineFooter(context);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.smart_toy_outlined,
                size: 13,
                color: BgColors.mist,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _attribution,
                  style: const TextStyle(
                    fontSize: 10,
                    color: BgColors.mist,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SourceConfidenceRow(
            source: article.sources.isNotEmpty
                ? article.sources.first
                : article.model,
            updatedAt: article.generatedAt,
            confidence: article.confidence,
          ),
        ],
      ),
    );
  }

  Widget _inlineFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.smart_toy_outlined, size: 12, color: BgColors.mist),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _attribution,
                style: const TextStyle(
                  fontSize: 10,
                  color: BgColors.mist,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SourceConfidenceRow(
          source: article.sources.isNotEmpty
              ? article.sources.first
              : article.model,
          updatedAt: article.generatedAt,
          confidence: article.confidence,
        ),
      ],
    );
  }
}
