import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Manages loading and showing of interstitial ads with a cooldown to avoid
/// spamming the user.
class InterstitialAdManager {
  InterstitialAdManager._();
  static final InterstitialAdManager instance = InterstitialAdManager._();

  /// Minimum gap between two interstitial shows.
  static const Duration cooldown = Duration(seconds: 60);

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  DateTime? _lastShownAt;

  /// Pre-load an interstitial ad.
  void loadAd() {
    if (_interstitialAd != null || _isLoading) {
      return;
    }
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isLoading = false;
          debugPrint('[InterstitialAd] Loaded.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          debugPrint('[InterstitialAd] Failed to load: $error');
        },
      ),
    );
  }

  /// Show an interstitial ad if one is loaded and the cooldown has elapsed.
  ///
  /// [onAdDismissed] is called after the user closes the ad (or if no ad is
  /// available), so navigation can continue.
  void showAd({VoidCallback? onAdDismissed}) {
    // Enforce cooldown.
    if (_lastShownAt != null &&
        DateTime.now().difference(_lastShownAt!) < cooldown) {
      debugPrint('[InterstitialAd] Cooldown active — skipping.');
      onAdDismissed?.call();
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('[InterstitialAd] Not loaded — skipping.');
      loadAd();
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('[InterstitialAd] Dismissed.');
        ad.dispose();
        _interstitialAd = null;
        _lastShownAt = DateTime.now();
        loadAd(); // Pre-load next.
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('[InterstitialAd] Failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        loadAd();
        onAdDismissed?.call();
      },
    );

    _interstitialAd!.show();
  }
}
