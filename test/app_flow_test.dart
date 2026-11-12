import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/app_router.dart';
import 'package:calcmaster/lib_currency.dart';
import 'package:calcmaster/screens/sheet/sheet_screen.dart';
import 'package:calcmaster/sheet/sheet_share.dart';
import 'package:calcmaster/sheet/sheet_store.dart';
import 'package:calcmaster/state/region_provider.dart';

import 'support/app_harness.dart';

/// The core job end to end in the real app: first launch, typing a line,
/// relaunching, a tool adding to the sheet, honest states, and sharing.
void main() {
  setUpApp();

  Finder lineField(int i) => find.byType(TextField).at(i);

  group('first launch', () {
    testWidgets('opens straight onto an empty sheet with grey hints — no '
        'sign-in, splash or tab bar', (tester) async {
      phone(tester);
      await tester.pumpWidget(testApp());
      await settle(tester);

      expect(find.byType(SheetEditor), findsOneWidget);
      for (final hint in sheetHints) {
        expect(find.text(hint), findsOneWidget, reason: hint);
      }
      expect(find.text('How lines work'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      for (final gone in [
        'Sign in',
        'Welcome Back',
        'Continue with Google',
        'Get started',
        'Calculator',
      ]) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('the hints are placeholders: typing replaces them and they '
        'are never saved', (tester) async {
      phone(tester);
      await tester.pumpWidget(testApp());
      await settle(tester);

      await tester.enterText(lineField(0), '12 ft in m');
      await tester.pump();
      expect(find.text('3.6576 m'), findsWidgets);
      expect(find.text('#1 + 18%'), findsNothing);
      expect(find.text('Dinner: 38.50 EUR on 14 Sep in USD'), findsNothing);
      await letAutosave(tester);

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(SheetStore.kSheets)!;
      expect(saved, contains('12 ft in m'));
      // '12 ft in m' is what was typed; the other three hints are not saved.
      for (final hint in ['Dinner: 38.50 EUR on 14 Sep in USD', '#1 + 18%']) {
        expect(saved.contains(hint), isFalse, reason: hint);
      }
      expect(saved.contains('"total"'), isFalse);
    });

    testWidgets('relaunching restores the sheet', (tester) async {
      phone(tester);
      await tester.pumpWidget(testApp(key: const ValueKey('first')));
      await settle(tester);
      await tester.enterText(lineField(0), 'Shelf: 12 ft in m');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await settle(tester);
      await tester.enterText(lineField(1), '#1 * 2');
      await letAutosave(tester);

      // Kill the app and start it again on the same storage.
      await tester.pumpWidget(const SizedBox());
      appRouter.go('/');
      await tester.pumpWidget(testApp(key: const ValueKey('second')));
      await settle(tester);

      // The line itself, and the sheet title that defaults to it.
      expect(find.text('Shelf: 12 ft in m'), findsWidgets);
      expect(tester.widget<TextField>(lineField(0)).controller!.text,
          'Shelf: 12 ft in m');
      expect(find.text('3.6576 m'), findsWidgets);
      expect(find.text('7.3152 m'), findsWidgets);
      expect(find.text('Dinner: 38.50 EUR on 14 Sep in USD'), findsNothing);
    });
  });

  group('editing', () {
    testWidgets('the key row inserts symbols into the focused line',
        (tester) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp());
      await settle(tester);
      await tester.enterText(lineField(0), '12');
      await tester.pump();
      expect(find.bySemanticsLabel('Insert Plus'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Insert Plus'));
      await tester.pump();
      await tester.enterText(lineField(0), '${tester.widget<TextField>(lineField(0)).controller!.text}30');
      await tester.pump();
      expect(find.text('42'), findsWidgets);
      handle.dispose();
    });

    testWidgets('tapping a result puts #n into the line being edited',
        (tester) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(testApp());
      await settle(tester);
      await tester.enterText(lineField(0), '20');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await settle(tester);
      await tester.enterText(lineField(1), '5 + ');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Line 1 result 20')));
      await tester.pump();
      expect(tester.widget<TextField>(lineField(1)).controller!.text, '5 + #1');
      expect(find.text('25'), findsWidgets);
      handle.dispose();
    });
  });

  group('rename', () {
    testWidgets('renaming from the title and from the Sheets list works and '
        'leaves nothing broken behind the closing dialog', (tester) async {
      phone(tester);
      await tester.pumpWidget(testApp());
      await settle(tester);
      await tester.enterText(lineField(0), '12 ft in m');
      await tester.pump();

      await tester.tap(find.bySemanticsLabel(RegExp(r'^Sheet title: ')));
      await settle(tester);
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(TextField)),
          'Shelving');
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Shelving'), findsOneWidget);

      await tester.tap(find.byTooltip('Sheets'));
      await settle(tester);
      await tester.tap(find.byTooltip('Sheet actions for Shelving'));
      await settle(tester);
      await tester.tap(find.text('Rename').last);
      await settle(tester);
      await tester.enterText(
          find.descendant(
              of: find.byType(AlertDialog), matching: find.byType(TextField)),
          'Shelving wall');
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Shelving wall'), findsOneWidget);
    });
  });

  group('tools feed the sheet', () {
    testWidgets('Tip & split → Add to sheet appends the per-person figure',
        (tester) async {
      phone(tester);
      SharedPreferences.setMockInitialValues({'region': 'US'});
      await tester.pumpWidget(testApp());
      await settle(tester);

      await tester.tap(find.byTooltip('Tools'));
      await settle(tester);
      expect(find.text('MONEY'), findsOneWidget);
      await tester.tap(find.text('Tip & Split'));
      await settle(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '100'); // bill
      await tester.enterText(fields.at(2), '2'); // people
      await tester.pump();
      // The tool's own figure.
      expect(find.text(r'$59.00'), findsWidgets);

      await tester.tap(find.text('Add to sheet'));
      await tester.pump();
      expect(find.textContaining('Added to'), findsOneWidget);

      appRouter.go('/');
      await settle(tester);
      expect(
          find.text('Per person (bill 100 + 18% tip, 2 people): 59.00 USD'),
          findsOneWidget);
      // The sheet works the line out to the same number.
      expect(find.text('59.00 USD'), findsWidgets);
    });

    testWidgets('every tool but BMI has Add to sheet; BMI has none',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(testApp());
      await settle(tester);
      const withAdd = [
        '/tools/tip',
        '/tools/discount',
        '/tools/sales-tax',
        '/tools/tax',
        '/tools/paycheck',
        '/tools/emi',
        '/tools/compound',
        '/tools/unit-price',
        '/tools/currency',
        '/tools/aspect-ratio',
        '/tools/date-diff',
        '/tools/age',
        '/tools/time-zones',
        '/tools/calendar',
        '/tools/percentage',
        '/tools/base',
        '/tools/fraction',
        '/tools/ohm',
        '/tools/adc-dac',
        '/tools/gps',
      ];
      for (final route in withAdd) {
        appRouter.go(route);
        await settle(tester);
        expect(find.text('Add to sheet'), findsOneWidget, reason: route);
      }
      // Full-height keypads carry it in the title row.
      for (final route in [
        '/tools/scientific',
        for (final cat in ['distance', 'weight', 'temperature', 'energy'])
          '/tools/convert/$cat',
      ]) {
        final cat = route;
        appRouter.go(route);
        await settle(tester);
        expect(find.byTooltip('Add to sheet'), findsOneWidget, reason: cat);
      }
      appRouter.go('/tools/bmi');
      await settle(tester);
      expect(find.text('BMI'), findsWidgets);
      expect(find.text('Add to sheet'), findsNothing);
      expect(find.byTooltip('Add to sheet'), findsNothing);
      appRouter.go('/');
      await settle(tester);
    });
  });

  group('honest states', () {
    testWidgets('Tax and Paycheck name the year of their tables',
        (tester) async {
      phone(tester);
      SharedPreferences.setMockInitialValues({'region': 'US'});
      await tester.pumpWidget(testApp());
      await settle(tester);

      appRouter.go('/tools/tax');
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, '85000');
      await tester.pump();
      await tester.scrollUntilVisible(find.textContaining('2025 brackets'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(
          find.text(
              "Estimate using 2025 brackets — check your current year's rules"),
          findsOneWidget);

      appRouter.go('/tools/paycheck');
      await settle(tester);
      await tester.scrollUntilVisible(find.textContaining('2025 brackets'), 300,
          scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Estimate using 2025 brackets'), findsOneWidget);
      appRouter.go('/');
      await settle(tester);
    });

    testWidgets('Re-price while offline says so and keeps the pinned rate',
        (tester) async {
      phone(tester);
      SharedPreferences.setMockInitialValues({
        'region': 'US',
        SheetStore.kSheets: jsonEncode([
          {
            'id': 'trip',
            'title': 'Trip',
            'createdAt': 1,
            'updatedAt': 2,
            'lines': [
              {
                'text': '100 EUR in USD',
                'pin': {
                  'base': 'EUR',
                  'quote': 'USD',
                  'rate': 1.1206,
                  'date': '2026-10-09'
                }
              }
            ],
          }
        ]),
      });
      await tester.pumpWidget(testApp(
          region: RegionProvider(client: offlineClient())));
      await settle(tester);

      expect(find.text('112.06 USD'), findsWidgets);
      expect(find.text('Rates as of 9 Oct 2026'), findsOneWidget);
      expect(find.text('ECB 1.1206 · 9 Oct 2026 · pinned'), findsOneWidget);

      await tester.tap(find.text('Re-price'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text("Can't re-price offline — showing rates as of 9 Oct"),
          findsOneWidget);
      expect(find.text('112.06 USD'), findsWidgets);
    });

    testWidgets('a currency the ECB does not publish says so, with no number',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(testApp());
      await settle(tester);
      await tester.enterText(lineField(0), '50 AED in USD');
      await tester.pump();
      expect(find.text('The ECB publishes no reference rate for AED'),
          findsOneWidget);
    });
  });

  group('share and export', () {
    late String sharedText;
    late Uint8List sharedFile;
    late String sharedName;

    setUp(() {
      sharedText = '';
      sharedFile = Uint8List(0);
      SheetSharer.shareText = (text, subject, origin) async {
        sharedText = text;
      };
      SheetSharer.shareFile = (bytes, name, subject, origin) async {
        sharedFile = bytes;
        sharedName = name;
      };
    });

    testWidgets('Share as text and Export CSV carry the rate, its date and '
        'the source', (tester) async {
      phone(tester);
      SharedPreferences.setMockInitialValues({
        SheetStore.kSheets: jsonEncode([
          {
            'id': 'trip',
            'title': 'Lisbon',
            'createdAt': 1,
            'updatedAt': 2,
            'lines': [
              {'text': 'Dinner: 38.50 EUR on 2026-09-14 in USD'},
            ],
          }
        ]),
        SheetStore.kRateCache: jsonEncode({
          datedRateKey('2026-09-14', 'EUR', 'USD'): const EcbRate(
                  base: 'EUR', quote: 'USD', rate: 1.1551, ecbDate: '2026-09-14')
              .toJson(),
        }),
      });
      await tester.pumpWidget(testApp());
      await settle(tester);
      expect(find.text('44.47 USD'), findsWidgets);
      expect(find.text('ECB 1.1551 · 14 Sep 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('More'));
      await settle(tester);
      await tester.tap(find.text('Share as text'));
      await settle(tester);
      // A preview of exactly what will be shared comes first.
      expect(find.textContaining('44.47 USD (ECB 1.1551, 2026-09-14)'),
          findsOneWidget);
      await tester.tap(find.text('Share…'));
      await settle(tester);
      expect(sharedText, contains('44.47 USD (ECB 1.1551, 2026-09-14)'));
      expect(sharedText, contains('European Central Bank, via Frankfurter'));

      await tester.tap(find.byTooltip('More'));
      await settle(tester);
      await tester.tap(find.text('Export CSV'));
      await settle(tester);
      expect(find.textContaining('ecb_rate,ecb_date'), findsOneWidget);
      await tester.tap(find.text('Share file…'));
      await settle(tester);
      final csv = utf8.decode(sharedFile);
      expect(sharedName, 'Lisbon.csv');
      expect(csv.split('\n').first,
          'line,label,input,result,unit_or_currency,ecb_rate,ecb_date');
      expect(csv, contains('1,Dinner,38.50 EUR on 2026-09-14 in USD,44.47,USD,1.1551,2026-09-14'));
    });
  });

  group('smart answers', () {
    testWidgets('a loosely typed line shows its answer and the total at once; '
        'Use keeps it', (tester) async {
      phone(tester);
      await tester.pumpWidget(testApp());
      await settle(tester);
      await tester.enterText(lineField(0), 'finner 18 eurp for 2 peoer');
      await tester.pump();

      // The answer is on the line and in the card before anything is tapped.
      expect(find.text('≈ 9.00 EUR'), findsOneWidget);
      expect(find.text('Per person'), findsOneWidget);
      expect(find.text('9.00 EUR'), findsOneWidget);
      expect(find.text('Sheet total with this: 9.00 EUR'), findsOneWidget);

      await tester.tap(find.byKey(const Key('answer-use')));
      await settle(tester);
      expect(tester.widget<TextField>(lineField(0)).controller!.text,
          'Dinner per person: 18 EUR / 2');
      expect(find.byKey(const Key('answer-use')), findsNothing);
    });

    testWidgets('Enter on a loosely typed line keeps its answer and moves on',
        (tester) async {
      phone(tester);
      await tester.pumpWidget(testApp());
      await settle(tester);
      await tester.enterText(lineField(0), 'taxi 30 eur split in half');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await settle(tester);
      expect(tester.widget<TextField>(lineField(0)).controller!.text,
          'Taxi per person: 30 EUR / 2');
      expect(find.text('15.00 EUR'), findsWidgets);
    });

    testWidgets('the total counts the lines above', (tester) async {
      phone(tester);
      await tester.pumpWidget(testApp());
      await settle(tester);
      await tester.enterText(lineField(0), 'Hotel: 100 EUR');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await settle(tester);
      await tester.enterText(lineField(1), 'pizza 12 and drinks 8 eur');
      await tester.pump();
      expect(find.text('Sheet total with this: 120.00 EUR'), findsOneWidget);
    });
  });
}
