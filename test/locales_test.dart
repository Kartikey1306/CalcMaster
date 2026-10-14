import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:calcmaster/screens/tools/tools_drawer.dart';
import 'package:calcmaster/state/region_provider.dart';
import 'package:calcmaster/theme/app_theme.dart';

import 'support/app_harness.dart';

/// Boot the Tools drawer in each of the 12 supported locales and assert that
/// the locale's translated heading is rendered. Detects regressions where an
/// ARB key is missing or a widget bypasses AppLocalizations.
Widget wrap(Locale locale) {
  return ChangeNotifierProvider(
    create: (_) => RegionProvider(client: offlineClient()),
    child: MaterialApp(
      theme: buildAppTheme(),
      home: const ToolsDrawer(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUpApp();

  // Per-locale Tools heading. These mirror `toolsTitle` in each
  // lib/l10n/app_<lang>.arb file.
  const headings = <String, String>{
    'en': 'Tools',
    'es': 'Herramientas',
    'zh': '工具',
    'hi': 'टूल',
    'fr': 'Outils',
    'ar': 'الأدوات',
    'de': 'Werkzeuge',
    'ja': 'ツール',
    'pt': 'Ferramentas',
    'it': 'Strumenti',
    'ko': '도구',
    'ru': 'Инструменты',
  };

  for (final entry in headings.entries) {
    final code = entry.key;
    final expected = entry.value;
    testWidgets('Tools drawer renders in $code locale', (tester) async {
      await tester.pumpWidget(wrap(Locale(code)));
      await tester.pumpAndSettle();
      expect(find.text(expected), findsWidgets,
          reason: 'Expected heading "$expected" for locale "$code"');
    });
  }

  testWidgets('All 12 locales registered as supported', (tester) async {
    final codes =
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    expect(
        codes,
        containsAll([
          'en', 'es', 'zh', 'hi', 'fr', 'ar', 'de', 'ja', 'pt', 'ko', 'ru', 'it'
        ]));
    expect(AppLocalizations.supportedLocales.length, equals(12));
  });

  testWidgets('Arabic forces RTL textDirection', (tester) async {
    await tester.pumpWidget(wrap(const Locale('ar')));
    await tester.pumpAndSettle();
    final dir = Directionality.of(tester.element(find.byType(ToolsDrawer)));
    expect(dir, equals(TextDirection.rtl));
  });

  testWidgets('English uses LTR textDirection', (tester) async {
    await tester.pumpWidget(wrap(const Locale('en')));
    await tester.pumpAndSettle();
    final dir = Directionality.of(tester.element(find.byType(ToolsDrawer)));
    expect(dir, equals(TextDirection.ltr));
  });

  test('every locale translates the sheet, tools and settings strings',
      () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    for (final code in headings.keys) {
      final loc = await AppLocalizations.delegate.load(Locale(code));
      final pairs = <String, (String, String)>{
        'sheetsEmpty': (loc.sheetsEmpty, english.sheetsEmpty),
        'sheetAddToSheet': (loc.sheetAddToSheet, english.sheetAddToSheet),
        'sheetShareText': (loc.sheetShareText, english.sheetShareText),
        'toolsGroupMoney': (loc.toolsGroupMoney, english.toolsGroupMoney),
        'settingsRatesBody': (loc.settingsRatesBody(3), english.settingsRatesBody(3)),
        'helpHowLinesWork': (loc.helpHowLinesWork, english.helpHowLinesWork),
        'aboutBlurb': (loc.aboutBlurb, english.aboutBlurb),
        'privacyAtGlance': (loc.privacyAtGlance, english.privacyAtGlance),
        'labelFilingStatus': (loc.labelFilingStatus, english.labelFilingStatus),
      };
      pairs.forEach((key, v) {
        expect(v.$1, isNotEmpty, reason: '$key is empty for $code');
        if (code != 'en') {
          expect(v.$1, isNot(equals(v.$2)),
              reason: '$key in $code is still the English text');
        }
      });
      expect(loc.sheetRatesAsOf('9 Oct 2026'), contains('9 Oct 2026'));
    }
  });
}
