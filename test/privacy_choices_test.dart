// Google UMP: users in the EEA/UK/Switzerland must be able to change their
// ad-consent choice in the app. Settings shows a "Privacy choices" row only
// when UMP says privacy options are required, and the row reopens Google's
// privacy-options form.
import 'package:agl_i18n/agl_i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:calcmaster/monetization/premium_provider.dart';
import 'package:calcmaster/screens/settings_screen.dart';
import 'package:calcmaster/state/auth_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpSettings(
    WidgetTester tester, {
    required bool required,
    required VoidCallback onShow,
  }) async {
    final locale = AglLocaleController();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AglLocaleController>.value(value: locale),
        ChangeNotifierProvider(create: (_) => PremiumProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        supportedLocales: locale.supportedLocales,
        localizationsDelegates:
            aglLocalizationsDelegates(AppLocalizations.delegate),
        home: SettingsScreen(
          isPrivacyOptionsRequired: () async => required,
          showPrivacyOptions: () async => onShow(),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('row is shown when privacy options are required and opens the '
      'form', (tester) async {
    var shown = 0;
    await pumpSettings(tester, required: true, onShow: () => shown++);

    final row = find.text('Privacy choices');
    await tester.scrollUntilVisible(row, 200,
        scrollable: find.byType(Scrollable).first);
    expect(row, findsOneWidget);

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(shown, 1);
  });

  testWidgets('row is hidden when privacy options are not required',
      (tester) async {
    await pumpSettings(tester, required: false, onShow: () {});

    await tester.scrollUntilVisible(find.text('About CalcMaster'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Privacy choices'), findsNothing);
  });
}
