import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:calcmaster/screens/calculate/calculate_screens.dart';
import 'package:calcmaster/widgets/calc_key.dart';

/// The keypad is a full-height phone layout, so pump it in a phone-shaped
/// window rather than the 800×600 test default — a tall one, because the
/// Scientific tool has five rows of function keys above the main keypad.
Future<void> _pumpCalc(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 1100);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: child,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  ));
  await tester.pumpAndSettle();
}

/// Taps a keypad key by label — scoped to the keypad so a readout showing the
/// same glyph (`0`, `1`…) doesn't make the finder ambiguous.
Future<void> _tapKey(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
    of: find.byType(CalcKeypad),
    matching: find.text(label),
  ));
  await tester.pumpAndSettle();
}

void main() {
  // The standalone Standard calculator (an iOS Calculator look-alike) was
// removed: the sheet replaces it. Its keypad behaviour lives on in
// KeypadCalcState, which the Scientific tool and the unit converters use, so
// these cases now drive the Scientific tool's main keypad — same keys, same
// assertions.
  group('Scientific · display + keypad', () {
    testWidgets('idle state shows 0 and an AC key', (tester) async {
      await _pumpCalc(tester, const ScientificCalc());

      expect(find.text('0'), findsWidgets); // readout + the 0 key
      expect(find.text('AC'), findsOneWidget);
      expect(find.byIcon(Icons.backspace_outlined), findsNothing);
    });

    testWidgets('typing shows the expression above the live result',
        (tester) async {
      await _pumpCalc(tester, const ScientificCalc());

      await _tapKey(tester, '5');
      await _tapKey(tester, '×');
      await _tapKey(tester, '3');
      await tester.pumpAndSettle();

      expect(find.text('5×3'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      // AC turns into backspace once there is something to delete.
      expect(find.text('AC'), findsNothing);
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('equals commits the expression with a trailing =',
        (tester) async {
      await _pumpCalc(tester, const ScientificCalc());

      await _tapKey(tester, '8');
      await _tapKey(tester, '+');
      await _tapKey(tester, '7');
      await _tapKey(tester, '=');
      await tester.pumpAndSettle();

      expect(find.text('8+7 ='), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('percent divides the trailing number by 100', (tester) async {
      await _pumpCalc(tester, const ScientificCalc());

      await _tapKey(tester, '5');
      await _tapKey(tester, '0');
      await _tapKey(tester, '%');
      await tester.pumpAndSettle();

      expect(find.text('0.5'), findsOneWidget);
    });

    testWidgets('backspace deletes the last character', (tester) async {
      await _pumpCalc(tester, const ScientificCalc());

      await _tapKey(tester, '1');
      await _tapKey(tester, '2');
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(CalcKeypad),
        matching: find.byIcon(Icons.backspace_outlined),
      ));
      await tester.pumpAndSettle();
      expect(find.text('12'), findsNothing);
      expect(find.text('1'), findsWidgets);
    });
  });

  group('ScientificCalc · function keys', () {
    testWidgets('renders the function grid and toggles 2nd', (tester) async {
      await _pumpCalc(tester, const ScientificCalc());

      expect(find.text('sin'), findsOneWidget);
      expect(find.text('mr'), findsOneWidget);
      expect(find.text('Rad'), findsOneWidget);

      await _tapKey(tester, '2nd');
      await tester.pumpAndSettle();
      expect(find.text('sin⁻¹'), findsOneWidget);
      expect(find.text('sinh⁻¹'), findsOneWidget);
    });

    testWidgets('Rad/Deg toggle changes the trig result', (tester) async {
      await _pumpCalc(tester, const ScientificCalc());

      await _tapKey(tester, 'Rad');
      await tester.pumpAndSettle();
      expect(find.text('Deg'), findsOneWidget);

      await _tapKey(tester, 'sin');
      await _tapKey(tester, '9');
      await _tapKey(tester, '0');
      await tester.pumpAndSettle();

      // sin(90°) = 1 — auto-closing the open paren keeps the result live.
      expect(find.text('1'), findsWidgets);
    });
  });
}
