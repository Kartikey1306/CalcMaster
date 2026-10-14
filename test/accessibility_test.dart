import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/app_router.dart';

import 'support/app_harness.dart';

/// Accessibility guarantees for the sheet and the screens around it.
///
/// Uses Flutter's own guideline matchers (tap-target size, rendered text
/// contrast, labelled tap targets) plus a large-text sweep. Text scaling is
/// the usual source of breakage: a RenderFlex overflow throws in debug, so
/// pumping at 2.0x turns "does it survive a user with large fonts?" into a
/// pass/fail question instead of a guess.
void main() {
  setUpApp();

  Future<void> expectGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  }

  group('tap targets, contrast and semantics', () {
    testWidgets('the empty first sheet meets platform guidelines',
        (tester) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp());
      await settle(tester);
      await expectGuidelines(tester);
      handle.dispose();
    });

    testWidgets('a worked sheet — results, captions, errors, the key row and '
        'the footer — meets platform guidelines', (tester) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp());
      await settle(tester);
      final field = find.byType(TextField);
      await tester.enterText(field.at(0), 'Shelf: 12 ft in m');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await settle(tester);
      await tester.enterText(find.byType(TextField).at(1), '50 AED in USD');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await settle(tester);
      await tester.enterText(find.byType(TextField).at(2), '#1 * 2');
      await tester.pump();
      // A line has focus, so the key row is showing.
      expect(find.bySemanticsLabel('Insert Plus'), findsOneWidget);
      // Every interactive control on the sheet is labelled.
      for (final label in [
        'Line 1',
        'Line 1 options',
        'Insert Plus',
        'Insert Minus',
        'Insert Multiply',
      ]) {
        expect(find.bySemanticsLabel(label), findsWidgets, reason: label);
      }
      expect(find.bySemanticsLabel(RegExp(r'^Line 1 result 3\.6576 m')),
          findsOneWidget);
      await expectGuidelines(tester);
      handle.dispose();
    });

    for (final route in ['/sheets', '/tools', '/settings', '/help']) {
      testWidgets('$route meets platform guidelines', (tester) async {
        phone(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(testApp());
        await settle(tester);
        appRouter.go(route);
        await settle(tester);
        await expectGuidelines(tester);
        handle.dispose();
        appRouter.go('/');
        await settle(tester);
      });
    }
  });

  group('large text does not break layout', () {
    // 2.0x is within what iOS and Android expose to users.
    for (final scale in <double>[1.3, 2.0]) {
      testWidgets('every destination survives ${scale}x text', (tester) async {
        phone(tester);
        textScale(tester, scale);
        await tester.pumpWidget(testApp());
        await settle(tester);
        expect(tester.takeException(), isNull,
            reason: 'the sheet overflowed at ${scale}x text');
        await tester.enterText(find.byType(TextField).first,
            'Dinner: 38.50 EUR on 14 Sep in USD');
        await tester.pump();
        expect(tester.takeException(), isNull,
            reason: 'a waiting currency line overflowed at ${scale}x');

        for (final route in [
          '/sheets',
          '/tools',
          '/tools/tip',
          '/tools/currency',
          '/tools/scientific',
          '/settings',
          '/help',
          '/about',
          '/privacy',
        ]) {
          appRouter.go(route);
          await settle(tester);
          expect(tester.takeException(), isNull,
              reason: '$route overflowed at ${scale}x text');
        }
        appRouter.go('/');
        await settle(tester);
      });
    }
  });
}
