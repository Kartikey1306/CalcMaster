import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:calcmaster/monetization/monetization_config.dart';
import 'package:calcmaster/monetization/premium_provider.dart';
import 'package:calcmaster/screens/paywall_screen.dart';

// Kept apart from premium_provider_test.dart: the paywall now builds a
// PremiumProvider, and the in_app_purchase plugin's shared billing client
// reports its missing host channel into whichever test zone first created it.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PaywallScreen', () {
    testWidgets('renders 3 tier cards + continue button', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => PremiumProvider(),
          child: MaterialApp(
            home: const PaywallScreen(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unlock CalcMaster Pro'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Annual'), findsOneWidget);
      expect(find.text('Lifetime'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Restore purchases'), findsOneWidget);
    });

    testWidgets('lists only benefits Pro actually delivers', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => PremiumProvider(),
          child: MaterialApp(
            home: const PaywallScreen(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Year-by-year loan and investment breakdowns'),
          findsOneWidget);
      expect(find.text('Real-time currency refresh'), findsNothing);
      expect(find.text('Priority email support'), findsNothing);
      // No real ad units in this build, so there is no ad to remove.
      expect(find.text('Ad-free experience'),
          MonetizationConfig.adsReady ? findsOneWidget : findsNothing);
    });

    testWidgets(
        'without store products it shows no invented prices or savings and '
        'cannot continue', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => PremiumProvider(),
          child: MaterialApp(
            home: const PaywallScreen(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Price unavailable'), findsNWidgets(3));
      expect(find.textContaining('\$'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('popular'), findsNothing);
      expect(find.text('BEST VALUE'), findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
