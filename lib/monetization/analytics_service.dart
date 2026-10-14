import 'package:flutter/foundation.dart';

import 'monetization_config.dart';

/// A destination for product analytics — Firebase Analytics, Amplitude, or a
/// first-party endpoint.
///
/// Kept as an interface, the same way `CrashSink` is in
/// `lib/services/crash_reporter.dart`, so the app emits a complete, reviewable
/// event stream with **no** vendor SDK and no credentials in the repo, and a
/// vendor can be attached at startup without touching a single call site.
abstract class AnalyticsSink {
  /// Called once at startup, before any [log].
  Future<void> bootstrap();

  /// One event. [params] values are already primitives (String/num/bool).
  void log(String name, Map<String, dynamic> params);
}

/// Thin wrapper around analytics emission.
///
/// Events always route to `debugPrint` in debug builds so the event spec stays
/// visible locally and in CI logs. Beyond that, an event only leaves the device
/// when an [AnalyticsSink] has been [attach]ed — attaching *is* the opt-in.
/// Nothing attaches one by default, and [bootstrap] refuses to attach the
/// configured provider until `MonetizationConfig.analyticsEnabled` is flipped,
/// so the shipping default is "no telemetry".
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  AnalyticsSink? _sink;
  bool _bootstrapped = false;

  /// Whether events are currently reaching a real destination.
  bool get isForwarding => _sink != null;

  /// Attach the destination events are forwarded to. Call before [bootstrap].
  /// Passing `null` detaches (used by tests and by an opt-out).
  void attach(AnalyticsSink? sink) {
    _sink = sink;
    _bootstrapped = false;
  }

  /// Initialises the attached sink once. A sink attached after this returns is
  /// the caller's to bootstrap.
  ///
  /// Called from `main()`; with analytics disabled in config there is nothing
  /// to start up, so it returns immediately.
  Future<void> bootstrap() async {
    if (!MonetizationConfig.analyticsEnabled) return;
    final sink = _sink;
    if (sink == null || _bootstrapped) return;
    _bootstrapped = true;
    try {
      await sink.bootstrap();
    } catch (e) {
      // Analytics must never take the app down on startup.
      debugPrint('[analytics] sink bootstrap failed: $e');
      _bootstrapped = false;
    }
  }

  void logEvent(String name, [Map<String, dynamic> params = const {}]) {
    if (kDebugMode) {
      debugPrint('[analytics] $name $params');
    }
    final sink = _sink;
    if (sink == null) return;
    try {
      sink.log(name, params);
    } catch (e) {
      // A broken analytics provider must not break the feature that logged.
      debugPrint('[analytics] sink rejected $name: $e');
    }
  }

  // Domain-specific helpers — keep all event names + params in one place so the
  // schema stays consistent and reviewable.
  void logConvertUsed(String category) =>
      logEvent('convert_used', {'category': category});

  void logCalcUsed(String tool) => logEvent('calc_used', {'tool': tool});

  void logFinanceUsed(String tool) => logEvent('finance_used', {'tool': tool});

  void logToolUsed(String tool) => logEvent('tool_used', {'tool': tool});

  void logAdImpression(String slot, String format) =>
      logEvent('ad_impression', {'slot': slot, 'format': format});

  void logSheetShared(String format) =>
      logEvent('sheet_shared', {'format': format});

  void logAddToSheet(String tool) => logEvent('add_to_sheet', {'tool': tool});

  void logNotificationPermission(bool granted) =>
      logEvent('notification_permission', {'granted': granted});
}
