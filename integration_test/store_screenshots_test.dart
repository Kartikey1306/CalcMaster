// BESPOKE store screenshots for CalcMaster - do not regenerate.
//
// The generic .sweep/capture_screenshots.py run against this app timed the
// whole harness out. Two always-mounted widgets, AnimatedGradientBackground
// and ParticleDotGrid, start an AnimationController.repeat() that is only
// suppressed when the binding is an AutomatedTestWidgetsFlutterBinding - the
// binding used by `flutter test`, not the one used by `flutter drive`. So
// under integration_test they run forever, every frame is a new frame, and
// pumpAndSettle never returns an idle tree; the generic test's `on Exception`
// would not have caught the resulting FlutterError either, since a
// FlutterError is an Error.
//
// This test therefore never calls pumpAndSettle. It pumps for a bounded time
// and waits on real widgets. The tab bar is also a custom widget rather than
// a BottomNavigationBar, so the tabs are driven by their label text.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:calcmaster/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<bool> pumpUntil(
    WidgetTester tester,
    Finder f, {
    Duration timeout = const Duration(seconds: 150),
  }) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      if (f.evaluate().isNotEmpty) {
        debugPrint('[shots] found ${f.description} after '
            '${DateTime.now().difference(start).inMilliseconds}ms');
        return true;
      }
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
    }
    debugPrint('[shots] TIMED OUT waiting for ${f.description}');
    return false;
  }

  Future<void> quiet(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 120)));
    }
  }

  testWidgets('store screenshots', (WidgetTester tester) async {
    app.main();
    await pumpUntil(tester, find.byType(MaterialApp));
    // The splash runs a ~1s entrance animation and then routes to /calculate.
    await pumpUntil(tester, find.text('Calculate'),
        timeout: const Duration(seconds: 60));
    await quiet(tester);
    await binding.takeScreenshot('01_calculate');

    const tabs = <String>['Convert', 'Finance', 'Tools', 'Notes'];
    var n = 1;
    for (final tab in tabs) {
      final f = find.text(tab);
      if (f.evaluate().isEmpty) continue;
      await tester.tap(f.last, warnIfMissed: false);
      await quiet(tester);
      n += 1;
      await binding.takeScreenshot('0${n}_${tab.toLowerCase()}');
    }
  });
}
