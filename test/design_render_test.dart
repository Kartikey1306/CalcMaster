@Tags(['design'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/app_router.dart';
import 'package:calcmaster/lib_currency.dart';
import 'package:calcmaster/sheet/sheet_store.dart';
import 'package:calcmaster/state/region_provider.dart';

import 'support/app_harness.dart';

/// Renders real screens to PNGs under `test/goldens/` so the UI can be
/// inspected without a device:
///
///   flutter test --run-skipped --update-goldens --tags design
///
/// These are review artifacts, not assertions. `dart_test.yaml` marks the
/// `design` tag as skipped, so `flutter test` never runs them and a pixel diff
/// can never fail CI — hence the explicit `--run-skipped` above.
void main() {
  const phoneSize = Size(390, 844);

  setUpAll(() async {
    HttpOverrides.global = OfflineHttpOverrides();
    // Widget tests ship no fonts, so text would render as boxes. Load the
    // two bundled families the app actually uses.
    for (final family in ['GolosText', 'RedditMono']) {
      final loader = FontLoader(family);
      for (final w in [400, 500, 600, 700]) {
        final bytes = File('assets/fonts/$family-$w.ttf').readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
      await loader.load();
    }
    final icons = File(
        '${Platform.environment['FLUTTER_ROOT'] ?? '/Users/spatchava/agl/.flutter-sdk'}'
        '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')
            ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync()))))
          .load();
    }
  });
  tearDownAll(() => HttpOverrides.global = null);

  Map<String, Object> tripSheet({String? theme}) => {
        'region': 'US',
        if (theme != null) 'theme_mode': theme,
        SheetStore.kSheets: '[{"id":"trip","title":"Lisbon expenses",'
            '"createdAt":1,"updatedAt":2,"lines":['
            '{"text":"Trip to Lisbon"},'
            '{"text":"Dinner: 38.50 EUR on 14 Sep in USD"},'
            '{"text":"Hotel: 120 GBP on 2026-09-15 in USD"},'
            '{"text":"Ferry: 100 EUR on 2026-10-10 in USD"},'
            '{"text":"Taxi: 18 USD + 15%"},'
            '{"text":"Museum: 30 AED in USD"},'
            '{"text":"total"}]}]',
        SheetStore.kRateCache: '{'
            '"${datedRateKey('2026-09-14', 'EUR', 'USD')}":{"base":"EUR","quote":"USD","rate":1.1551,"date":"2026-09-14"},'
            '"${datedRateKey('2026-09-15', 'GBP', 'USD')}":{"base":"GBP","quote":"USD","rate":1.3524,"date":"2026-09-15"},'
            '"${datedRateKey('2026-10-10', 'EUR', 'USD')}":{"base":"EUR","quote":"USD","rate":1.1206,"date":"2026-10-09"}'
            '}',
      };

  Future<void> shoot(WidgetTester tester, String name,
      {Map<String, Object>? prefs, String? route}) async {
    SharedPreferences.setMockInitialValues(prefs ?? {});
    appRouter.go('/');
    tester.view.physicalSize = phoneSize * 2;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testApp(region: RegionProvider(client: offlineClient())));
    await settle(tester);
    if (route != null) {
      appRouter.go(route);
      await settle(tester);
    }
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    appRouter.go('/');
    await settle(tester);
  }

  testWidgets('first launch', (t) => shoot(t, '01_first_launch'));
  testWidgets('a worked sheet',
      (t) => shoot(t, '02_sheet', prefs: tripSheet()));
  testWidgets('tools drawer',
      (t) => shoot(t, '03_tools', prefs: tripSheet(), route: '/tools'));
  testWidgets('sheets list',
      (t) => shoot(t, '04_sheets', prefs: tripSheet(), route: '/sheets'));
  testWidgets('night ledger',
      (t) => shoot(t, '05_night', prefs: tripSheet(theme: 'dark')));
}
