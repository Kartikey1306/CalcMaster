// BESPOKE store screenshots for CalcMaster - do not regenerate.
//
// Drives the real app from a fresh install, through the real UI only, and
// captures five screens that show what the store listing promises:
//
//   01_scientific_calculator  Scientific mode with a committed result
//   02_distance_converter     Convert > Distance, miles -> kilometres
//   03_currency_live_rates    Finance > Currency with live ECB rates
//                             (api.frankfurter.dev - the test fails rather
//                             than capture "Loading…" or "unavailable")
//   04_income_tax             Finance > Tax, income-tax estimate
//   05_notes                  Notes saved on this device through the editor
//
// No sign-in: CalcMaster never requires an account (the splash routes every
// user straight to /calculate; /login is only reachable from Settings), and
// none of the features shown above needs one. QA_EMAIL / QA_PASSWORD are
// therefore not read. Nothing here posts, purchases or deletes anything; the
// only data created is two notes kept in this device's SharedPreferences.
//
// Why there is no plain pumpAndSettle: AnimatedGradientBackground and
// ParticleDotGrid run an AnimationController.repeat() that is only suppressed
// under AutomatedTestWidgetsFlutterBinding (flutter test), not under the
// integration_test binding used by flutter drive. The tree never goes idle,
// so settle() tries pumpAndSettle with a short timeout and falls back to a
// bounded number of real-time pumps.
//
// Layouts: iPhone gets the custom bottom bar, iPad (>= 840 dp wide) gets a
// NavigationRail whose labels are hidden when it is not extended. Tabs are
// therefore found by their icon inside whichever navigation is present, and
// everything else by widget type/property or text - never by coordinates.
import 'package:calcmaster/main.dart' as app;
import 'package:calcmaster/screens/notes_screen.dart';
import 'package:calcmaster/widgets/calc_key.dart';
import 'package:calcmaster/widgets/convert_card.dart';
import 'package:calcmaster/widgets/number_input.dart';
import 'package:calcmaster/widgets/result_row.dart';
import 'package:calcmaster/widgets/rich_hub_card.dart';
import 'package:calcmaster/widgets/tab_scaffold.dart';
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
  /// if it never does - a missing proof widget must never become a shot of
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

  Future<void> waitGone(WidgetTester tester, Finder f, String what) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < const Duration(seconds: 10)) {
      if (f.evaluate().isEmpty) return;
      await tick(tester, 100);
    }
    fail('Timed out waiting for $what to disappear.');
  }

  /// pumpAndSettle with a timeout, falling back to bounded real-time pumps
  /// (the always-running background animations mean it usually times out).
  Future<void> settle(WidgetTester tester) async {
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
    } on Object catch (_) {
      // Expected: repeat() animations keep scheduling frames.
    }
    for (var i = 0; i < 8; i++) {
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

  /// Hides the keyboard, clears snackbars and lets the frame settle.
  Future<void> shot(WidgetTester tester, String name) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tick(tester);
    for (final e in find.byType(ScaffoldMessenger).evaluate()) {
      final s = (e as StatefulElement).state;
      if (s is ScaffoldMessengerState) s.clearSnackBars();
    }
    await settle(tester);
    log('capture $name');
    await binding.takeScreenshot(name);
  }

  /// Taps a shell tab by its icon inside the NavigationRail (iPad / wide)
  /// or the custom bottom bar (phone).
  Future<void> openTab(WidgetTester tester, IconData icon, String what) async {
    final rail = find.byType(NavigationRail);
    final bottom = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_BottomNav');
    final Finder target;
    if (rail.evaluate().isNotEmpty) {
      target = find.descendant(of: rail, matching: find.byIcon(icon));
    } else if (bottom.evaluate().isNotEmpty) {
      target = find.descendant(of: bottom, matching: find.byIcon(icon));
    } else {
      fail('Neither a NavigationRail nor the bottom bar is on screen.');
    }
    await tap(tester, target, '$what tab');
    await settle(tester);
  }

  Finder hubCard(String svg) => find.byWidgetPredicate(
      (w) => w is RichHubCard && w.svgPath == 'assets/icons/$svg.svg');

  Finder key(String glyph) => find.byWidgetPredicate(
      (w) => w is CalcKey && (w.label ?? w.semanticLabel) == glyph);

  Future<void> keys(WidgetTester tester, List<String> glyphs) async {
    for (final g in glyphs) {
      await tap(tester, key(g), 'key "$g"');
    }
  }

  Finder numberField(String labelPrefix) => find.descendant(
        of: find.byWidgetPredicate((w) =>
            w is NumberInput && (w.label ?? '').startsWith(labelPrefix)),
        matching: find.byType(TextField),
      );

  Finder resultRow(String label, {bool nonZero = false}) =>
      find.byWidgetPredicate((w) =>
          w is ResultRow &&
          w.label == label &&
          (!nonZero || RegExp('[1-9]').hasMatch(w.value)));

  testWidgets('CalcMaster store screenshots', (WidgetTester tester) async {
    app.main();

    // Splash (~2.2 s animation) routes everyone to the Calculate hub. No
    // onboarding, consent or sign-in gate exists in this app.
    await waitFor(tester, find.byType(TabScaffold), 'tab shell after splash',
        timeout: const Duration(seconds: 60));
    await settle(tester);

    // ---- 01 Scientific calculator: √(2) × π = 4.4428829382 ----
    await openTab(tester, Icons.calculate, 'Calculate');
    await tap(tester, hubCard('scientific'), 'Scientific card');
    await waitFor(tester, key('sin'), 'scientific keypad');
    await settle(tester);
    await keys(tester, ['²√x', '2', ')', '×', 'π', '=']);
    await waitFor(tester, find.textContaining('4.44288'),
        'scientific result 4.44288…');
    // Tapping the bottom keys can scroll a phone-height window down; bring
    // the header and the result readout back into view.
    await tester.ensureVisible(find.byTooltip('Go back').first);
    await shot(tester, '01_scientific_calculator');

    // ---- 02 Distance converter: 26.2 mi (a marathon) -> km ----
    await openTab(tester, Icons.swap_horiz, 'Convert');
    await tap(
        tester,
        find.byWidgetPredicate(
            (w) => w is ConvertCard && w.category.id == 'distance'),
        'Distance card');
    await waitFor(tester, find.text('MM · MILLIMETER'), 'distance converter');
    await settle(tester);

    await tap(tester, find.text('MM · MILLIMETER'), 'FROM unit picker');
    await tap(tester, find.text('Mile (mi)'), 'Mile in picker');
    await waitGone(tester, find.text('Mile (mi)'), 'unit picker');
    await waitFor(tester, find.text('MI · MILE'), 'FROM = Mile');

    await tap(tester, find.text('CM · CENTIMETER'), 'TO unit picker');
    await tap(tester, find.text('Kilometer (km)'), 'Kilometer in picker');
    await waitGone(tester, find.text('Kilometer (km)'), 'unit picker');
    await waitFor(tester, find.text('KM · KILOMETER'), 'TO = Kilometer');

    // The readout starts at "1": backspace it, then type 26.2.
    await keys(tester, ['⌫', '2', '6', '.', '2']);
    await waitFor(tester, find.textContaining('42.1648'),
        '26.2 mi = 42.1648… km');
    await shot(tester, '02_distance_converter');

    // ---- 03 Currency with live ECB rates (network) ----
    await openTab(tester, Icons.attach_money, 'Finance');
    await tap(tester, hubCard('currency'), 'Currency card');
    final liveRates = find.textContaining('ECB rates, ');
    final start = DateTime.now();
    while (liveRates.evaluate().isEmpty &&
        DateTime.now().difference(start) < const Duration(seconds: 12)) {
      await tick(tester, 100);
    }
    if (liveRates.evaluate().isEmpty &&
        find.text('Rates unavailable').evaluate().isNotEmpty) {
      // The launch-time fetch failed; use the screen's own refresh button.
      log('rates unavailable - tapping refresh');
      await tap(tester, find.byIcon(Icons.refresh), 'refresh rates');
    }
    await waitFor(tester, liveRates, 'live ECB exchange rates');
    await tester.enterText(numberField('Amount'), '250');
    await tick(tester);
    await waitFor(tester, resultRow('EUR', nonZero: true), 'EUR rate row');
    await shot(tester, '03_currency_live_rates');

    // ---- 04 Income tax estimate ----
    // Re-tapping the active tab returns the Finance branch to its hub.
    await openTab(tester, Icons.attach_money, 'Finance');
    await tap(tester, hubCard('tax'), 'Tax card');
    await waitFor(tester, numberField('Annual gross'), 'income tax form');
    await tester.enterText(numberField('Annual gross'), '85000');
    await tick(tester);
    await waitFor(tester, resultRow('Tax owed', nonZero: true),
        'computed tax owed');
    await shot(tester, '04_income_tax');

    // ---- 05 Notes saved on this device ----
    await openTab(tester, Icons.bookmark_outline, 'Notes');
    final notesFields = find.descendant(
        of: find.byType(NotesScreen), matching: find.byType(TextField));
    await waitFor(tester, notesFields, 'notes editor');
    // Field order in NotesScreen: search, title, body.
    final addButton = find.descendant(
        of: find.byType(NotesScreen), matching: find.byType(FilledButton));
    const notes = <(String, String)>[
      (
        'Road trip fuel',
        '1,240 km at 7.2 L/100 km = 89.3 L. Fill up in Flagstaff and Barstow.'
      ),
      (
        'Kitchen tile order',
        'Floor 42 m² × \$38/m² = \$1,596. Add 10% for cuts: 46.2 m².'
      ),
    ];
    for (final (title, body) in notes) {
      await tester.enterText(notesFields.at(1), title);
      await tick(tester);
      await tester.enterText(notesFields.at(2), body);
      await tick(tester);
      await tap(tester, addButton, 'Add note');
      // A plain Text (not the EditableText being typed into) is the list
      // entry NotesProvider rendered after the save.
      await waitFor(
          tester,
          find.byWidgetPredicate((w) => w is Text && w.data == title),
          'saved note "$title"');
    }
    await shot(tester, '05_notes');
  });
}
