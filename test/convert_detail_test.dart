import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:calcmaster/screens/convert_detail.dart';

MaterialApp _wrap(Widget child) => MaterialApp(
      home: child,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );

/// The converter is a full-height phone layout (readout + 5-row keypad), so
/// pump it in a phone-sized window rather than the 800×600 test default.
Future<void> _pumpConverter(WidgetTester tester, String categoryId) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_wrap(ConvertDetail(categoryId: categoryId)));
  await tester.pumpAndSettle();
}

void main() {
  group('ConvertDetail · keypad + swap', () {
    testWidgets('initial state shows mm → cm conversion', (tester) async {
      await _pumpConverter(tester, 'distance');

      // Header
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('9 units available'), findsOneWidget);

      // FROM/TO unit captions are tappable pickers
      expect(find.text('MM · MILLIMETER'), findsOneWidget);
      expect(find.text('CM · CENTIMETER'), findsOneWidget);

      // Swap affordance (icon + keypad key) and the keypad itself
      expect(find.byIcon(Icons.swap_vert), findsOneWidget);
      expect(find.text('SWAP'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      // Seeded with 1 mm = 0.1 cm
      expect(find.text('1'), findsWidgets);
      expect(find.text('0.1'), findsOneWidget);
    });

    testWidgets('typing on the keypad updates the converted value',
        (tester) async {
      await _pumpConverter(tester, 'distance');

      // 1 → 12 mm = 1.2 cm
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.text('1.2'), findsOneWidget);
    });

    testWidgets('tapping swap reverses FROM/TO units', (tester) async {
      await _pumpConverter(tester, 'distance');

      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();

      // After swap: FROM=cm, TO=mm. 1 cm = 10 mm.
      expect(find.text('CM · CENTIMETER'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('unit picker sheet lists the category units', (tester) async {
      await _pumpConverter(tester, 'distance');

      await tester.tap(find.text('CM · CENTIMETER'));
      await tester.pumpAndSettle();

      expect(find.text('CONVERT TO'), findsOneWidget);
      expect(find.text('Meter (m)'), findsOneWidget);

      await tester.tap(find.text('Meter (m)'));
      await tester.pumpAndSettle();

      // 1 mm = 0.001 m
      expect(find.text('M · METER'), findsOneWidget);
      expect(find.text('0.001'), findsOneWidget);
    });

    testWidgets('volume category renders its keypad without crashing',
        (tester) async {
      await _pumpConverter(tester, 'volume');
      expect(find.byIcon(Icons.swap_vert), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
