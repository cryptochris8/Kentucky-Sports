// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluegrass_gameday/core/models/models.dart';
import 'package:bluegrass_gameday/core/providers/vault_providers.dart';
import 'package:bluegrass_gameday/features/vault/vault_screen.dart';

// ---------------------------------------------------------------------------
// Minimal JSON fixtures (match real asset shapes)
// ---------------------------------------------------------------------------

const Map<String, dynamic> _footballSeasonJson = <String, dynamic>{
  'id': 'fb_2025',
  'sport': 'football',
  'season': 2025,
  'seasonLabel': '2025',
  'conference': 'SEC',
  'wins': 5,
  'losses': 7,
  'record': '5-7',
  'conferenceRecord': '2-6',
  'source': 'cfbd',
  'confidence': 'official',
  'updatedAt': '2026-06-16T14:41:16.035Z',
};

const Map<String, dynamic> _bballSeasonJson = <String, dynamic>{
  'id': 'bb_2024_25',
  'sport': 'mens_basketball',
  'season': 2024,
  'seasonLabel': '2024-25',
  'conference': 'SEC',
  'wins': 22,
  'losses': 14,
  'record': '22-14',
  'source': 'cbbd',
  'confidence': 'official',
  'updatedAt': '2026-06-16T14:41:16.035Z',
};

const Map<String, dynamic> _legendJson = <String, dynamic>{
  'id': 'legend_rupp',
  'type': 'legend',
  'subject': 'Adolph Rupp',
  'sport': 'mens_basketball',
  'era': '1930-1972',
  'title': 'The Baron of the Bluegrass',
  'subtitle': 'How Adolph Rupp built college basketball\'s winningest empire',
  'sections': <dynamic>[
    <String, dynamic>{
      'heading': 'Four Decades, One Standard',
      'body': 'From 1930 to 1972, Adolph Rupp didn\'t just coach Kentucky basketball — he defined it.',
    },
  ],
  'byTheNumbers': <String>['876-190 career record (.822)'],
  'pullQuote': 'The Baron of the Bluegrass turned a regional program into a national measuring stick.',
  'closingLine': 'From the Fabulous Five to the building that bears his name.',
  'sources': <String>['https://en.wikipedia.org/wiki/Adolph_Rupp'],
  'model': 'claude-opus-4-8',
  'status': 'draft',
  'confidence': 'researched',
  'generatedAt': '2026-06-16T16:46:02.445Z',
};

// ---------------------------------------------------------------------------
// Unit tests — VaultSeason.fromJson
// ---------------------------------------------------------------------------

void main() {
  group('VaultSeason.fromJson', () {
    test('parses a football season correctly', () {
      final VaultSeason s = VaultSeason.fromJson(_footballSeasonJson);
      expect(s.id, 'fb_2025');
      expect(s.sport, 'football');
      expect(s.season, 2025);
      expect(s.seasonLabel, '2025');
      expect(s.record, '5-7');
      expect(s.wins, 5);
      expect(s.losses, 7);
      expect(s.ties, isNull);
      expect(s.conference, 'SEC');
      expect(s.conferenceRecord, '2-6');
      expect(s.source, 'cfbd');
      expect(s.confidence, 'official');
      expect(s.updatedAt, isNotNull);
    });

    test('parses a basketball season without conferenceRecord', () {
      final VaultSeason s = VaultSeason.fromJson(_bballSeasonJson);
      expect(s.id, 'bb_2024_25');
      expect(s.sport, 'mens_basketball');
      expect(s.season, 2024);
      expect(s.record, '22-14');
      expect(s.conferenceRecord, isNull);
    });

    test('tolerates missing optional fields gracefully', () {
      final VaultSeason s = VaultSeason.fromJson(<String, dynamic>{
        'id': 'fb_minimal',
        'sport': 'football',
        'season': 2000,
        'seasonLabel': '2000',
        'conference': 'SEC',
        'record': '7-5',
        'source': 'cfbd',
      });
      expect(s.wins, isNull);
      expect(s.losses, isNull);
      expect(s.ties, isNull);
      expect(s.conferenceRecord, isNull);
      expect(s.updatedAt, isNull);
      expect(s.confidence, 'official'); // default
    });
  });

  // ---------------------------------------------------------------------------
  // Unit tests — VaultLegend.fromJson
  // ---------------------------------------------------------------------------

  group('VaultLegend.fromJson', () {
    test('parses the Rupp legend correctly', () {
      final VaultLegend l = VaultLegend.fromJson(_legendJson);
      expect(l.id, 'legend_rupp');
      expect(l.type, 'legend');
      expect(l.subject, 'Adolph Rupp');
      expect(l.sport, 'mens_basketball');
      expect(l.era, '1930-1972');
      expect(l.title, 'The Baron of the Bluegrass');
      expect(l.isDraft, isTrue);
      expect(l.sections.length, 1);
      expect(l.sections.first.heading, 'Four Decades, One Standard');
      expect(l.byTheNumbers.length, 1);
      expect(l.pullQuote, isNotEmpty);
      expect(l.closingLine, isNotEmpty);
      expect(l.sources.length, 1);
      expect(l.model, 'claude-opus-4-8');
      expect(l.confidence, 'researched');
      expect(l.generatedAt, isNotNull);
    });

    test('VaultLegendSection parses heading and body', () {
      final VaultLegendSection section = VaultLegendSection.fromJson(
        _legendJson['sections'][0] as Map<String, dynamic>,
      );
      expect(section.heading, 'Four Decades, One Standard');
      expect(section.body, contains('1930 to 1972'));
    });

    test('isDraft returns false when status is published', () {
      final Map<String, dynamic> json =
          Map<String, dynamic>.from(_legendJson)..['status'] = 'published';
      final VaultLegend l = VaultLegend.fromJson(json);
      expect(l.isDraft, isFalse);
    });

    test('parses real vault_legends.json asset', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final String raw = await rootBundle
          .loadString('assets/vault/vault_legends.json');
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic> list = decoded['vault_legends'] as List<dynamic>;
      expect(list.isNotEmpty, isTrue);
      final VaultLegend rupp =
          VaultLegend.fromJson(list.first as Map<String, dynamic>);
      expect(rupp.title, 'The Baron of the Bluegrass');
      expect(rupp.sections.isNotEmpty, isTrue);
    });

    test('parses all 83 seasons from real vault_seasons.json asset', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final String raw = await rootBundle
          .loadString('assets/vault/vault_seasons.json');
      final Map<String, dynamic> decoded =
          jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic> list = decoded['vault_seasons'] as List<dynamic>;
      // The asset has 83 real season records.
      expect(list.length, greaterThanOrEqualTo(80));
      final List<VaultSeason> seasons = list
          .whereType<Map<String, dynamic>>()
          .map(VaultSeason.fromJson)
          .toList();
      expect(seasons.every((VaultSeason s) => s.id.isNotEmpty), isTrue);
      expect(seasons.every((VaultSeason s) => s.record.isNotEmpty), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Widget test — VaultScreen renders season rows + Rupp legend card
  // ---------------------------------------------------------------------------

  group('VaultScreen widget', () {
    testWidgets('renders season timeline and Rupp legend title', (WidgetTester tester) async {
      // Minimal asset bundle setup so FutureProviders resolve from real files.
      TestWidgetsFlutterBinding.ensureInitialized();

      // Provide stub data via overrides to avoid asset loading in widget tests.
      final Map<String, dynamic> seasonsPayload = <String, dynamic>{
        '_meta': <String, dynamic>{},
        'vault_seasons': <dynamic>[_footballSeasonJson, _bballSeasonJson],
      };
      final Map<String, dynamic> legendsPayload = <String, dynamic>{
        '_meta': <String, dynamic>{},
        'vault_legends': <dynamic>[_legendJson],
      };

      // Override providers with stubbed futures.
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          vaultSeasonsProvider.overrideWith(
            (Ref ref) async => (seasonsPayload['vault_seasons'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .map(VaultSeason.fromJson)
                .toList(),
          ),
          vaultLegendsProvider.overrideWith(
            (Ref ref) async => (legendsPayload['vault_legends'] as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .map(VaultLegend.fromJson)
                .toList(),
          ),
          vaultSeasonsBySportProvider('football').overrideWith(
            (Ref ref) async => <VaultSeason>[VaultSeason.fromJson(_footballSeasonJson)],
          ),
          vaultSeasonsBySportProvider('mens_basketball').overrideWith(
            (Ref ref) async => <VaultSeason>[VaultSeason.fromJson(_bballSeasonJson)],
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VaultScreen()),
        ),
      );

      // Pump to resolve futures.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Screen title visible
      expect(find.text('THE VAULT'), findsOneWidget);

      // Rupp legend card title visible
      expect(find.text('The Baron of the Bluegrass'), findsOneWidget);

      // Season record row visible (football is default)
      expect(find.text('5-7'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
    });
  });
}
