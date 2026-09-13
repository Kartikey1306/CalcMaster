import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/app_router.dart';
import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:calcmaster/monetization/premium_provider.dart';
import 'package:calcmaster/state/notes_provider.dart';
import 'package:calcmaster/state/region_provider.dart';
import 'package:calcmaster/theme/app_theme.dart';
import 'package:calcmaster/widgets/calc_key.dart';
import 'package:calcmaster/widgets/hub_tile.dart';
import 'package:calcmaster/widgets/number_input.dart';
import 'package:calcmaster/widgets/result_row.dart';
import 'package:calcmaster/widgets/rich_hub_card.dart';

/// Screen-reader labels.
///
/// `test/accessibility_test.dart` proves the *shape* of the UI is accessible
/// (tap targets, contrast, every tappable thing is labelled). This file proves
/// the labels say something a blind user can act on: a keypad key announces
/// "Divide", not the glyph "÷"; a result row announces "Future value, $1,234"
/// as one phrase instead of two disconnected fragments.
///
/// See `accessibility_test.dart` for why sockets are blocked here.
class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw const SocketException('network disabled in tests');
}

void main() {
  setUpAll(() => HttpOverrides.global = _OfflineHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget host(Widget child) => MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Center(child: child)),
      );

  group('CalcKey.spokenName', () {
    test('maps every bare glyph on the keypad to a word', () {
      const cases = {
        'AC': 'All clear',
        '⌫': 'Backspace',
        '+/−': 'Toggle sign',
        '%': 'Percent',
        '÷': 'Divide',
        '×': 'Multiply',
        '−': 'Minus',
        '+': 'Plus',
        '=': 'Equals',
        '.': 'Decimal point',
      };
      cases.forEach((glyph, spoken) {
        expect(CalcKey.spokenName(glyph, null), spoken,
            reason: '$glyph must not be read out as punctuation');
      });
    });

    test('digits and words pass through unchanged', () {
      expect(CalcKey.spokenName('7', null), '7');
      expect(CalcKey.spokenName('sin', null), 'sin');
    });

    test('an explicit semanticLabel wins over the glyph', () {
      // Icon-only keys carry no label at all; the call site passes the glyph
      // through semanticLabel instead.
      expect(CalcKey.spokenName(null, '⌫'), 'Backspace');
      expect(CalcKey.spokenName(null, null), '');
    });
  });

  group('widget semantics', () {
    testWidgets('an icon-only key is still named', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(CalcKey(
        icon: Icons.backspace_outlined,
        semanticLabel: '⌫',
        kind: CalcKeyKind.function,
        size: 64,
        onTap: () {},
      )));

      expect(find.bySemanticsLabel('Backspace'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the calculator readout is a named live region',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const CalcDisplay(
        expression: '12 × 4',
        value: '48',
        maxWidth: 300,
      )));

      final node = tester.getSemantics(find.byType(CalcDisplay));
      expect(node.label, 'Result for 12 × 4');
      expect(node.value, '48');
      handle.dispose();
    });

    testWidgets('a result row reads as one label-and-value phrase',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const ResultRow(
        label: 'Future value',
        value: r'$1,234.00',
      )));

      expect(find.bySemanticsLabel(r'Future value, $1,234.00'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a hub tile announces its title and description',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(HubTile(
        title: 'Mortgage',
        description: 'Monthly payment',
        icon: Icons.home,
        iconColor: Colors.amber,
        onTap: () {},
      )));

      expect(
          find.bySemanticsLabel('Mortgage, Monthly payment'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a rich hub card announces its title and subtitle',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(RichHubCard(
        title: 'Aspect ratio',
        subtitle: 'Solve missing W or H',
        svgPath: 'assets/icons/scientific.svg',
        accent: Colors.amber,
        onTap: () {},
      )));

      expect(find.bySemanticsLabel('Aspect ratio, Solve missing W or H'),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('a number input names its field and its unit', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(NumberInput(
        label: 'Principal',
        unitSymbol: 'USD',
        controller: TextEditingController(),
      )));

      expect(find.bySemanticsLabel('Principal in USD'), findsOneWidget);
      handle.dispose();
    });
  });

  group('the running app', () {
    Widget buildApp() => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RegionProvider()),
            ChangeNotifierProvider(create: (_) => NotesProvider()),
            ChangeNotifierProvider(create: (_) => PremiumProvider()),
          ],
          child: MaterialApp.router(
            theme: buildAppTheme(),
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        );

    testWidgets('the bottom nav exposes selected tabs by name', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      for (final label in ['Convert', 'Calculate', 'Finance', 'Tools']) {
        expect(find.bySemanticsLabel(label), findsWidgets,
            reason: 'the $label tab must be announced by name');
      }

      // The tab you are on has to be distinguishable from the ones you are not.
      final navItems = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.inMutuallyExclusiveGroup ?? false)
          .toList();
      expect(navItems.map((s) => s.properties.label),
          containsAll(<String>['Convert', 'Calculate']));
      final selected =
          navItems.where((s) => s.properties.selected ?? false).toList();
      expect(selected.length, 1, reason: 'exactly one tab is current');
      expect(selected.single.properties.label, 'Convert');

      handle.dispose();
    });

    testWidgets('the region pill is named, not just a flag emoji',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildApp());
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(
        find.bySemanticsLabel('Region: US, currency USD'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
