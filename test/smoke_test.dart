import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calcmaster/screens/sheet/sheet_screen.dart';

import 'support/app_harness.dart';

/// The cheapest end-to-end check: the real app boots straight onto the sheet,
/// and a line works out.
void main() {
  setUpApp();

  testWidgets('the app boots onto the sheet and works out a line',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(testApp());
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(SheetEditor), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '1 + 1');
    await tester.pump();
    expect(find.text('2'), findsWidgets);
  });
}
