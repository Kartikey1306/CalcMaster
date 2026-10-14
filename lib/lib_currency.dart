import 'dart:convert';
import 'package:http/http.dart' as http;

/// Supported regions, named by their ISO 3166-1 alpha-2 country code (`EU` for
/// the shared eurozone region).
///
/// The names are deliberately upper-case: `RegionId.name` is the value
/// persisted under the `region` key in SharedPreferences and matched back in
/// `RegionProvider`, so lower-camel-casing them would silently reset every
/// existing user's saved region. `IN` also cannot be lower-cased — `in` is a
/// reserved word in Dart.
// ignore: constant_identifier_names
enum RegionId { US, UK, EU, CA, AU, IN, JP, BR, MX, KR, AE }

class Region {
  final RegionId id;
  final String label;
  final String flag;
  final String currency;
  final String symbol;
  final String locale;

  const Region({
    required this.id,
    required this.label,
    required this.flag,
    required this.currency,
    required this.symbol,
    required this.locale,
  });
}

const List<Region> regions = [
  Region(
      id: RegionId.US,
      label: 'US',
      flag: '🇺🇸',
      currency: 'USD',
      symbol: '\$',
      locale: 'en_US'),
  Region(
      id: RegionId.UK,
      label: 'UK',
      flag: '🇬🇧',
      currency: 'GBP',
      symbol: '£',
      locale: 'en_GB'),
  Region(
      id: RegionId.EU,
      label: 'EU',
      flag: '🇪🇺',
      currency: 'EUR',
      symbol: '€',
      locale: 'de_DE'),
  Region(
      id: RegionId.CA,
      label: 'CA',
      flag: '🇨🇦',
      currency: 'CAD',
      symbol: 'C\$',
      locale: 'en_CA'),
  Region(
      id: RegionId.AU,
      label: 'AU',
      flag: '🇦🇺',
      currency: 'AUD',
      symbol: 'A\$',
      locale: 'en_AU'),
  Region(
      id: RegionId.IN,
      label: 'IN',
      flag: '🇮🇳',
      currency: 'INR',
      symbol: '₹',
      locale: 'en_IN'),
  Region(
      id: RegionId.JP,
      label: 'JP',
      flag: '🇯🇵',
      currency: 'JPY',
      symbol: '¥',
      locale: 'ja_JP'),
  Region(
      id: RegionId.BR,
      label: 'BR',
      flag: '🇧🇷',
      currency: 'BRL',
      symbol: 'R\$',
      locale: 'pt_BR'),
  Region(
      id: RegionId.MX,
      label: 'MX',
      flag: '🇲🇽',
      currency: 'MXN',
      symbol: 'Mex\$',
      locale: 'es_MX'),
  Region(
      id: RegionId.KR,
      label: 'KR',
      flag: '🇰🇷',
      currency: 'KRW',
      symbol: '₩',
      locale: 'ko_KR'),
  Region(
      id: RegionId.AE,
      label: 'AE',
      flag: '🇦🇪',
      currency: 'AED',
      symbol: 'د.إ',
      locale: 'en_AE'),
];

Region regionById(RegionId id) =>
    regions.firstWhere((r) => r.id == id, orElse: () => regions[0]);

class RatesResult {
  final Map<String, double> rates;

  /// When this device fetched the rates (ms since epoch).
  final int fetchedAt;

  /// The ECB reference date Frankfurter reports for these rates (YYYY-MM-DD).
  final String date;
  final bool live;
  const RatesResult(
      {required this.rates,
      required this.fetchedAt,
      required this.date,
      required this.live});

  Map<String, dynamic> toJson() =>
      {'rates': rates, 'fetchedAt': fetchedAt, 'date': date};

  /// Rebuilds a cached response. Always `live: false` — a cached rate is the
  /// last real one we saw, not a current one. Returns `null` if the cache is
  /// unreadable.
  static RatesResult? fromCacheJson(String source) {
    try {
      final json = jsonDecode(source) as Map<String, dynamic>;
      final raw = json['rates'] as Map<String, dynamic>;
      final rates = <String, double>{
        for (final e in raw.entries)
          if (e.value is num) e.key: (e.value as num).toDouble(),
      };
      final date = json['date'] as String?;
      final fetchedAt = json['fetchedAt'] as int?;
      if (rates.isEmpty || date == null || fetchedAt == null) return null;
      return RatesResult(
          rates: rates, fetchedAt: fetchedAt, date: date, live: false);
    } catch (_) {
      return null;
    }
  }
}

// Frankfurter moved to api.frankfurter.dev/v1; the old api.frankfurter.app host
// only 301s here now, so call the current one directly rather than relying on
// the redirect surviving.
const String kRatesEndpoint = 'https://api.frankfurter.dev/v1/latest?from=USD';

/// Parses a Frankfurter `latest?from=USD` body. Returns `null` if it does not
/// carry rates and a reference date.
RatesResult? parseRatesResponse(String body, int fetchedAt) {
  try {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final raw = (json['rates'] as Map<String, dynamic>?) ?? {};
    final date = json['date'] as String?;
    if (raw.isEmpty || date == null) return null;
    final rates = <String, double>{'USD': 1};
    raw.forEach((k, v) {
      if (v is num) rates[k] = v.toDouble();
    });
    return RatesResult(
        rates: rates, fetchedAt: fetchedAt, date: date, live: true);
  } catch (_) {
    return null;
  }
}

/// Fetches the latest ECB reference rates from Frankfurter. Returns `null` when
/// the call fails; callers fall back to the last cached real response (or show
/// that rates are unavailable), never to made-up rates.
Future<RatesResult?> fetchLatestRates({http.Client? client}) async {
  try {
    final uri = Uri.parse(kRatesEndpoint);
    final res = await (client == null ? http.get(uri) : client.get(uri))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    return parseRatesResponse(res.body, DateTime.now().millisecondsSinceEpoch);
  } catch (_) {
    return null;
  }
}

double convertCurrency(
    double amount, String from, String to, Map<String, double> rates) {
  if (!amount.isFinite) return double.nan;
  final fromR = rates[from];
  final toR = rates[to];
  if (fromR == null || toR == null) return double.nan;
  return (amount / fromR) * toR;
}

// ---------------------------------------------------------------------------
// ECB reference rates on a date ("Rate on the day")
// ---------------------------------------------------------------------------

/// The 30 currencies the European Central Bank publishes reference rates
/// for — exactly the codes `https://api.frankfurter.dev/v1/currencies`
/// returned on 2026-10-13. The currency picker and the sheet's line parser
/// accept these and nothing else; there is no second rate source.
const List<String> ecbCurrencies = [
  'AUD', 'BRL', 'CAD', 'CHF', 'CNY', 'CZK', 'DKK', 'EUR', 'GBP', 'HKD',
  'HUF', 'IDR', 'ILS', 'INR', 'ISK', 'JPY', 'KRW', 'MXN', 'MYR', 'NOK',
  'NZD', 'PHP', 'PLN', 'RON', 'SEK', 'SGD', 'THB', 'TRY', 'USD', 'ZAR',
];

bool isEcbCurrency(String code) => ecbCurrencies.contains(code.toUpperCase());

/// Real ISO 4217 codes the ECB does not publish. A sheet line naming one gets
/// a specific reason ("The ECB publishes no reference rate for AED") instead
/// of a generic parse error. Never converted, never estimated.
const Set<String> nonEcbCurrencies = {
  'AED', 'ARS', 'BDT', 'BGN', 'BHD', 'CLP', 'COP', 'EGP', 'GHS', 'HRK',
  'JOD', 'KES', 'KWD', 'KZT', 'LKR', 'MAD', 'NGN', 'OMR', 'PEN', 'PKR',
  'QAR', 'RUB', 'SAR', 'TWD', 'UAH', 'VND',
};

/// The first day the ECB published euro reference rates.
final DateTime ecbFirstDate = DateTime.utc(1999, 1, 4);

/// Why a rate could not be produced. Each one is shown to the user as a
/// specific reason; none of them is ever replaced by a guessed number.
enum RateFailure {
  /// One of the currencies is not among [ecbCurrencies].
  unsupported,

  /// The date is before 4 Jan 1999.
  beforeEcb,

  /// The date is after today.
  future,

  /// No connection (or a timeout) and nothing cached.
  offline,

  /// Frankfurter answered, but not with a usable rate.
  http,
}

/// `YYYY-MM-DD` for the calendar date of [d].
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime _dayOf(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// One ECB reference rate: 1 [base] = [rate] [quote], published for
/// [ecbDate] (`YYYY-MM-DD`). For a weekend or holiday request [ecbDate] is
/// the previous working day — always display it, never the requested date.
class EcbRate {
  final String base;
  final String quote;
  final double rate;
  final String ecbDate;

  const EcbRate({
    required this.base,
    required this.quote,
    required this.rate,
    required this.ecbDate,
  });

  Map<String, dynamic> toJson() =>
      {'base': base, 'quote': quote, 'rate': rate, 'date': ecbDate};

  static EcbRate? fromJson(Object? json) {
    if (json is! Map) return null;
    final base = json['base'], quote = json['quote'];
    final rate = json['rate'], date = json['date'];
    if (base is! String || quote is! String || rate is! num || date is! String) {
      return null;
    }
    return EcbRate(
        base: base, quote: quote, rate: rate.toDouble(), ecbDate: date);
  }

  @override
  bool operator ==(Object other) =>
      other is EcbRate &&
      other.base == base &&
      other.quote == quote &&
      other.rate == rate &&
      other.ecbDate == ecbDate;

  @override
  int get hashCode => Object.hash(base, quote, rate, ecbDate);

  @override
  String toString() => 'EcbRate($base→$quote $rate @ $ecbDate)';
}

/// The result of a lookup: a [rate] or a typed [failure], never both.
class RateLookup {
  final EcbRate? rate;
  final RateFailure? failure;
  const RateLookup.ok(EcbRate this.rate) : failure = null;
  const RateLookup.failed(RateFailure this.failure) : rate = null;
  bool get ok => rate != null;
}

/// Cache key for a dated lookup.
String datedRateKey(String requestedDate, String base, String quote) =>
    '$requestedDate|${base.toUpperCase()}|${quote.toUpperCase()}';

/// Fetches ECB reference rates for a date through Frankfurter's keyless
/// historical endpoint (`/v1/{YYYY-MM-DD}?base=…&symbols=…`).
///
/// Published ECB rates never change, so a dated rate is cached for good in
/// [cache] (keyed by [datedRateKey]); a second identical lookup makes no HTTP
/// call. The one exception is a request for *today* answered with an earlier
/// date (the ECB publishes around 16:00 CET): that answer is not stored,
/// because it changes once today's rate is out.
class RateClient {
  RateClient({http.Client? client, DateTime Function()? today, Map<String, EcbRate>? cache})
      : _client = client,
        _today = today ?? DateTime.now,
        cache = cache ?? {};

  final http.Client? _client;
  final DateTime Function() _today;

  /// Permanent dated-rate cache, `date|BASE|QUOTE` → rate.
  final Map<String, EcbRate> cache;

  static const String endpoint = 'https://api.frankfurter.dev/v1';

  /// Checks that need no network: unsupported codes, dates before the ECB
  /// started, and dates in the future.
  RateFailure? precheck(DateTime date, String base, String quote) {
    if (!isEcbCurrency(base) || !isEcbCurrency(quote)) {
      return RateFailure.unsupported;
    }
    final day = _dayOf(date);
    if (day.isBefore(ecbFirstDate)) return RateFailure.beforeEcb;
    if (day.isAfter(_dayOf(_today()))) return RateFailure.future;
    return null;
  }

  /// The ECB rate for 1 [base] in [quote] on [date] (or the last working day
  /// before it), or a typed failure.
  Future<RateLookup> fetchRateOn(
      DateTime date, String base, String quote) async {
    base = base.toUpperCase();
    quote = quote.toUpperCase();
    final pre = precheck(date, base, quote);
    if (pre != null) return RateLookup.failed(pre);

    final requested = isoDate(date);
    final key = datedRateKey(requested, base, quote);
    final hit = cache[key];
    if (hit != null) return RateLookup.ok(hit);

    if (base == quote) {
      final same =
          EcbRate(base: base, quote: quote, rate: 1, ecbDate: requested);
      cache[key] = same;
      return RateLookup.ok(same);
    }

    final uri = Uri.parse('$endpoint/$requested?base=$base&symbols=$quote');
    http.Response res;
    try {
      res = await (_client == null ? http.get(uri) : _client.get(uri))
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      return const RateLookup.failed(RateFailure.offline);
    }
    if (res.statusCode == 404) {
      return const RateLookup.failed(RateFailure.http);
    }
    if (res.statusCode != 200) {
      return const RateLookup.failed(RateFailure.http);
    }
    final parsed = parseDatedRate(res.body, base, quote);
    if (parsed == null) return const RateLookup.failed(RateFailure.http);

    final isToday = _dayOf(date) == _dayOf(_today());
    if (!isToday || parsed.ecbDate == requested) cache[key] = parsed;
    return RateLookup.ok(parsed);
  }
}

/// Every ECB rate for 1 [base] on a date, or a typed failure.
class RateTableLookup {
  final Map<String, double>? rates;

  /// ECB date the table was published for, `YYYY-MM-DD`.
  final String? ecbDate;
  final RateFailure? failure;
  const RateTableLookup.ok(Map<String, double> this.rates, String this.ecbDate)
      : failure = null;
  const RateTableLookup.failed(RateFailure this.failure)
      : rates = null,
        ecbDate = null;
  bool get ok => rates != null;
}

extension RateTableOnDate on RateClient {
  /// All ECB rates for 1 [base] on [date] in one request
  /// (`/v1/{date}?base=…`). Each pair is stored in [RateClient.cache] under
  /// the same rules as [RateClient.fetchRateOn].
  Future<RateTableLookup> fetchTableOn(DateTime date, String base,
      {http.Client? client}) async {
    base = base.toUpperCase();
    final pre = precheck(date, base, base);
    if (pre != null) return RateTableLookup.failed(pre);
    final requested = isoDate(date);
    // Served from the cache when every other ECB currency is already there.
    final cached = <String, double>{};
    String? cachedDate;
    for (final q in ecbCurrencies) {
      if (q == base) continue;
      final hit = cache[datedRateKey(requested, base, q)];
      if (hit == null) break;
      cached[q] = hit.rate;
      cachedDate = hit.ecbDate;
    }
    if (cached.length == ecbCurrencies.length - 1 && cachedDate != null) {
      return RateTableLookup.ok(cached, cachedDate);
    }
    final uri = Uri.parse('${RateClient.endpoint}/$requested?base=$base');
    http.Response res;
    try {
      final c = client ?? _client;
      res = await (c == null ? http.get(uri) : c.get(uri))
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      return const RateTableLookup.failed(RateFailure.offline);
    }
    if (res.statusCode != 200) {
      return const RateTableLookup.failed(RateFailure.http);
    }
    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final d = json['date'];
      final raw = json['rates'];
      if (d is! String || raw is! Map) {
        return const RateTableLookup.failed(RateFailure.http);
      }
      final rates = <String, double>{
        for (final e in raw.entries)
          if (e.value is num && isEcbCurrency(e.key as String))
            e.key as String: (e.value as num).toDouble(),
      };
      final isToday = _dayOf(date) == _dayOf(_today());
      if (!isToday || d == requested) {
        rates.forEach((q, r) => cache[datedRateKey(requested, base, q)] =
            EcbRate(base: base, quote: q, rate: r, ecbDate: d));
      }
      return RateTableLookup.ok(rates, d);
    } catch (_) {
      return const RateTableLookup.failed(RateFailure.http);
    }
  }
}

/// Parses a Frankfurter `/v1/{date}?base=…&symbols=…` body.
EcbRate? parseDatedRate(String body, String base, String quote) {
  try {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final date = json['date'];
    final rates = json['rates'];
    if (date is! String || rates is! Map) return null;
    final r = rates[quote];
    if (r is! num) return null;
    return EcbRate(base: base, quote: quote, rate: r.toDouble(), ecbDate: date);
  } catch (_) {
    return null;
  }
}

/// The cross rate for 1 [base] in [quote] from a `latest?from=USD` table, or
/// null when either currency is missing from it.
EcbRate? crossRateFrom(RatesResult table, String base, String quote) {
  base = base.toUpperCase();
  quote = quote.toUpperCase();
  final b = table.rates[base], q = table.rates[quote];
  if (b == null || q == null || b == 0) return null;
  // Frankfurter publishes five or six significant digits; a cross rate keeps
  // six so it never claims more precision than its inputs had.
  final rate = double.parse((q / b).toStringAsPrecision(6));
  return EcbRate(base: base, quote: quote, rate: rate, ecbDate: table.date);
}
