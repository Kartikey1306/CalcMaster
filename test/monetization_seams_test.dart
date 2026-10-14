import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/monetization/analytics_service.dart';
import 'package:calcmaster/monetization/monetization_config.dart';
import 'package:calcmaster/monetization/notification_service.dart';

/// The seams that used to be `TODO(monetization)` markers: analytics
/// forwarding and push permission/topics. (Store receipt verification went
/// with the Pro paywall: CalcMaster sells nothing.)
///
/// Each is an injected interface rather than a hard vendor dependency, so the
/// behaviour that actually matters — "nothing leaves the device unless someone
/// attached a destination" — is asserted here instead of being taken on trust.

class _RecordingSink implements AnalyticsSink {
  final events = <({String name, Map<String, dynamic> params})>[];
  int bootstraps = 0;
  final bool throwOnLog;

  _RecordingSink({this.throwOnLog = false});

  @override
  Future<void> bootstrap() async => bootstraps++;

  @override
  void log(String name, Map<String, dynamic> params) {
    if (throwOnLog) throw StateError('sink is broken');
    events.add((name: name, params: params));
  }
}

class _FakePushTransport implements PushTransport {
  final bool grant;
  final bool explode;
  final subscribed = <String>[];
  final unsubscribed = <String>[];
  int requests = 0;

  _FakePushTransport({this.grant = true, this.explode = false});

  @override
  Future<bool> requestPermission() async {
    requests++;
    if (explode) throw StateError('no APNs token');
    return grant;
  }

  @override
  Future<void> subscribe(String topic) async => subscribed.add(topic);

  @override
  Future<void> unsubscribe(String topic) async => unsubscribed.add(topic);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AnalyticsService', () {
    tearDown(() => AnalyticsService.instance.attach(null));

    test('forwards nothing while no sink is attached', () {
      AnalyticsService.instance.attach(null);
      expect(AnalyticsService.instance.isForwarding, isFalse);
      // The only assertion that matters here is that this does not throw and
      // has nowhere to send the event.
      AnalyticsService.instance.logAddToSheet('tip');
    });

    test('forwards the documented event schema to an attached sink', () {
      final sink = _RecordingSink();
      AnalyticsService.instance.attach(sink);
      expect(AnalyticsService.instance.isForwarding, isTrue);

      AnalyticsService.instance.logAddToSheet('tip');
      AnalyticsService.instance.logSheetShared('csv');

      expect(sink.events.map((e) => e.name), ['add_to_sheet', 'sheet_shared']);
      expect(sink.events.first.params, {'tool': 'tip'});
      expect(sink.events.last.params, {'format': 'csv'});
    });

    test('a throwing sink cannot break the feature that logged', () {
      AnalyticsService.instance.attach(_RecordingSink(throwOnLog: true));
      expect(
          () => AnalyticsService.instance.logSheetShared('text'), returnsNormally);
    });

    test('bootstrap stays inert while analytics are disabled in config',
        () async {
      // Guards the shipping default: main() calls bootstrap() unconditionally.
      expect(MonetizationConfig.analyticsEnabled, isFalse);
      final sink = _RecordingSink();
      AnalyticsService.instance.attach(sink);
      await AnalyticsService.instance.bootstrap();
      expect(sink.bootstraps, 0);
    });
  });

  group('NotificationService', () {
    tearDown(() => NotificationService.instance.attach(null));

    test('with no transport, the opt-in is purely local', () async {
      NotificationService.instance.attach(null);
      expect(NotificationService.instance.isLive, isFalse);
      expect(await NotificationService.instance.requestPermission(), isFalse);

      await NotificationService.instance.setEnabled(enabled: true);
      expect(await NotificationService.instance.requestPermission(), isTrue);
    });

    test('a granted request is persisted', () async {
      final transport = _FakePushTransport(grant: true);
      NotificationService.instance.attach(transport);

      expect(await NotificationService.instance.requestPermission(), isTrue);
      expect(transport.requests, 1);
      expect(await NotificationService.instance.isEnabled(), isTrue);
    });

    test('a denied request does not record an opt-in', () async {
      NotificationService.instance.attach(_FakePushTransport(grant: false));
      await NotificationService.instance.setEnabled(enabled: true);

      expect(await NotificationService.instance.requestPermission(), isFalse);
      expect(await NotificationService.instance.isEnabled(), isFalse,
          reason: 'a denial must clear the stored opt-in');
    });

    test('a failed request is not a grant', () async {
      NotificationService.instance.attach(_FakePushTransport(explode: true));
      expect(await NotificationService.instance.requestPermission(), isFalse);
    });

    test('topics are only joined by a user who opted in', () async {
      final transport = _FakePushTransport();
      NotificationService.instance.attach(transport);

      await NotificationService.instance.subscribe('deals');
      expect(transport.subscribed, isEmpty, reason: 'not opted in yet');

      await NotificationService.instance.setEnabled(enabled: true);
      await NotificationService.instance.subscribe('deals');
      expect(transport.subscribed, ['deals']);

      // Leaving a topic must work even after opting out.
      await NotificationService.instance.setEnabled(enabled: false);
      await NotificationService.instance.unsubscribe('deals');
      expect(transport.unsubscribed, ['deals']);
    });
  });
}
