import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/app_router.dart';
import 'package:calcmaster/screens/help_screen.dart';
import 'package:calcmaster/screens/sheet/sheet_screen.dart';
import 'package:calcmaster/screens/tools/tools_drawer.dart';

import 'support/app_harness.dart';

/// Boots the whole app and walks every destination from the controls on the
/// sheet — the Sheets list, the Tools drawer (every group, every tool),
/// Settings and Help — asserting each renders and none throws.
///
/// This replaces the old five-tab walk: there is no tab bar any more, so the
/// equivalent of "tap each tab" is "open each destination from home".
void main() {
  setUpApp();

  Future<void> boot(WidgetTester tester) async {
    phone(tester);
    await tester.pumpWidget(testApp());
    await settle(tester);
  }

  group('home and its destinations', () {
    testWidgets('home is the sheet, with Sheets, Tools and More in the top bar',
        (tester) async {
      await boot(tester);
      expect(find.byType(SheetEditor), findsOneWidget);
      expect(find.byTooltip('Sheets'), findsOneWidget);
      expect(find.byTooltip('Tools'), findsOneWidget);
      expect(find.byTooltip('More'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('Sheets opens the list with its empty state and search',
        (tester) async {
      await boot(tester);
      await tester.tap(find.byTooltip('Sheets'));
      await settle(tester);
      expect(find.text('Sheets'), findsWidgets);
      expect(find.text('Search titles and lines'), findsOneWidget);
      expect(
          find.text(
              'No sheets yet. Start one — every line works out as you type.'),
          findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      // Back to the sheet.
      await tester.tap(find.byTooltip('Back to the sheet'));
      await settle(tester);
      expect(find.byType(SheetEditor), findsOneWidget);
    });

    testWidgets('Tools lists all six groups and every tool',
        (tester) async {
      // A tall window so the drawer lays out every entry at once.
      phone(tester, const Size(390, 3200));
      await tester.pumpWidget(testApp());
      await settle(tester);
      await tester.tap(find.byTooltip('Tools'));
      await settle(tester);

      // In the order they appear, so one downward scroll meets them all.
      const groups = ['MONEY', 'MEASURE', 'TIME', 'MATHS', 'ENGINEERING', 'BODY'];
      const labels = [
        'MONEY', 'Tip & Split', 'Discount', 'Sales tax / VAT',
        'Income tax estimate', 'Paycheck', 'EMI / Loan', 'Compound Interest',
        'Unit Price', 'Currency',
        'MEASURE', 'Distance', 'Volume', 'Weight', 'Temperature', 'Speed',
        'Area', 'Data Size', 'Fuel Economy', 'Pressure', 'Energy',
        'Aspect Ratio',
        'TIME', 'Date Difference', 'Age', 'Time Zones', 'Calendar',
        'MATHS', 'Scientific', 'Percentage', 'Base', 'Fraction',
        'ENGINEERING', "Ohm's Law", 'ADC / DAC', 'GPS Coordinates',
        'BODY', 'BMI',
      ];
      expect(labels.where((l) => !groups.contains(l)), hasLength(32),
          reason: '9 money + 10 units + aspect ratio + 4 time + 4 maths + '
              '3 engineering + BMI');
      for (final label in labels) {
        expect(
            find.descendant(
                of: find.byType(ToolsDrawer), matching: find.text(label)),
            findsOneWidget,
            reason: label);
      }
      // The Standard calculator (an iOS Calculator clone) is gone.
      expect(find.text('Standard'), findsNothing);
    });

    testWidgets('every tool opens from the drawer without an exception',
        (tester) async {
      await boot(tester);
      const routes = [
        '/tools/tip', '/tools/discount', '/tools/sales-tax', '/tools/tax',
        '/tools/paycheck', '/tools/emi', '/tools/compound', '/tools/unit-price',
        '/tools/currency', '/tools/convert/distance', '/tools/convert/volume',
        '/tools/convert/weight', '/tools/convert/temperature',
        '/tools/convert/speed', '/tools/convert/area',
        '/tools/convert/dataSize', '/tools/convert/fuelEconomy',
        '/tools/convert/pressure', '/tools/convert/energy',
        '/tools/aspect-ratio', '/tools/date-diff', '/tools/age',
        '/tools/time-zones', '/tools/calendar', '/tools/scientific',
        '/tools/percentage', '/tools/base', '/tools/fraction', '/tools/ohm',
        '/tools/adc-dac', '/tools/gps', '/tools/bmi',
      ];
      for (final route in routes) {
        appRouter.go(route);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: route);
      }
      appRouter.go('/');
      await settle(tester);
    });

    testWidgets('More opens Settings and How lines work', (tester) async {
      await boot(tester);
      await tester.tap(find.byTooltip('More'));
      await settle(tester);
      for (final item in [
        'New sheet',
        'Share as text',
        'Export CSV',
        'Copy to clipboard',
        'How lines work',
        'Settings',
      ]) {
        expect(find.text(item), findsWidgets, reason: item);
      }
      await tester.tap(find.text('Settings').last);
      await settle(tester);
      expect(find.text('HOME CURRENCY & REGION'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      // No account section any more.
      expect(find.text('ACCOUNT'), findsNothing);
      expect(find.text('Sign in'), findsNothing);
      await tester.tap(find.byTooltip('Close'));
      await settle(tester);

      await tester.tap(find.byTooltip('More'));
      await settle(tester);
      await tester.tap(find.text('How lines work').last);
      await settle(tester);
      await tester.scrollUntilVisible(find.text('Rate on the day'), 150,
          scrollable: find.descendant(
              of: find.byType(HelpScreen), matching: find.byType(Scrollable)));
      expect(find.text('Rate on the day'), findsOneWidget);
      expect(find.text('38.50 EUR on 14 Sep in USD'), findsOneWidget);
    });
  });
}
