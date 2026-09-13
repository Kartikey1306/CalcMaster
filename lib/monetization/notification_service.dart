import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

/// The platform side of push: requesting the OS permission and managing topic
/// subscriptions.
///
/// This app deliberately ships no messaging SDK (no `firebase_messaging`, no
/// Firebase config files — see `MonetizationConfig.fcmEnabled`). The transport
/// is an injected [PushTransport] instead, so the opt-in bookkeeping below is
/// real and testable and a provider can be attached at startup without editing
/// a call site.
abstract class PushTransport {
  /// Ask the OS for notification permission (and register for APNs on iOS).
  /// Returns whether permission was granted.
  Future<bool> requestPermission();

  /// Subscribe / unsubscribe this device from a re-engagement topic.
  Future<void> subscribe(String topic);
  Future<void> unsubscribe(String topic);
}

/// Permission + topic bookkeeping for push notifications.
///
/// The user's opt-in choice is always persisted locally. Attaching a
/// [PushTransport] is what makes push real: with one attached, permission
/// requests and topic subscriptions are forwarded to it; with none attached
/// every method resolves from the persisted opt-in and nothing leaves the
/// device. Nothing attaches a transport while
/// `MonetizationConfig.fcmEnabled` is false, which is the shipping default.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static const _kEnabled = '@calcmaster/notifications_enabled';

  PushTransport? _transport;

  /// Whether a real push transport is attached.
  bool get isLive => _transport != null;

  /// Attach the platform transport. Callers must gate this on
  /// `MonetizationConfig.fcmEnabled`. Passing `null` detaches.
  void attach(PushTransport? transport) => _transport = transport;

  Future<bool> isEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kEnabled) ?? false;
  }

  Future<void> setEnabled({required bool enabled}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kEnabled, enabled);
    AnalyticsService.instance.logNotificationPermission(enabled);
  }

  /// Request OS-level permission. With no transport attached this reports the
  /// persisted opt-in rather than claiming a grant it never obtained.
  ///
  /// A grant is persisted so the rest of the app can read it synchronously via
  /// [isEnabled]; a denial clears it.
  Future<bool> requestPermission() async {
    final transport = _transport;
    if (transport == null) return isEnabled();
    bool granted;
    try {
      granted = await transport.requestPermission();
    } catch (_) {
      // A failed request is not a grant.
      return false;
    }
    await setEnabled(enabled: granted);
    return granted;
  }

  /// Subscribe to a topic for re-engagement messages. Refuses to subscribe a
  /// user who has not opted in, so an accidental call cannot re-enable push
  /// behind their back.
  Future<void> subscribe(String topic) async {
    final transport = _transport;
    if (transport == null) return;
    if (!await isEnabled()) return;
    try {
      await transport.subscribe(topic);
    } catch (_) {
      // Topic membership is best-effort; a failure must not break the caller.
    }
  }

  /// Remove this device from a topic. Safe to call when opted out — that is
  /// exactly when it matters.
  Future<void> unsubscribe(String topic) async {
    final transport = _transport;
    if (transport == null) return;
    try {
      await transport.unsubscribe(topic);
    } catch (_) {
      // Best-effort, as above.
    }
  }
}
