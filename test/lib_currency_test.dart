import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/l10n/generated/app_localizations.dart';
import 'package:calcmaster/lib_currency.dart';
import 'package:calcmaster/screens/finance/finance_screens.dart';
import 'package:calcmaster/state/region_provider.dart';
import 'package:calcmaster/widgets/result_row.dart';

// Shape of a real Frankfurter `latest?from=USD` response (values trimmed).
const _frankfurterBody =
    '{"amount":1.0,"base":"USD","date":"2026-10-09","rates":{"EUR":0.89238,'
    '"GBP":0.75641,"INR":96.73}}';

void main() {
  group('parseRatesResponse', () {
    test('keeps Frankfurter rates and its reference date', () {
      final r = parseRatesResponse(_frankfurterBody, 1)!;
      expect(r.live, isTrue);
      expect(r.date, '2026-10-09');
      expect(r.rates, {'USD': 1, 'EUR': 0.89238, 'GBP': 0.75641, 'INR': 96.73});
    });

    test('returns null for a body without rates', () {
      expect(parseRatesResponse('{"message":"not found"}', 1), isNull);
      expect(parseRatesResponse('not json', 1), isNull);
    });
  });

  group('fetchLatestRates', () {
    test('returns null on an HTTP error instead of substitute rates', () async {
      final client = MockClient((_) async => http.Response('', 500));
      expect(await fetchLatestRates(client: client), isNull);
    });

    test('returns null when the network throws', () async {
      final client = MockClient((_) async => throw Exception('offline'));
      expect(await fetchLatestRates(client: client), isNull);
    });
  });

  group('cache', () {
    test('a cached response round-trips and is marked not live', () {
      final live = parseRatesResponse(_frankfurterBody, 42)!;
      final cached = RatesResult.fromCacheJson(jsonEncode(live.toJson()))!;
      expect(cached.live, isFalse);
      expect(cached.date, '2026-10-09');
      expect(cached.fetchedAt, 42);
      expect(cached.rates, live.rates);
    });

    test('an unreadable cache yields nothing', () {
      expect(RatesResult.fromCacheJson('{}'), isNull);
      expect(RatesResult.fromCacheJson('garbage'), isNull);
    });
  });

  group('convertCurrency', () {
    test('converts through the given rates', () {
      final rates = {'USD': 1.0, 'EUR': 0.5, 'GBP': 0.25};
      expect(convertCurrency(10, 'EUR', 'GBP', rates), closeTo(5, 1e-9));
    });

    test('has no built-in rates to fall back on', () {
      expect(convertCurrency(1, 'USD', 'EUR', const {}).isNaN, isTrue);
      expect(convertCurrency(1, 'USD', 'JPY', {'USD': 1.0}).isNaN, isTrue);
    });
  });

  testWidgets('offline, the screen shows the last real rates with their date',
      (tester) async {
    final cached = parseRatesResponse(_frankfurterBody, 42)!;
    SharedPreferences.setMockInitialValues({
      'region': 'US',
      'rates_cache': jsonEncode(cached.toJson()),
    });
    final region = RegionProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: region,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CurrencyCalc(),
        ),
      ),
    );
    await tester.runAsync(() => region.refreshRates());
    await tester.pumpAndSettle();

    expect(region.ratesLive, isFalse);
    expect(region.ratesDate, '2026-10-09');
    expect(region.rates['EUR'], 0.89238);
    expect(find.text('ECB rates, 2026-10-09 (offline)'), findsOneWidget);
  });

  testWidgets(
      'currency screen with no rates shows the unavailable state and no '
      'invented numbers', (tester) async {
    // A saved region skips GPS detection; the test binding answers every HTTP
    // request with 400, so the fetch fails and nothing is cached.
    SharedPreferences.setMockInitialValues({'region': 'US'});
    final region = RegionProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: region,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CurrencyCalc(),
        ),
      ),
    );
    await tester.runAsync(() => region.refreshRates());
    await tester.pumpAndSettle();

    expect(region.rates, isEmpty);
    expect(
        find.text('Exchange rates unavailable. Connect to the internet and '
            'tap refresh.'),
        findsOneWidget);
    expect(find.text('Rates unavailable'), findsOneWidget);
    // No conversion rows at all, so none of the former hard-coded values.
    expect(find.byType(ResultRow), findsNothing);
    for (final v in ['0.92', '83.4', '149.2', '1,310', '—']) {
      expect(find.text(v), findsNothing, reason: '$v must not be shown');
    }
  });
}
