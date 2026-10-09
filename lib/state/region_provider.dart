import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib_currency.dart';

/// Outcome of a GPS-based region detection attempt, so the UI can show the
/// right feedback (a toast, a permission hint, etc.).
enum DetectResult { success, permissionDenied, unavailable, noMatch }

class RegionProvider extends ChangeNotifier {
  static const _kRegion = 'region';
  static const _kAutoDetected = 'region_auto_detected';
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

  RegionProvider() {
    _hydrate();
  }

  Future<void> _hydrate() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString(_kRegion);
    if (saved != null) {
      try {
        _regionId = RegionId.values.firstWhere((r) => r.name == saved);
        notifyListeners();
      } catch (_) {}
    } else if (!(sp.getBool(_kAutoDetected) ?? false)) {
      // First launch with no saved region: try once to detect the country
      // from GPS. Fire-and-forget so it never blocks startup, and only if
      // the user hasn't already denied location forever.
      _autoDetectOnFirstLaunch();
    }
    final cachedRates = sp.getString(_kRatesCache);
    final cached =
        cachedRates == null ? null : RatesResult.fromCacheJson(cachedRates);
    if (cached != null) _applyRates(cached);
    refreshRates();
  }

  Future<void> _autoDetectOnFirstLaunch() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAutoDetected, true);
    try {
      final perm = await Geolocator.checkPermission();
      // Don't surface a permission prompt unprompted if the user already said
      // no; otherwise request gently. A manual "Detect" button remains.
      if (perm == LocationPermission.deniedForever) return;
      await detectRegionFromLocation();
    } catch (_) {
      // Ignore — manual selection still works.
    }
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
      final matched = iso == null ? null : _regionForCountry(iso);
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

  RegionId? _regionForCountry(String iso) {
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
  Future<void> refreshRates() async {
    _ratesLoading = true;
    notifyListeners();
    final result = await fetchLatestRates();
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
