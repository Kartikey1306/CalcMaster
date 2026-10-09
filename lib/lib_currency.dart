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
