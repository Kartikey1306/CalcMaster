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
// Ad unit IDs come from build-time --dart-define (release builds without
// them request no ads). CalcMaster sells nothing: there are no in-app
// purchases, subscriptions or partner links in this app.
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
  /// at the foot of the Sheets list and the Tools drawer — never on the sheet
  /// editor); interstitial/native have no call sites.
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
}
