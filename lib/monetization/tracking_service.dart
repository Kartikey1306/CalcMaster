import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'analytics_service.dart';

/// iOS App Tracking Transparency (ATT) prompt manager.
///
/// The AdMob SDK links ATTrackingManager, so Apple expects the ATT prompt to
/// appear before anything that could track the user — in this app, before the
/// ads SDK starts. `main()` calls [requestWhenActive] right after `runApp` and
/// only bootstraps ads once it completes.
///
/// iOS only presents the system alert while the app is active. A request made
/// earlier — in `main()`, before the first frame, or while another system
/// sheet is up — returns without ever showing it, which is how App Review saw
/// no prompt. So the request waits for the first frame and a resumed
/// lifecycle, and if iOS still reports notDetermined afterwards (the request
/// was swallowed) it asks again on the next resume.
///
/// On Android + web this class is a no-op.
class TrackingService {
  static final TrackingService instance = TrackingService._();
  TrackingService._();

  /// Gives the first screen time to settle after it becomes active; a request
  /// issued in the same instant the scene activates can still be dropped.
  static const _settleDelay = Duration(seconds: 1);

  Future<TrackingStatus>? _inFlight;
  AppLifecycleListener? _retryListener;

  /// Shows the ATT prompt once the first frame is on screen and the app is
  /// active, and completes with the user's answer. Safe to call multiple
  /// times — iOS itself never shows the prompt again once it is answered.
  Future<TrackingStatus> requestWhenActive() {
    if (!_isIOS) return Future.value(TrackingStatus.notSupported);
    return _inFlight ??= _requestWhenActive();
  }

  Future<TrackingStatus> _requestWhenActive() async {
    await WidgetsBinding.instance.endOfFrame;
    final result = await _requestOnceActive();
    if (result == TrackingStatus.notDetermined) {
      // iOS swallowed the request. Until it is answered the advertising
      // identifier stays zeroed, so nothing can track; ask again on the next
      // resume rather than blocking the caller indefinitely.
      _retryListener ??= AppLifecycleListener(onResume: () async {
        final status = await _requestOnceActive();
        if (status != TrackingStatus.notDetermined) {
          _retryListener?.dispose();
          _retryListener = null;
        }
      });
    }
    return result;
  }

  Future<TrackingStatus> _requestOnceActive() async {
    await _untilResumed();
    await Future<void>.delayed(_settleDelay);
    final current = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (current != TrackingStatus.notDetermined) return current;

    final result = await AppTrackingTransparency.requestTrackingAuthorization();
    AnalyticsService.instance.logEvent('att_prompt_result', {
      'status': result.toString(),
    });
    return result;
  }

  static Future<void> _untilResumed() {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return Future<void>.value();
    }
    final resumed = Completer<void>();
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(onStateChange: (state) {
      if (state != AppLifecycleState.resumed) return;
      listener.dispose();
      if (!resumed.isCompleted) resumed.complete();
    });
    return resumed.future;
  }

  static bool get _isIOS {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }
}
