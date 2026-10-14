import 'package:agl_ads/agl_ads.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'monetization_config.dart';

/// AdMob wrapper using the real google_mobile_ads SDK.
///
/// Unit ids come from build-time `--dart-define=ADMOB_<FORMAT>_<PLATFORM>`
/// (see MonetizationConfig.resolveAdUnit): Google's test units in debug and
/// profile, and no ad at all in a release build that was not given a real one.
///
/// On web and in widget tests, every method gracefully no-ops.
class AdService {
  static final AdService instance = AdService._();
  AdService._();

  bool _initialized = false;
  int _interstitialCounter = 0;
  InterstitialAd? _cachedInterstitial;
  bool _loadingInterstitial = false;
  final Completer<void> _ready = Completer<void>();

  /// Completes when [bootstrap] has finished, whether or not it succeeded.
  /// `main()` only bootstraps after the ATT prompt is answered, so an ad slot
  /// built on the first screen waits on this rather than requesting early.
  Future<void> get ready => _ready.future;

  /// Single gate for ad loading. Previously this was
  /// `adsEnabled || _hasTestAds()`, and `_hasTestAds()` only checked that a
  /// unit ID string was non-empty — which is always true — so ads rendered
  /// even with `adsEnabled = false`. It now defers entirely to
  /// [MonetizationConfig.adsReady], which additionally requires a unit for
  /// this platform (a real one in release) and is false in SCREENSHOT builds,
  /// so a release build cannot ship test ads.
  bool get enabled {
    if (kIsWeb) return false;
    return MonetizationConfig.adsReady;
  }

  Future<void> bootstrap() async {
    if (kIsWeb || _initialized) return;
    if (_isInTest()) return;
    if (!enabled) {
      // No real ad units were compiled in, so no ad can ever be requested: do
      // not show the UMP consent form or start the ads SDK for nothing.
      // `ready` still completes so a banner slot waiting on it settles.
      if (!_ready.isCompleted) _ready.complete();
      return;
    }
    try {
      // AdMob policy: in the EEA, the UK and Switzerland an ad may not be
      // *requested* until the user has been asked — a non-personalised ad is
      // not a substitute. UMP decides whether a form is required from the
      // user's own location, so there is no geo-check here; everywhere else
      // it reports "not required" and this costs one no-op call.
      await AglConsent.gather();
      await MobileAds.instance.initialize();
      // Caches the answer for AglConsent.adsAllowed, which is what the
      // synchronous ad call sites below read.
      await AglConsent.refresh();
      _initialized = true;
    } catch (e) {
      // Initialization can fail on emulators without Google Play Services etc.
      debugPrint('[AdService] Mobile Ads init failed: $e');
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  String? bannerUnitId() {
    // No ad may be requested until UMP says consent allows it.
    if (!AglConsent.adsAllowed) return null;
    if (!enabled) return null;
    return MonetizationConfig.bannerUnit;
  }

  String? interstitialUnitId() {
    if (!enabled) return null;
    return MonetizationConfig.interstitialUnit;
  }

  String? nativeUnitId() {
    // No ad may be requested until UMP says consent allows it.
    if (!AglConsent.adsAllowed) return null;
    if (!enabled) return null;
    return MonetizationConfig.nativeUnit;
  }

  /// Builds a fresh BannerAd. Caller is responsible for calling `ad.load()`
  /// and disposing on widget dispose.
  BannerAd? createBannerAd(
      {required void Function(Ad) onAdLoaded,
      required void Function() onAdFailed}) {
    final unitId = bannerUnitId();
    if (unitId == null || _isInTest()) return null;
    return BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('[AdService] Banner failed to load: $error');
          onAdFailed();
        },
      ),
    );
  }

  /// Preload the next interstitial in the background so `showInterstitial`
  /// can fire immediately on its next eligible trigger.
  Future<void> preloadInterstitial() async {
    // No ad may be requested until UMP says consent allows it.
    if (!await AglConsent.canRequestAds()) return;
    if (kIsWeb || _isInTest()) return;
    if (_cachedInterstitial != null || _loadingInterstitial) return;
    final unitId = interstitialUnitId();
    if (unitId == null) return;
    _loadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _cachedInterstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Interstitial failed to load: $error');
          _loadingInterstitial = false;
        },
      ),
    );
  }

  /// Increments a session counter. Returns true every Nth call (default 5),
  /// signaling the caller it's time to display an interstitial.
  bool shouldShowInterstitial({int? every}) {
    _interstitialCounter += 1;
    final n = every ?? MonetizationConfig.interstitialEveryNUses;
    return _interstitialCounter % n == 0;
  }

  /// Show the cached interstitial (loads one if not yet cached). Triggers
  /// the next preload so subsequent shows are instant.
  Future<void> showInterstitial() async {
    if (kIsWeb || _isInTest()) return;
    if (_cachedInterstitial == null) {
      await preloadInterstitial();
      return; // skip this show — preload kicked off for next time
    }
    final ad = _cachedInterstitial!;
    _cachedInterstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('[AdService] Interstitial show failed: $error');
        preloadInterstitial();
      },
    );
    await ad.show();
  }

  static bool _isInTest() {
    try {
      return WidgetsBinding.instance.runtimeType
          .toString()
          .contains('AutomatedTestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }
}
