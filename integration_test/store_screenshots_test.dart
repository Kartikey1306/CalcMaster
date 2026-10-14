// BESPOKE store screenshots for CalcMaster - do not regenerate.
//
// Drives the real app from a fresh install, through the real UI only, and
// captures the five screens the listing describes (spec §5):
//
//   01_trip_sheet       a trip sheet: dated EUR and GBP lines in USD, each
//                       with its ECB caption, and the total. The rates are
//                       the real ones Frankfurter returns for those dates —
//                       the test fails rather than capture "Getting…".
//   02_diy_sheet        a DIY sheet in feet and metres with a percentage
//                       line for waste
//   03_tools            the Tools drawer
//   04_share_preview    the Share preview: every rate, its date and source
//   05_sheets_night     the Sheets list with a search, in Night ledger
//
// No sign-in exists in this app; nothing here posts, purchases or deletes.
// The only data created is two sheets kept in this device's
// SharedPreferences. The amounts are typed scenario inputs.
//
// Layouts: on iPad (>= 840 dp wide) the Sheets list is a left pane, so the
// Sheets button is absent there; everything is found by tooltip, type or
// text — never by coordinates.
import 'package:calcmaster/main.dart' as app;
import 'package:calcmaster/screens/sheet/sheet_screen.dart';
import 'package:calcmaster/screens/sheet/sheets_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  void log(String m) => debugPrint('[shots] $m');

  /// Real-time pump: lets frames, timers, platform channels and HTTP make
  /// progress (runAsync escapes the fake-async zone so I/O can complete).
  Future<void> tick(WidgetTester tester, [int ms = 150]) async {
    await tester.pump(Duration(milliseconds: ms));
    await tester
        .runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  }

  /// Polls until [f] matches, up to [timeout]. Fails the test with [what]
  /// if it never does — a missing proof widget must never become a shot of
  /// a spinner or an error.
  Future<void> waitFor(
    WidgetTester tester,
    Finder f,
    String what, {
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      if (f.evaluate().isNotEmpty) {
        log('found $what after '
            '${DateTime.now().difference(start).inMilliseconds}ms');
        return;
      }
      await tick(tester, 100);
    }
    fail('Timed out after ${timeout.inSeconds}s waiting for $what '
        '(${f.describeMatch(Plurality.many)}).');
  }

  Future<void> settle(WidgetTester tester) async {
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
    } on Object catch (_) {}
    for (var i = 0; i < 4; i++) {
      await tick(tester, 120);
    }
  }

  Future<void> tap(WidgetTester tester, Finder f, String what) async {
    await waitFor(tester, f, what, timeout: const Duration(seconds: 10));
    await tester.ensureVisible(f.first);
    await tick(tester, 80);
    await tester.tap(f.first);
    await tick(tester, 120);
  }

  Future<void> shot(WidgetTester tester, String name,
      {bool keepFocus = false}) async {
    if (!keepFocus) FocusManager.instance.primaryFocus?.unfocus();
    await tick(tester);
    for (final e in find.byType(ScaffoldMessenger).evaluate()) {
      final s = (e as StatefulElement).state;
      if (s is ScaffoldMessengerState) s.clearSnackBars();
    }
    await settle(tester);
    log('capture $name');
    await binding.takeScreenshot(name);
  }

  Finder line(int i) => find
      .descendant(of: find.byType(SheetEditor), matching: find.byType(TextField))
      .at(i);

  /// Types [lines] into the sheet, one per line, using the keyboard's
  /// next-line action between them.
  Future<void> typeLines(WidgetTester tester, List<String> lines) async {
    for (var i = 0; i < lines.length; i++) {
      await waitFor(tester, line(i), 'line ${i + 1}');
      await tester.enterText(line(i), lines[i]);
      await tick(tester);
      if (i < lines.length - 1) {
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tick(tester, 200);
      }
    }
  }

  Future<void> rename(WidgetTester tester, String title) async {
    await tap(tester, find.bySemanticsLabel(RegExp(r'^Sheet title: ')),
        'sheet title');
    await waitFor(tester, find.byType(AlertDialog), 'rename dialog');
    await tester.enterText(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(TextField)),
        title);
    await tap(tester, find.text('Save'), 'Save');
    await settle(tester);
  }

  Future<void> menu(WidgetTester tester, String item) async {
    await tap(tester, find.byTooltip('More'), 'More menu');
    await tap(tester, find.text(item).last, item);
    await settle(tester);
  }

  testWidgets('CalcMaster store screenshots', (WidgetTester tester) async {
    app.main();
    await waitFor(tester, find.byType(SheetEditor), 'the first sheet',
        timeout: const Duration(seconds: 60));
    await settle(tester);

    // ---- 01 Trip sheet at the rate on the day ----
    await rename(tester, 'Lisbon trip');
    await typeLines(tester, [
      'Dinner: 38.50 EUR on 14 Sep in USD',
      'Hotel: 120 GBP on 15 Sep in USD',
      'Ferry: 100 EUR on 10 Oct in USD',
      'Taxi: 18 USD + 15%',
    ]);
    // Real ECB captions for each dated line, from Frankfurter.
    await waitFor(tester, find.textContaining('ECB '), 'an ECB caption',
        timeout: const Duration(seconds: 30));
    await waitFor(
        tester, find.textContaining('(no rate on Sat 10 Oct)'),
        'the weekend caption naming the ECB working day',
        timeout: const Duration(seconds: 30));
    final waiting = find.textContaining('Getting the ECB rate');
    final start = DateTime.now();
    while (waiting.evaluate().isNotEmpty &&
        DateTime.now().difference(start) < const Duration(seconds: 30)) {
      await tick(tester, 200);
    }
    expect(waiting, findsNothing, reason: 'every dated line has its rate');
    expect(find.textContaining('Needs a connection'), findsNothing);
    await shot(tester, '01_trip_sheet');

    // ---- 04 Share preview (taken from the trip sheet) ----
    await menu(tester, 'Share as text');
    await waitFor(tester, find.textContaining('Reference rates: European'),
        'the share preview');
    await shot(tester, '04_share_preview');
    await tap(tester, find.text('Copy'), 'close the preview with Copy');
    await settle(tester);

    // ---- 02 DIY sheet: feet, metres and a waste allowance ----
    await menu(tester, 'New sheet');
    await rename(tester, 'Shelving wall');
    await typeLines(tester, [
      'Wall: 12 ft in m',
      'Shelf boards: 4 * 1.2 m',
      'Waste: #2 + 10%',
      'Edging: 2.4 m + 80 cm',
    ]);
    await waitFor(tester, find.text('3.6576 m'), '12 ft in m');
    await shot(tester, '02_diy_sheet');

    // ---- 03 Tools drawer ----
    await tap(tester, find.byTooltip('Tools'), 'Tools');
    await waitFor(tester, find.text('MONEY'), 'the Tools drawer');
    await shot(tester, '03_tools');
    await tap(tester, find.byTooltip('Close tools'), 'close Tools');
    await settle(tester);

    // ---- 05 Sheets list with a search, in Night ledger ----
    await menu(tester, 'Settings');
    await tap(tester, find.text('Night ledger'), 'Night ledger');
    await tap(tester, find.byTooltip('Close'), 'close Settings');
    await settle(tester);
    if (find.byType(SheetsListPane).evaluate().isEmpty) {
      await tap(tester, find.byTooltip('Sheets'), 'Sheets');
    }
    await waitFor(tester, find.byType(SheetsListPane), 'the Sheets list');
    await tester.enterText(
        find
            .descendant(
                of: find.byType(SheetsListPane),
                matching: find.byType(TextField))
            .first,
        'trip');
    await tick(tester);
    await waitFor(tester, find.text('Lisbon trip'), 'the search result');
    await shot(tester, '05_sheets_night', keepFocus: true);
  });
}
