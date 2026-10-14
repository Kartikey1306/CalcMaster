import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/app_router.dart';
import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:calcmaster/theme/app_theme.dart';
import 'package:calcmaster/widgets/calc_key.dart';
import 'package:calcmaster/widgets/number_input.dart';
import 'package:calcmaster/widgets/result_row.dart';

import 'support/app_harness.dart';

/// Screen-reader labels.
///
/// `test/accessibility_test.dart` proves the *shape* of the UI is accessible
/// (tap targets, contrast, every tappable thing is labelled). This file proves
/// the labels say something a blind user can act on: a keypad key announces
/// "Divide", not the glyph "÷"; a result row announces "Future value, $1,234"
/// as one phrase instead of two disconnected fragments; a sheet line announces
/// its number, its result and what a tap does.
void main() {
  setUpApp();

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
    testWidgets('the top bar actions are named', (tester) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp());
      await settle(tester);

      for (final label in ['Sheets', 'Tools', 'More']) {
        expect(find.byTooltip(label), findsOneWidget,
            reason: 'the $label action must be announced by name');
      }
      expect(find.bySemanticsLabel(RegExp(r'^Sheet title: ')), findsOneWidget,
          reason: 'the title says it is the sheet title and can be renamed');
      handle.dispose();
    });

    testWidgets('a sheet line reads as its number, result and what a tap '
        'does; the total reads as one phrase', (tester) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp());
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, '12 ft in m');
      await tester.pump();

      expect(find.bySemanticsLabel('Line 1'), findsWidgets);
      final result = tester.getSemantics(
          find.bySemanticsLabel(RegExp(r'^Line 1 result 3\.6576 m')));
      expect(result.hint,
          'Tap to insert #1 into the line you are editing. Long press to copy.');
      expect(find.bySemanticsLabel('Total, 3.6576 m'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an error line is announced with its reason', (tester) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp());
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, '3 kg in m');
      await tester.pump();
      expect(find.bySemanticsLabel("Line 1: Can't convert kg to m"),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('the region pill is named, not just a flag emoji',
        (tester) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp());
      await settle(tester);
      appRouter.go('/settings');
      await settle(tester);

      expect(
        find.bySemanticsLabel(RegExp(r'^Region: \w+, currency [A-Z]{3}$')),
        findsOneWidget,
      );
      handle.dispose();
      appRouter.go('/');
      await settle(tester);
    });
  });
}
