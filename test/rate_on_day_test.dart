import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/lib_currency.dart';
import 'package:calcmaster/sheet/sheet_engine.dart';
import 'package:calcmaster/sheet/sheet_model.dart';
import 'package:calcmaster/sheet/sheet_store.dart';
import 'package:calcmaster/sheet/sheets_controller.dart';

import 'support/fake_rates.dart';

/// "Rate on the day" (spec M2), with a mocked HTTP client — never a live call.
final _today = DateTime(2026, 10, 13);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFrankfurter api;
  late RateClient client;

  setUp(() {
    api = FakeFrankfurter();
    client = RateClient(client: api.client, today: () => _today);
  });

  SheetEvaluation evalWith(List<String> lines) => evaluateSheet(
        [for (final l in lines) SheetLine(l)],
        rates: RateBook(dated: client.cache),
        today: _today,
      );

  group('fetchRateOn', () {
    test('38.50 EUR on 2026-09-14 in USD at 1.1551 is 44.47 USD', () async {
      final r = await client.fetchRateOn(DateTime(2026, 9, 14), 'EUR', 'USD');
      expect(r.ok, isTrue);
      expect(r.rate!.rate, 1.1551);
      expect(r.rate!.ecbDate, '2026-09-14');

      final line = evalWith(['38.50 EUR on 2026-09-14 in USD']).lines.single;
      expect(line.display, '44.47 USD');
      expect(line.rate!.caption, 'ECB 1.1551 · 14 Sep 2026');
    });

    test('a Saturday uses Friday\'s rate and the caption names Friday',
        () async {
      final r = await client.fetchRateOn(DateTime(2026, 10, 10), 'EUR', 'USD');
      expect(r.rate!.ecbDate, '2026-10-09',
          reason: 'the returned date is shown, not the requested one');
      expect(r.rate!.rate, 1.1206);

      final line = evalWith(['100 EUR on 2026-10-10 in USD']).lines.single;
      expect(line.display, '112.06 USD');
      expect(line.rate!.caption,
          'ECB 1.1206 · Fri 9 Oct (no rate on Sat 10 Oct)');
      expect(line.rate!.caption, contains('Fri 9 Oct'));
    });

    test('the first ECB day works', () async {
      final r = await client.fetchRateOn(DateTime(1999, 1, 4), 'EUR', 'USD');
      expect(r.rate!.rate, 1.1789);
    });

    test('AED is unsupported, with no request and no number', () async {
      final r = await client.fetchRateOn(DateTime(2026, 9, 14), 'AED', 'USD');
      expect(r.failure, RateFailure.unsupported);
      expect(r.rate, isNull);
      expect(api.calls, 0);
      final line = evalWith(['50 AED on 14 Sep in USD']).lines.single;
      expect(line.display, isNull);
      expect(line.message, 'The ECB publishes no reference rate for AED');
    });

    test('1998-12-01 is before the ECB; a future date is refused', () async {
      expect(
          (await client.fetchRateOn(DateTime(1998, 12, 1), 'EUR', 'USD'))
              .failure,
          RateFailure.beforeEcb);
      expect(
          (await client.fetchRateOn(DateTime(2026, 10, 14), 'EUR', 'USD'))
              .failure,
          RateFailure.future);
      expect(api.calls, 0, reason: 'both are known without asking');
    });

    test('a second identical dated lookup makes zero HTTP calls', () async {
      await client.fetchRateOn(DateTime(2026, 9, 14), 'EUR', 'USD');
      expect(api.calls, 1);
      final again =
          await client.fetchRateOn(DateTime(2026, 9, 14), 'EUR', 'USD');
      expect(again.rate!.rate, 1.1551);
      expect(api.calls, 1);
    });

    test('the dated cache survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await client.fetchRateOn(DateTime(2026, 9, 14), 'EUR', 'USD');
      await SheetStore(prefs).saveRateCache(client.cache);

      final reopened = RateClient(
          client: api.client,
          today: () => _today,
          cache: SheetStore(prefs).loadRateCache());
      final r = await reopened.fetchRateOn(DateTime(2026, 9, 14), 'EUR', 'USD');
      expect(r.rate!.rate, 1.1551);
      expect(api.calls, 1);
    });

    test('offline with nothing cached is a typed failure', () async {
      api.offline = true;
      final r = await client.fetchRateOn(DateTime(2026, 9, 14), 'EUR', 'USD');
      expect(r.failure, RateFailure.offline);
    });
  });

  group('in a sheet', () {
    late FakeRates rates;
    late SheetsController sheets;

    Future<void> start({RatesResult? table}) async {
      SharedPreferences.setMockInitialValues({});
      rates = FakeRates(table: table);
      sheets = SheetsController(
          rates: rates,
          rateClient: client,
          now: () => _today,
          saveDelay: const Duration(milliseconds: 1));
      await sheets.init();
    }

    tearDown(() => sheets.dispose());

    /// Lets the controller finish the fetches an evaluation started.
    Future<SheetEvaluation> settle() async {
      sheets.evaluation();
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      return sheets.evaluation();
    }

    test('a dated line is fetched, shown with its ECB date, and totalled',
        () async {
      await start();
      sheets.setLineText(0, 'Dinner: 38.50 EUR on 14 Sep in USD');
      final e = await settle();
      expect(e.lines.single.display, '44.47 USD');
      expect(e.totalDisplay, '44.47 USD');
      expect(api.calls, 1);
    });

    test('offline with no cache: excluded from the total, labelled, and the '
        'footer says so', () async {
      await start();
      api.offline = true;
      sheets.setLineText(0, 'Taxi: 20 USD');
      sheets.insertLine(1, 'Dinner: 38.50 EUR on 14 Sep in USD');
      final e = await settle();
      final dinner = e.lines[1];
      expect(dinner.kind, LineKind.needsRate);
      expect(dinner.message,
          'Needs a connection to get the ECB rate for 14 Sep');
      expect(dinner.display, isNull);
      expect(e.totalDisplay, '20.00 USD');
      expect(e.excludedNote, 'Total excludes 1 line');
    });

    test('a pinned undated line keeps its value after the latest rate '
        'changes, until Re-price is tapped', () async {
      await start(table: usdTable('2026-10-09', eur: 0.89238));
      sheets.setLineText(0, '100 EUR in USD');
      var e = await settle();
      expect(e.lines.single.display, '112.06 USD');
      expect(sheets.current.lines.single.pin!.date, '2026-10-09');

      // Next month the ECB rate is different…
      rates.table = usdTable('2026-11-12', eur: 0.86);
      rates.notifyListeners();
      e = await settle();
      expect(e.lines.single.display, '112.06 USD',
          reason: 'the saved sheet gives the same answer next month');
      expect(e.pinnedAsOf, '2026-10-09');

      // …until the user asks.
      rates.next = usdTable('2026-11-12', eur: 0.86);
      final result = await sheets.reprice();
      expect(result.ok, isTrue);
      e = await settle();
      expect(e.lines.single.display, '116.28 USD');
      expect(e.pinnedAsOf, '2026-11-12');
    });

    test('Re-price offline keeps the pinned rates and reports their date',
        () async {
      await start(table: usdTable('2026-10-09', eur: 0.89238));
      sheets.setLineText(0, '100 EUR in USD');
      await settle();
      rates.next = null; // the refresh fails
      final result = await sheets.reprice();
      expect(result.ok, isFalse);
      expect(result.asOf, '2026-10-09');
      expect((await settle()).lines.single.display, '112.06 USD');
    });

    test('dated lines never re-price', () async {
      await start(table: usdTable('2026-10-09', eur: 0.89238));
      sheets.setLineText(0, '38.50 EUR on 2026-09-14 in USD');
      await settle();
      rates.next = usdTable('2026-11-12', eur: 0.5);
      await sheets.reprice();
      expect((await settle()).lines.single.display, '44.47 USD');
    });
  });
}
