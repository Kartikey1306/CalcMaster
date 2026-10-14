import 'dart:convert';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../lib_currency.dart';
import '../sheet/sheets_controller.dart';

/// Outcome of a GPS-based region detection attempt, so the UI can show the
/// right feedback (a toast, a permission hint, etc.).
enum DetectResult { success, permissionDenied, unavailable, noMatch }

class RegionProvider extends ChangeNotifier implements LatestRatesSource {
  static const _kRegion = 'region';
  static const _kRatesCache = 'rates_cache';

  RegionId _regionId = RegionId.US;
  // Empty until a real Frankfurter response (live or cached) is available.
  Map<String, double> _rates = const {};
  bool _ratesLive = false;
  bool _ratesLoading = true;
  int? _ratesUpdatedAt;
  String? _ratesDate;
  bool _detecting = false;

  RegionId get regionId => _regionId;
  Region get region => regionById(_regionId);
  Map<String, double> get rates => _rates;
  bool get ratesLive => _ratesLive;
  int? get ratesUpdatedAt => _ratesUpdatedAt;

  /// ECB reference date of the rates in [rates], or `null` when there are none.
  String? get ratesDate => _ratesDate;

  /// True while a rates fetch is in flight.
  bool get ratesLoading => _ratesLoading;

  /// True while a GPS detection is in flight (drives the picker's spinner).
  bool get detecting => _detecting;

  @override
  RatesResult? get latestTable => _rates.isEmpty
      ? null
      : RatesResult(
          rates: _rates,
          fetchedAt: _ratesUpdatedAt ?? 0,
          date: _ratesDate ?? '',
          live: _ratesLive);

  @override
  bool get latestOffline => !_ratesLoading && !_ratesLive;

  /// [client] is for tests; the app uses the default HTTP client.
  RegionProvider({http.Client? client}) : _client = client {
    _hydrate();
  }

  final http.Client? _client;

  Future<void> _hydrate() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString(_kRegion);
    if (saved != null) {
      try {
        _regionId = RegionId.values.firstWhere((r) => r.name == saved);
        notifyListeners();
      } catch (_) {}
    } else {
      // First launch with no saved region: follow the device's region
      // setting. Location is never requested here — only when the user taps
      // "Detect" in the region picker (or "Use my location" in the GPS tool).
      final fromLocale = regionForLocale(PlatformDispatcher.instance.locale);
      if (fromLocale != null && fromLocale != _regionId) {
        _regionId = fromLocale;
        notifyListeners();
      }
    }
    final cachedRates = sp.getString(_kRatesCache);
    final cached =
        cachedRates == null ? null : RatesResult.fromCacheJson(cachedRates);
    if (cached != null) _applyRates(cached);
    refreshRates();
  }

  /// Detects the country from the device location and switches the region/
  /// currency to match. Returns a [DetectResult] for UI feedback.
  Future<DetectResult> detectRegionFromLocation() async {
    if (_detecting) return DetectResult.unavailable;
    _detecting = true;
    notifyListeners();
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return DetectResult.permissionDenied;
      }

      final pos = await Geolocator.getCurrentPosition();
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final iso =
          placemarks.isNotEmpty ? placemarks.first.isoCountryCode : null;
      final matched = iso == null ? null : regionForCountry(iso);
      if (matched == null) return DetectResult.noMatch;

      await setRegion(matched);
      return DetectResult.success;
    } catch (_) {
      return DetectResult.unavailable;
    } finally {
      _detecting = false;
      notifyListeners();
    }
  }

  /// Maps an ISO 3166-1 alpha-2 country code to one of the app's regions.
  /// Eurozone countries collapse to the shared EU/euro region.
  static const _eurozone = {
    'AT',
    'BE',
    'HR',
    'CY',
    'EE',
    'FI',
    'FR',
    'DE',
    'GR',
    'IE',
    'IT',
    'LV',
    'LT',
    'LU',
    'MT',
    'NL',
    'PT',
    'SK',
    'SI',
    'ES',
  };

  /// The region for a device locale's country (e.g. `ja_JP` -> JP), or
  /// `null` when the locale carries no country or it has no matching region.
  static RegionId? regionForLocale(Locale locale) {
    final cc = locale.countryCode;
    if (cc == null || cc.isEmpty) return null;
    return regionForCountry(cc);
  }

  static RegionId? regionForCountry(String iso) {
    final code = iso.toUpperCase();
    const direct = {
      'US': RegionId.US,
      'GB': RegionId.UK,
      'CA': RegionId.CA,
      'AU': RegionId.AU,
      'IN': RegionId.IN,
      'JP': RegionId.JP,
      'BR': RegionId.BR,
      'MX': RegionId.MX,
      'KR': RegionId.KR,
      'AE': RegionId.AE,
    };
    if (direct.containsKey(code)) return direct[code];
    if (_eurozone.contains(code)) return RegionId.EU;
    return null;
  }

  Future<void> setRegion(RegionId id) async {
    _regionId = id;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kRegion, id.name);
  }

  Future<void> cycleRegion() async {
    final idx = regions.indexWhere((r) => r.id == _regionId);
    final next = regions[(idx + 1) % regions.length].id;
    await setRegion(next);
  }

  void _applyRates(RatesResult result) {
    _rates = result.rates;
    _ratesLive = result.live;
    _ratesUpdatedAt = result.fetchedAt;
    _ratesDate = result.date;
  }

  /// Fetches fresh rates. On failure the last real (cached) rates stay, marked
  /// not live; if there were none, [rates] stays empty.
  @override
  Future<void> refreshRates() async {
    _ratesLoading = true;
    notifyListeners();
    final result = await fetchLatestRates(client: _client);
    if (result != null) {
      _applyRates(result);
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kRatesCache, jsonEncode(result.toJson()));
    } else {
      _ratesLive = false;
    }
    _ratesLoading = false;
    notifyListeners();
  }
}
