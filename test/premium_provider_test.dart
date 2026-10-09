import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calcmaster/monetization/premium_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PremiumProvider', () {
    test('default isPro is false', () async {
      final p = PremiumProvider();
      // Wait one microtask for hydration to complete.
      await Future<void>.delayed(Duration.zero);
      expect(p.isPro, isFalse);
    });

    test('purchase returns false when subscriptions disabled', () async {
      final p = PremiumProvider();
      await Future<void>.delayed(Duration.zero);
      final ok = await p.purchase(SubscriptionTier.annual);
      expect(ok, isFalse);
      expect(p.isPro, isFalse);
    });

    test('restore returns false when subscriptions disabled', () async {
      final p = PremiumProvider();
      await Future<void>.delayed(Duration.zero);
      final ok = await p.restore();
      expect(ok, isFalse);
    });

    test('setIsProForTest flips entitlement and persists', () async {
      final p = PremiumProvider();
      await Future<void>.delayed(Duration.zero);
      await p.setIsProForTest(true);
      expect(p.isPro, isTrue);

      // New instance hydrates from the same SharedPreferences mock.
      final p2 = PremiumProvider();
      await Future<void>.delayed(Duration.zero);
      expect(p2.isPro, isTrue);
    });
  });
}
