import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/monetization/analytics_service.dart';
import 'package:calcmaster/monetization/monetization_config.dart';
import 'package:calcmaster/monetization/notification_service.dart';
import 'package:calcmaster/monetization/premium_provider.dart';

/// The three seams that used to be `TODO(monetization)` markers: analytics
/// forwarding, push permission/topics, and store receipt verification.
///
/// Each is an injected interface rather than a hard vendor dependency, so the
/// behaviour that actually matters — "nothing leaves the device unless someone
/// attached a destination", and "no entitlement without a verified receipt" —
/// is asserted here instead of being taken on trust.

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

class _FixedVerifier implements ReceiptVerifier {
  final bool answer;
  final bool explode;
  int calls = 0;
  _FixedVerifier(this.answer, {this.explode = false});

  @override
  Future<bool> verify(PurchaseDetails purchase) async {
    calls++;
    if (explode) throw StateError('backend unreachable');
    return answer;
  }
}

PurchaseDetails _purchase(PurchaseStatus status) => PurchaseDetails(
      purchaseID: 'txn-1',
      productID: MonetizationConfig.productAnnual,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server-receipt',
        source: 'app_store',
      ),
      transactionDate: '0',
      status: status,
    );

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
      AnalyticsService.instance.logTabOpen('convert');
    });

    test('forwards the documented event schema to an attached sink', () {
      final sink = _RecordingSink();
      AnalyticsService.instance.attach(sink);
      expect(AnalyticsService.instance.isForwarding, isTrue);

      AnalyticsService.instance.logTabOpen('finance');
      AnalyticsService.instance.logPurchaseCompleted('calcmaster_pro_annual');

      expect(
          sink.events.map((e) => e.name), ['tab_open', 'purchase_completed']);
      expect(sink.events.first.params, {'name': 'finance'});
      expect(sink.events.last.params, {'product_id': 'calcmaster_pro_annual'});
    });

    test('a throwing sink cannot break the feature that logged', () {
      AnalyticsService.instance.attach(_RecordingSink(throwOnLog: true));
      expect(
          () => AnalyticsService.instance.logTabOpen('tools'), returnsNormally);
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

  group('receipt verification', () {
    test('an unverified purchase grants nothing', () async {
      final provider = PremiumProvider();
      await Future<void>.delayed(Duration.zero);
      final verifier = _FixedVerifier(false);
      provider.attachVerifier(verifier);

      await provider.handlePurchaseForTest(_purchase(PurchaseStatus.purchased));

      expect(verifier.calls, 1);
      expect(provider.isPro, isFalse);
      expect(provider.lastError, isNotNull);
    });

    test('an unreachable verifier fails closed', () async {
      final provider = PremiumProvider();
      await Future<void>.delayed(Duration.zero);
      provider.attachVerifier(_FixedVerifier(true, explode: true));

      await provider.handlePurchaseForTest(_purchase(PurchaseStatus.purchased));
      expect(provider.isPro, isFalse);
    });

    test('a verified purchase grants and persists Pro', () async {
      final provider = PremiumProvider();
      await Future<void>.delayed(Duration.zero);
      provider.attachVerifier(_FixedVerifier(true));

      await provider.handlePurchaseForTest(_purchase(PurchaseStatus.purchased));
      expect(provider.isPro, isTrue);

      final reopened = PremiumProvider();
      await Future<void>.delayed(Duration.zero);
      expect(reopened.isPro, isTrue);
    });

    test('a restore is verified the same way as a purchase', () async {
      final provider = PremiumProvider();
      await Future<void>.delayed(Duration.zero);
      provider.attachVerifier(_FixedVerifier(false));

      await provider.handlePurchaseForTest(_purchase(PurchaseStatus.restored),
          restored: true);
      expect(provider.isPro, isFalse);
    });
  });

  group('HttpReceiptVerifier', () {
    test('posts the store receipt and grants on an entitled answer', () async {
      late Map<String, dynamic> sent;
      final verifier = HttpReceiptVerifier(
        'https://example.test/verify',
        client: MockClient((req) async {
          sent = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('{"entitled": true}', 200);
        }),
      );

      expect(
          await verifier.verify(_purchase(PurchaseStatus.purchased)), isTrue);
      expect(sent['receipt'], 'server-receipt');
      expect(sent['productId'], MonetizationConfig.productAnnual);
      expect(sent['transactionId'], 'txn-1');
    });

    test('refuses on a negative answer, an error, or junk', () async {
      Future<bool> answer(http.Response response) => HttpReceiptVerifier(
            'https://example.test/verify',
            client: MockClient((_) async => response),
          ).verify(_purchase(PurchaseStatus.purchased));

      expect(await answer(http.Response('{"entitled": false}', 200)), isFalse);
      expect(await answer(http.Response('{"entitled": true}', 500)), isFalse);
      expect(await answer(http.Response('not json', 200)), isFalse);
      expect(await answer(http.Response('"entitled"', 200)), isFalse);
    });

    test('a transport failure is not an entitlement', () async {
      final verifier = HttpReceiptVerifier(
        'https://example.test/verify',
        client: MockClient((_) async {
          throw const SocketExceptionStub();
        }),
      );
      expect(
          await verifier.verify(_purchase(PurchaseStatus.purchased)), isFalse);
    });
  });

  test('the config exposes whether receipts are actually checked', () {
    // Unset by default; `env/*.json` carries the key so a release build must
    // make a deliberate choice.
    expect(MonetizationConfig.receiptVerificationUrl, isEmpty);
    expect(MonetizationConfig.receiptVerificationReady, isFalse);
  });
}

/// A stand-in for a network failure that does not need `dart:io`.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
