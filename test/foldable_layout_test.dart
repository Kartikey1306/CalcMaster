import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/app_router.dart';
import 'package:calcmaster/screens/sheet/sheet_screen.dart';
import 'package:calcmaster/screens/sheet/sheets_list_screen.dart';

import 'support/app_harness.dart';

/// Foldable / dual-screen survival.
///
/// The defining property of a folding phone is not a new screen size: it is
/// that the window *changes size while the app is running*, and that it takes
/// aspect ratios no current iPhone has — near-square when unfolded, very tall
/// and narrow when folded. A layout that assumes a fixed width, or that only
/// ever sees 9:19.5, breaks visibly on the unfold.
///
/// Apple ships no simulator for this, so these widget tests *are* the
/// verification. Every screen is pumped at each window size and asserted to
/// produce no RenderFlex overflow and no layout exception (both surface
/// through `tester.takeException()` in debug).
///
/// Sockets are blocked (see `support/app_harness.dart`): `RegionProvider`
/// refreshes ECB rates on construction, and refusing to connect exercises the
/// offline path rather than the network.

/// Logical window sizes a folding iPhone passes through.
const _windows = <String, Size>{
  // Folded / cover display: tall and narrow.
  'folded 360x840': Size(360, 840),
  // Unfolded, near-square (aspect ~0.87) — no current iPhone is this shape.
  'unfolded 730x840': Size(730, 840),
  // Unfolded, rotated.
  'unfolded landscape 840x730': Size(840, 730),
  // An intermediate frame seen *during* the unfold animation.
  'mid-resize 540x840': Size(540, 840),
  // Smallest supported window.
  'smallest 320x690': Size(320, 690),
};

/// Every primary destination, addressed by route so the real router and the
/// real providers are all in play. (There is no tab bar: the sheet is home,
/// and the Sheets list, Tools drawer and Settings open over it.)
const _tabRoutes = <String>[
  '/',
  '/sheets',
  '/tools',
  '/settings',
  '/help',
];

const _detailRoutes = <String>[
  '/tools/convert/distance',
  '/tools/convert/temperature',
  '/tools/convert/dataSize',
  '/tools/scientific',
  '/tools/percentage',
  '/tools/base',
  '/tools/fraction',
  '/tools/tax',
  '/tools/sales-tax',
  '/tools/paycheck',
  '/tools/tip',
  '/tools/discount',
  '/tools/compound',
  '/tools/emi',
  '/tools/currency',
  '/tools/unit-price',
  '/tools/gps',
  '/tools/ohm',
  '/tools/bmi',
  '/tools/date-diff',
  '/tools/time-zones',
  '/tools/adc-dac',
  '/tools/age',
  '/tools/aspect-ratio',
  '/tools/calendar',
  '/settings',
  '/privacy',
  '/about',
  '/help',
];

void main() {
  setUpApp();

  /// A sheet with lines on it, so the editor is laid out with results,
  /// captions and an error rather than empty.
  Future<void> fillSheet(WidgetTester tester) async {
    appRouter.go('/');
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Shelf: 12 ft in m');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await settle(tester);
    await tester.enterText(find.byType(TextField).at(1),
        'Dinner: 38.50 EUR on 14 Sep in USD');
    await tester.pump();
  }

  Widget buildApp() => testApp();

  /// Sizes the test window in *logical* pixels.
  void resize(WidgetTester tester, Size logical) {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = logical * 3.0;
  }

  /// Navigates to [route] and settles. Returns whatever the frame threw.
  Future<Object?> visit(WidgetTester tester, String route) async {
    appRouter.go(route);
    await settle(tester);
    return tester.takeException();
  }

  group('foldable window sizes', () {
    _windows.forEach((name, size) {
      testWidgets('every destination lays out at $name', (tester) async {
        resize(tester, size);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(buildApp());
        await settle(tester);
        expect(tester.takeException(), isNull,
            reason: 'app boot overflowed at $name');

        for (final route in _tabRoutes) {
          expect(await visit(tester, route), isNull,
              reason: '$route overflowed at $name');
        }
      });

      testWidgets('every detail screen lays out at $name', (tester) async {
        resize(tester, size);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(buildApp());
        await settle(tester);
        tester.takeException();

        for (final route in _detailRoutes) {
          expect(await visit(tester, route), isNull,
              reason: '$route overflowed at $name');
        }
        // Leave the shared router at home for the next test.
        await visit(tester, '/');
      });
    });
  });

  group('large text plus a fold', () {
    // A fold *and* large type is where text layouts actually break, so the
    // busiest screens get a second pass at 1.6x.
    const busiest = <String>[
      '/',
      '/tools/convert/distance',
      '/tools',
      '/tools/scientific',
      '/tools/currency',
      '/sheets',
      '/settings',
    ];

    _windows.forEach((name, size) {
      testWidgets('the busiest screens survive 1.6x text at $name',
          (tester) async {
        resize(tester, size);
        addTearDown(tester.view.reset);

        textScale(tester, 1.6);
        await tester.pumpWidget(buildApp());
        await settle(tester);
        expect(tester.takeException(), isNull,
            reason: 'app boot overflowed at 1.6x text, $name');

        await fillSheet(tester);
        expect(tester.takeException(), isNull,
            reason: 'a filled sheet overflowed at 1.6x text, $name');
        for (final route in busiest) {
          expect(await visit(tester, route), isNull,
              reason: '$route overflowed at 1.6x text, $name');
        }
        await visit(tester, '/');
      });
    });
  });

  group('resizing while running', () {
    // The actual foldable event: the window changes size under a live widget
    // tree. Anything that captured a width once at startup breaks here and
    // nowhere else.
    testWidgets('unfolding and refolding never throws', (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, _windows['folded 360x840']!);

      await tester.pumpWidget(buildApp());
      await settle(tester);
      expect(tester.takeException(), isNull);

      const sequence = <String>[
        'folded 360x840',
        'mid-resize 540x840',
        'unfolded 730x840',
        'unfolded landscape 840x730',
        'unfolded 730x840',
        'mid-resize 540x840',
        'folded 360x840',
        'smallest 320x690',
      ];

      for (final route in _tabRoutes) {
        expect(await visit(tester, route), isNull, reason: route);
        for (final step in sequence) {
          resize(tester, _windows[step]!);
          await settle(tester);
          expect(tester.takeException(), isNull,
              reason: 'resizing $route to $step threw');
        }
      }
    });

    testWidgets('the two-pane layout follows the live window width',
        (tester) async {
      addTearDown(tester.view.reset);
      resize(tester, _windows['folded 360x840']!);

      await tester.pumpWidget(buildApp());
      await settle(tester);
      await visit(tester, '/');

      // Folded: the sheet alone, with a Sheets button; never a tab bar.
      expect(find.byType(SheetsListPane), findsNothing);
      expect(find.byTooltip('Sheets'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);

      // Unfold *without* rebuilding the app: the Sheets list appears beside
      // the sheet anyway.
      resize(tester, _windows['unfolded landscape 840x730']!);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(SheetsListPane), findsOneWidget,
          reason: 'the width breakpoint must react to the live window, not to '
              'a value captured at startup');
      expect(find.byType(SheetEditor), findsOneWidget);
      expect(find.byTooltip('Sheets'), findsNothing,
          reason: 'the list is already on screen');

      // Refold: back to the sheet alone.
      resize(tester, _windows['folded 360x840']!);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(SheetsListPane), findsNothing);
      expect(find.byTooltip('Sheets'), findsOneWidget);
    });
  });
}
