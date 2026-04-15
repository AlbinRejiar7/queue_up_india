import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Manages loading and showing of App Open ads.
///
/// App Open ads are shown:
/// - Once on cold start (after bootstrap).
/// - When the app resumes from background after [_backgroundThreshold].
class AppOpenAdManager {
  AppOpenAdManager._();
  static final AppOpenAdManager instance = AppOpenAdManager._();

  static const Duration _backgroundThreshold = Duration(seconds: 30);
  static const Duration _adExpiry = Duration(hours: 4);

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _adLoadTime;
  DateTime? _lastBackgroundedAt;

  /// Pre-load an App Open ad so it is ready to show immediately.
  void loadAd() {
    AppOpenAd.load(
      adUnitId: AdIds.appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          _appOpenAd = ad;
          _adLoadTime = DateTime.now();
          debugPrint('[AppOpenAd] Ad loaded.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AppOpenAd] Failed to load: $error');
          _appOpenAd = null;
        },
      ),
    );
  }

  /// Record when the app goes to background.
  void onAppBackgrounded() {
    _lastBackgroundedAt = DateTime.now();
  }

  /// Show the App Open ad if the app was in background long enough.
  ///
  /// Returns `true` if the ad was shown, `false` otherwise.
  bool showAdIfAvailable() {
    if (_isShowingAd) {
      return false;
    }
    if (_appOpenAd == null) {
      loadAd();
      return false;
    }
    // Don't show if the ad has expired.
    if (_adLoadTime != null &&
        DateTime.now().difference(_adLoadTime!) > _adExpiry) {
      _appOpenAd?.dispose();
      _appOpenAd = null;
      loadAd();
      return false;
    }

    _isShowingAd = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (AppOpenAd ad) {
        debugPrint('[AppOpenAd] Showed.');
      },
      onAdDismissedFullScreenContent: (AppOpenAd ad) {
        debugPrint('[AppOpenAd] Dismissed.');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // Pre-load the next one.
      },
      onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
        debugPrint('[AppOpenAd] Failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
    return true;
  }

  /// Try to show an ad on app resume.  Only shows if the user was
  /// backgrounded for at least [_backgroundThreshold].
  bool tryShowOnResume() {
    if (_lastBackgroundedAt == null) {
      return false;
    }
    final backgroundDuration =
        DateTime.now().difference(_lastBackgroundedAt!);
    if (backgroundDuration < _backgroundThreshold) {
      return false;
    }
    return showAdIfAvailable();
  }
}
