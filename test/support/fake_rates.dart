import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:calcmaster/lib_currency.dart';
import 'package:calcmaster/sheet/sheets_controller.dart';

/// A latest-rates source the test controls. [refreshRates] installs [next]
/// as a live table, or — when [next] is null — behaves like a failed
/// (offline) refresh: the old table stays, marked not live.
class FakeRates extends ChangeNotifier implements LatestRatesSource {
  FakeRates({this.table, this.next});

  RatesResult? table;
  RatesResult? next;
  bool offline = false;
  int refreshes = 0;

  @override
  RatesResult? get latestTable => table;

  @override
  bool get latestOffline => offline;

  @override
  Future<void> refreshRates() async {
    refreshes++;
    final n = next;
    if (n != null) {
      table = n;
      offline = false;
    } else {
      offline = true;
      final t = table;
      if (t != null) {
        table = RatesResult(
            rates: t.rates, fetchedAt: t.fetchedAt, date: t.date, live: false);
      }
    }
    notifyListeners();
  }
}

RatesResult usdTable(String date, {required double eur, double gbp = 0.75555}) =>
    RatesResult(
        rates: {'USD': 1, 'EUR': eur, 'GBP': gbp},
        fetchedAt: 1,
        date: date,
        live: true);

/// Frankfurter as recorded on 2026-10-12 (spec §3), counting every request.
class FakeFrankfurter {
  int calls = 0;
  final List<Uri> requested = [];
  bool offline = false;

  static const bodies = <String, String>{
    '/v1/2026-09-14?base=EUR&symbols=USD':
        '{"amount":1.0,"base":"EUR","date":"2026-09-14","rates":{"USD":1.1551}}',
    '/v1/2026-10-10?base=EUR&symbols=USD':
        '{"amount":1.0,"base":"EUR","date":"2026-10-09","rates":{"USD":1.1206}}',
    '/v1/2026-09-15?base=GBP&symbols=USD':
        '{"amount":1.0,"base":"GBP","date":"2026-09-15","rates":{"USD":1.3524}}',
    '/v1/1999-01-04?base=EUR&symbols=USD':
        '{"amount":1.0,"base":"EUR","date":"1999-01-04","rates":{"USD":1.1789}}',
  };

  http.Client get client => MockClient((req) async {
        calls++;
        requested.add(req.url);
        if (offline) throw http.ClientException('offline');
        final key = '${req.url.path}?${req.url.query}';
        final body = bodies[key];
        if (body == null) return http.Response('{"message":"not found"}', 404);
        return http.Response(body, 200);
      });
}
