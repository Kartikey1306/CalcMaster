import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/lib_currency.dart';
import 'package:calcmaster/sheet/sheets_controller.dart';

import 'support/fake_rates.dart';

/// Rates update by themselves: a stale table is fetched again, and with the
/// setting on, undated lines move to each new ECB publication.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 11, 13, 17);

  RatesResult table(String date, double eur, {required DateTime at}) =>
      RatesResult(
          rates: {'USD': 1, 'EUR': eur, 'GBP': 0.75},
          fetchedAt: at.millisecondsSinceEpoch,
          date: date,
          live: true);

  Future<(SheetsController, FakeRates)> open(
      {bool? autoUpdate, RatesResult? start}) async {
    SharedPreferences.setMockInitialValues({
      if (autoUpdate != null) SheetsController.kAutoUpdateRates: autoUpdate,
    });
    final rates = FakeRates(
        table: start ?? table('2026-11-12', 0.90, at: now));
    final c = SheetsController(
        rates: rates,
        now: () => now,
        saveDelay: const Duration(milliseconds: 1));
    await c.init();
    return (c, rates);
  }

  String priced(SheetsController c) {
    c.setLineText(0, '100 USD in EUR');
    return c.evaluation().lines.first.display!;
  }

  test('on by default', () async {
    final (c, _) = await open();
    expect(c.autoUpdateRates, isTrue);
  });

  test('a new ECB publication moves undated lines to it', () async {
    final (c, rates) = await open();
    expect(priced(c), '90.00 EUR');
    expect(c.current.lines.first.pin?.date, '2026-11-12');

    rates.next = table('2026-11-13', 0.95, at: now);
    await rates.refreshRates();

    expect(c.evaluation().lines.first.display, '95.00 EUR');
    expect(c.current.lines.first.pin?.date, '2026-11-13');
  });

  test('with the setting off, a line keeps its first rate', () async {
    final (c, rates) = await open(autoUpdate: false);
    expect(priced(c), '90.00 EUR');

    rates.next = table('2026-11-13', 0.95, at: now);
    await rates.refreshRates();

    expect(c.evaluation().lines.first.display, '90.00 EUR');
    // Turning it on catches up straight away.
    await c.setAutoUpdateRates(true);
    expect(c.evaluation().lines.first.display, '95.00 EUR');
  });

  test('a table older than 30 minutes is fetched again; a fresh one is not',
      () async {
    final (c, rates) = await open(
        start: table('2026-11-12', 0.90,
            at: now.subtract(const Duration(minutes: 10))));
    await c.refreshRatesIfStale();
    expect(rates.refreshes, 0);

    rates.table = table('2026-11-12', 0.90,
        at: now.subtract(const Duration(minutes: 31)));
    await c.refreshRatesIfStale();
    expect(rates.refreshes, 1);
  });

  test('offline: the cached table is kept and retried', () async {
    final (c, rates) = await open();
    expect(priced(c), '90.00 EUR');
    rates.table = RatesResult(
        rates: rates.table!.rates,
        fetchedAt: rates.table!.fetchedAt,
        date: rates.table!.date,
        live: false);
    await c.refreshRatesIfStale(); // not live → always retried
    expect(rates.refreshes, 1);
    // No new table came back, so nothing moved.
    expect(c.evaluation().lines.first.display, '90.00 EUR');
  });
}
