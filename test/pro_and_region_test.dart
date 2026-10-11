import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:calcmaster/lib_currency.dart';
import 'package:calcmaster/lib_finance.dart';
import 'package:calcmaster/lib_tax.dart';
import 'package:calcmaster/monetization/ad_service.dart';
import 'package:calcmaster/monetization/monetization_config.dart';
import 'package:calcmaster/monetization/premium_provider.dart';
import 'package:calcmaster/screens/finance/finance_screens.dart';
import 'package:calcmaster/state/region_provider.dart';

void main() {
  group('emiMonthly / amortizationByYear', () {
    test('matches the standard EMI formula', () {
      // 100,000 at 12%/yr over 1 year: textbook EMI is 8,884.88.
      expect(emiMonthly(100000, 12, 1), closeTo(8884.88, 0.01));
      expect(emiMonthly(1200, 0, 1), closeTo(100, 1e-9));
      expect(emiMonthly(0, 10, 5), 0);
    });

    test('schedule repays exactly the principal and ends at zero', () {
      final rows = amortizationByYear(250000, 6.5, 30);
      expect(rows, hasLength(30));
      final principal = rows.fold<double>(0, (s, r) => s + r.principalPaid);
      final interest = rows.fold<double>(0, (s, r) => s + r.interestPaid);
      expect(principal, closeTo(250000, 0.01));
      expect(rows.last.balance, closeTo(0, 0.01));
      // Interest + principal equals every instalment paid.
      expect(principal + interest,
          closeTo(emiMonthly(250000, 6.5, 30) * 360, 0.05));
      // Early years are interest-heavy, late years principal-heavy.
      expect(rows.first.interestPaid, greaterThan(rows.first.principalPaid));
      expect(rows.last.principalPaid, greaterThan(rows.last.interestPaid));
    });

    test('a partial final year gets its own row; bad input gives none', () {
      final rows = amortizationByYear(10000, 5, 2.5);
      expect(rows.map((r) => r.year), [1, 2, 3]);
      expect(rows.last.balance, closeTo(0, 0.01));
      expect(amortizationByYear(0, 5, 10), isEmpty);
      expect(amortizationByYear(1000, 5, 0), isEmpty);
      expect(amortizationByYear(1000, 5, 5000), hasLength(maxScheduleYears));
    });
  });

  group('compoundFutureValue / compoundGrowthByYear', () {
    test('monthly compounding matches the closed form', () {
      // 10,000 at 7% compounded monthly for 10 years, plus 100/month.
      final fv = compoundFutureValue(
        principal: 10000,
        annualRatePct: 7,
        years: 10,
        monthlyContribution: 100,
        compoundsPerYear: 12,
      );
      const i = 0.07 / 12;
      final expected = 10000 * _pow(1 + i, 120) +
          100 * ((_pow(1 + i, 120) - 1) / i);
      expect(fv, closeTo(expected, 1e-6));
    });

    test('a monthly contribution stays monthly under annual compounding', () {
      // No interest: 12 deposits a year whatever the compounding frequency.
      final fv = compoundFutureValue(
        principal: 0,
        annualRatePct: 0,
        years: 2,
        monthlyContribution: 50,
        compoundsPerYear: 1,
      );
      expect(fv, closeTo(1200, 1e-9));
    });

    test('yearly rows are consistent with the headline figure', () {
      final rows = compoundGrowthByYear(
        principal: 5000,
        annualRatePct: 5,
        years: 3.5,
        monthlyContribution: 200,
        compoundsPerYear: 4,
      );
      expect(rows.map((r) => r.year), [1.0, 2.0, 3.0, 3.5]);
      final headline = compoundFutureValue(
        principal: 5000,
        annualRatePct: 5,
        years: 3.5,
        monthlyContribution: 200,
        compoundsPerYear: 4,
      );
      expect(rows.last.balance, closeTo(headline, 1e-9));
      expect(rows.last.contributed, closeTo(5000 + 200 * 42, 1e-9));
      expect(rows.last.interest, closeTo(headline - (5000 + 200 * 42), 1e-9));
    });
  });

  group('customaryTipPercent', () {
    test('covers every region, with no tip where tipping is not customary',
        () {
      for (final id in RegionId.values) {
        expect(customaryTipPercent.containsKey(id), isTrue, reason: '$id');
      }
      expect(customaryTipPercent[RegionId.JP], 0);
      expect(customaryTipPercent[RegionId.KR], 0);
      expect(customaryTipPercent[RegionId.US], 18);
    });
  });

  group('RegionProvider first-launch default', () {
    test('maps the device locale country to a region', () {
      expect(RegionProvider.regionForLocale(const Locale('ja', 'JP')),
          RegionId.JP);
      expect(RegionProvider.regionForLocale(const Locale('fr', 'FR')),
          RegionId.EU);
      expect(RegionProvider.regionForLocale(const Locale('en', 'GB')),
          RegionId.UK);
      expect(RegionProvider.regionForLocale(const Locale('en')), isNull);
      expect(RegionProvider.regionForLocale(const Locale('sv', 'SE')), isNull);
    });
  });

  test('ads SDK stays off without real ad units', () async {
    // Shipping config uses Google test units, so no ad may be requested.
    expect(MonetizationConfig.adsReady, isFalse);
    expect(AdService.instance.enabled, isFalse);
    expect(AdService.instance.bannerUnitId(), isNull);
  });

  group('finance screens', () {
    Widget host(Widget child) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => RegionProvider()),
            ChangeNotifierProvider(create: (_) => PremiumProvider()),
          ],
          child: MaterialApp(
            home: child,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        );

    Future<void> fillEmi(WidgetTester tester) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '100000');
      await tester.enterText(fields.at(1), '12');
      await tester.enterText(fields.at(2), '2');
      await tester.pumpAndSettle();
    }

    testWidgets('free users see what the yearly breakdown is, not the table',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(host(const EmiCalc()));
      await tester.pumpAndSettle();
      await fillEmi(tester);
      await tester.scrollUntilVisible(find.text('See CalcMaster Pro'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Year-by-year breakdown'), findsOneWidget);
      expect(find.text('Principal'), findsNothing);
    });

    testWidgets('Pro users get the yearly amortisation table',
        (tester) async {
      SharedPreferences.setMockInitialValues({'@calcmaster/is_pro': true});
      await tester.pumpWidget(host(const EmiCalc()));
      await tester.pumpAndSettle();
      await fillEmi(tester);
      await tester.scrollUntilVisible(find.text('Principal'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Year-by-year breakdown ('), findsOneWidget);
      expect(find.text('See CalcMaster Pro'), findsNothing);
    });

    testWidgets('tip defaults to the region custom (0% in Japan)',
        (tester) async {
      SharedPreferences.setMockInitialValues({'region': 'JP'});
      await tester.pumpWidget(host(const TipCalc()));
      await tester.pumpAndSettle();
      final tip = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(tip.controller!.text, '0');
      expect(find.text('Customary tip in JP: 0%'), findsOneWidget);
    });

    testWidgets('a tip the user typed survives a region change',
        (tester) async {
      SharedPreferences.setMockInitialValues({'region': 'US'});
      await tester.pumpWidget(host(const TipCalc()));
      await tester.pumpAndSettle();
      final tipField = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(tipField).controller!.text, '18');
      await tester.enterText(tipField, '22');
      await tester.pumpAndSettle();
      final ctx = tester.element(find.byType(TipCalc));
      await Provider.of<RegionProvider>(ctx, listen: false)
          .setRegion(RegionId.JP);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(tipField).controller!.text, '22');
    });
  });
}

double _pow(double b, int e) {
  var r = 1.0;
  for (var k = 0; k < e; k++) {
    r *= b;
  }
  return r;
}
