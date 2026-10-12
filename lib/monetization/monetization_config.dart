// =====================================================================
//  CALCMASTER · MONETIZATION CONFIG · SINGLE SOURCE OF TRUTH
// =====================================================================
//
// EVERY monetization credential, ID, URL, email and feature flag lives in
// THIS FILE only. No other Dart file in the project hard-codes a key.
//
// To go live in production:
//   1. Find each value marked  // REPLACE: <source>  below
//   2. Paste the real value
//   3. Flip the matching master switch at the top of the class to `true`
//
// Defaults are SAFE to ship today: ad unit IDs come from build-time
// --dart-define (release builds without them request no ads), RevenueCat
// keys are dummy strings, affiliate tags are dummies.
// Until the master switches are flipped to `true`, every service in
// `lib/monetization/` short-circuits cleanly and the app behaves as if
// monetization were absent.
// =====================================================================

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class MonetizationConfig {
  // ───────────────────────────────────────────────────────────────────
  //  MASTER SWITCHES — flip per-pillar after replacing values below
  // ───────────────────────────────────────────────────────────────────

  /// Show banner / interstitial / native ads in the app.
  /// Requires real AdMob unit IDs (see ADMOB section).
  static const bool adsEnabled = true;

  /// Show paywall + accept real in-app purchases via RevenueCat.
  /// Requires real RevenueCat key + IAP products in App Store Connect / Play Console.
  static const bool subscriptionsEnabled = true;

  /// Render affiliate CTA buttons inside detail screens + tag URLs.
  /// Requires real Amazon Associates (or other) tag.
  static const bool affiliatesEnabled = false;

  /// Forward in-app events to Firebase Analytics.
  /// Until then, every event is logged via debugPrint for inspection.
  static const bool analyticsEnabled = false;

  /// Subscribe device to FCM topics + show push notifications.
  /// Requires Firebase project + APNs auth key (iOS) + google-services.json (Android).
  static const bool fcmEnabled = false;

  // ───────────────────────────────────────────────────────────────────
  //  ADMOB · in-app advertising
  // ───────────────────────────────────────────────────────────────────
  // App IDs are REAL (AdMob plan, agl-manifest/docs/admob-ids.json).
  // Publisher: pub-8528784688453695 (see marketing/site/app-ads.txt).
  // Must match ios/Runner/Info.plist GADApplicationIdentifier and
  // android/.../AndroidManifest.xml APPLICATION_ID, or the SDK crashes on
  // init.
  static const String admobAppIdIos = 'ca-app-pub-8528784688453695~9148987425';
  static const String admobAppIdAndroid =
      'ca-app-pub-8528784688453695~5377349094';

  // Ad UNIT ids are not committed. CI passes them at build time as
  // --dart-define=ADMOB_<FORMAT>_<PLATFORM>=<id> (agl-manifest
  // scripts/agl_paths.py admob_defines). An empty define means: Google's test
  // unit in debug/profile, and NO ad at all in release — see [resolveAdUnit].
  static const String admobIosBanner = String.fromEnvironment('ADMOB_BANNER_IOS');
  static const String admobAndroidBanner =
      String.fromEnvironment('ADMOB_BANNER_ANDROID');

  static const String admobIosInterstitial =
      String.fromEnvironment('ADMOB_INTERSTITIAL_IOS');
  static const String admobAndroidInterstitial =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID');

  static const String admobIosNative = String.fromEnvironment('ADMOB_NATIVE_IOS');
  static const String admobAndroidNative =
      String.fromEnvironment('ADMOB_NATIVE_ANDROID');

  // Google's published test units, used only by debug/profile builds.
  // https://developers.google.com/admob/flutter/test-ads
  static const String testIosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const String testAndroidBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testIosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';
  static const String testAndroidInterstitial =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testIosNative = 'ca-app-pub-3940256099942544/3986624511';
  static const String testAndroidNative =
      'ca-app-pub-3940256099942544/2247696110';

  /// Store-screenshot builds (`--dart-define=SCREENSHOT=true`) never load ads.
  static const bool screenshotMode = bool.fromEnvironment('SCREENSHOT');

  // ───────────────────────────────────────────────────────────────────
  //  REVENUECAT · subscriptions
  // ───────────────────────────────────────────────────────────────────
  // REPLACE: app.revenuecat.com → Project → Apps → Public API key
  // Use the platform-specific key — RevenueCat's Flutter SDK requires both.
  static const String revenueCatIosKey =
      'appl_DUMMY_REPLACE_BEFORE_LAUNCH'; // REPLACE
  static const String revenueCatAndroidKey =
      'goog_DUMMY_REPLACE_BEFORE_LAUNCH'; // REPLACE

  // REPLACE: App Store Connect → My Apps → CalcMaster → In-App Purchases  AND
  //          Google Play Console → CalcMaster → Monetize → Products → Subscriptions
  // Both stores must use the SAME identifier strings as below.
  static const String productMonthly =
      'calcmaster_pro_monthly'; // REPLACE if different
  static const String productAnnual =
      'calcmaster_pro_annual'; // REPLACE if different
  static const String productLifetime =
      'calcmaster_pro_lifetime'; // REPLACE if different

  // REPLACE: the HTTPS endpoint of the backend that validates a store receipt
  // with Apple / Google and answers `{"entitled": true|false}`.
  // While this is empty, `PremiumProvider` trusts the store callback directly,
  // which a jailbroken/rooted device can forge. Set it (or pass `--dart-define
  // RECEIPT_VERIFICATION_URL=...` at build time) before taking real money.
  static const String receiptVerificationUrl = String.fromEnvironment(
    'RECEIPT_VERIFICATION_URL',
    defaultValue: '',
  );

  /// True when store receipts are checked by a trusted backend before Pro is
  /// granted. Surfaced in the diagnostics screen / release checks.
  static bool get receiptVerificationReady =>
      receiptVerificationUrl.startsWith('https://');

  // Prices are not configured here: the paywall shows the store's localized
  // price (`PremiumProvider.productFor(tier)?.price`) or "Price unavailable".

  // ───────────────────────────────────────────────────────────────────
  //  FIREBASE · analytics, crashlytics, FCM (re-engagement)
  // ───────────────────────────────────────────────────────────────────
  // REPLACE: console.firebase.google.com → CalcMaster project → Project settings
  // The real config travels in `ios/Runner/GoogleService-Info.plist` and
  // `android/app/google-services.json` — these dummies are for sanity-check
  // logs only.
  static const String firebaseProjectId = 'calcmaster-DUMMY-12345'; // REPLACE
  static const String firebaseSenderId = '0123456789'; // REPLACE

  // FCM topics the app subscribes to once the user opts in to notifications.
  static const List<String> fcmTopics = [
    'daily_tip',
    'rate_alerts',
    'reengagement'
  ];

  // ───────────────────────────────────────────────────────────────────
  //  AFFILIATE PARTNERS
  // ───────────────────────────────────────────────────────────────────
  // REPLACE: affiliate-program.amazon.com → tag (e.g. "myname-20")
  // One tag per region; falls back to US tag when a region-specific tag
  // is empty.
  static const String amazonAssociatesTagUS = 'calcmaster-20'; // REPLACE
  static const String amazonAssociatesTagUK = 'calcmaster-21'; // REPLACE
  static const String amazonAssociatesTagIN = 'calcmaster-21'; // REPLACE

  // Optional: meal-delivery / wellness affiliate URLs. Replace with real
  // tracking URLs from your partner dashboards.
  static const String mealKitAffiliateUrl =
      ''; // REPLACE: set real meal-kit affiliate URL
  static const String wellnessSubscriptionUrl =
      ''; // REPLACE: set real wellness affiliate URL

  // Per-slot Amazon search URLs — used by `AffiliateService.urlFor()`.
  // The `?tag=...` query param is appended automatically based on region.
  // REPLACE with concrete product detail page URLs to maximise conversion.
  static const Map<String, String> affiliateSlots = {
    'volume_buy_measuring_set': 'https://www.amazon.com/s?k=measuring+cup+set',
    'bmi_smart_scale': 'https://www.amazon.com/s?k=smart+scale',
    'compound_savings_account':
        'https://www.amazon.com/s?k=high+yield+savings+book',
    'tax_book': 'https://www.amazon.com/s?k=tax+guide',
    'cooking_scale': 'https://www.amazon.com/s?k=kitchen+scale',
    '_fallback': 'https://www.amazon.com/',
  };

  // ───────────────────────────────────────────────────────────────────
  //  LEGAL / SUPPORT
  // ───────────────────────────────────────────────────────────────────
  // Served from marketing/site/ by .github/workflows/pages.yml. These MUST be
  // real pages: americangroup.ai is a catch-all SPA that returns the American
  // Group corporate homepage for every path, so the old /privacy-policy and
  // /terms links resolved 200 with the wrong content — an automatic App Store
  // rejection under Guideline 5.1.1.
  static const String privacyPolicyUrl =
      'https://www.americangroup.ai/policy/calcmaster/';
  static const String termsOfServiceUrl =
      'https://www.americangroup.ai/policy/calcmaster/terms.html';
  static const String supportEmail = 'contact@americangroup.ai';
  static const String marketingWebsite = 'https://www.americangroup.ai/';
  static const String appStoreUrl =
      'https://apps.apple.com/app/calcmaster/id0000000000'; // REPLACE after listing
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.americangroupllc.calcmaster'; // REPLACE

  // ───────────────────────────────────────────────────────────────────
  //  TUNING — safe to leave at defaults
  // ───────────────────────────────────────────────────────────────────

  /// Show an interstitial after every Nth use of any tool/calculator.
  static const int interstitialEveryNUses = 5;

  /// Currency rates auto-refresh interval for free-tier users.
  static const Duration freeRateRefreshInterval = Duration(hours: 24);

  /// Currency rates auto-refresh interval for Pro subscribers.
  static const Duration proRateRefreshInterval = Duration(minutes: 15);

  /// Maximum notification frequency to avoid annoying users.
  static const int maxPushNotificationsPerDay = 2;

  // ───────────────────────────────────────────────────────────────────
  //  COMPUTED — used by the rest of the app, do not edit
  // ───────────────────────────────────────────────────────────────────

  /// Google's official test publisher. Any unit ID carrying this prefix serves
  /// "Test Ad" placeholders and earns nothing.
  static const String _testAdPublisher = 'ca-app-pub-3940256099942544';

  /// The unit to request for one format on one platform.
  ///
  /// [define] is the `ADMOB_<FORMAT>_<PLATFORM>` value baked in at build time.
  /// Release builds request only a real unit: an empty define — or a Google
  /// test unit passed by mistake — yields null, i.e. no ad. Debug/profile
  /// builds fall back to [testUnit] so the slot can be exercised locally.
  static String? resolveAdUnit(
    String define,
    String testUnit, {
    bool releaseMode = kReleaseMode,
  }) {
    if (releaseMode) {
      if (define.isEmpty || define.startsWith(_testAdPublisher)) return null;
      return define;
    }
    return define.isNotEmpty ? define : testUnit;
  }

  /// true on iOS, false on Android, null anywhere AdMob does not run.
  static bool? get _isIos {
    if (kIsWeb) return null;
    try {
      if (Platform.isIOS) return true;
      if (Platform.isAndroid) return false;
    } catch (_) {}
    return null;
  }

  static String? _unitForPlatform(
      String iosDefine, String androidDefine, String iosTest, String androidTest) {
    final ios = _isIos;
    if (ios == null) return null;
    return ios
        ? resolveAdUnit(iosDefine, iosTest)
        : resolveAdUnit(androidDefine, androidTest);
  }

  static String? get bannerUnit => _unitForPlatform(
      admobIosBanner, admobAndroidBanner, testIosBanner, testAndroidBanner);
  static String? get interstitialUnit => _unitForPlatform(admobIosInterstitial,
      admobAndroidInterstitial, testIosInterstitial, testAndroidInterstitial);
  static String? get nativeUnit => _unitForPlatform(
      admobIosNative, admobAndroidNative, testIosNative, testAndroidNative);

  /// True when this build was given a live (non-test) banner unit for at least
  /// one platform. Banner is the only format the app renders (`BannerAdSlot`
  /// in `tab_scaffold.dart`); interstitial/native have no call sites.
  static bool get adUnitsAreReal => [admobIosBanner, admobAndroidBanner]
      .any((id) => id.isNotEmpty && !id.startsWith(_testAdPublisher));

  /// The single source of truth for "should this build serve ads at all".
  /// Requires the master switch, real app IDs, not a screenshot build, and a
  /// banner unit for this platform (a real one in release).
  static bool get adsReady =>
      adsEnabled &&
      !screenshotMode &&
      admobAppIdIos.isNotEmpty &&
      admobAppIdAndroid.isNotEmpty &&
      bannerUnit != null;

  /// True only when subscriptions are enabled AND a real RevenueCat key is in
  /// place (i.e. the dummy `_DUMMY_` marker has been removed).
  static bool get subscriptionsReady =>
      subscriptionsEnabled &&
      !revenueCatIosKey.contains('DUMMY') &&
      !revenueCatAndroidKey.contains('DUMMY');

  /// True when at least one affiliate tag has been replaced from the dummy.
  static bool get affiliatesReady =>
      affiliatesEnabled && !amazonAssociatesTagUS.contains('DUMMY');
}
