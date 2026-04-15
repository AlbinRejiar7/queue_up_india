import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Manages rewarded ads (opt-in video ads that give the user a reward).
class RewardedAdManager {
  RewardedAdManager._();
  static final RewardedAdManager instance = RewardedAdManager._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  /// Whether a rewarded ad is ready to show.
  bool get isAdReady => _rewardedAd != null;

  /// Pre-load a rewarded ad.
  void loadAd() {
    if (_rewardedAd != null || _isLoading) {
      return;
    }
    _isLoading = true;
    RewardedAd.load(
      adUnitId: AdIds.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint('[RewardedAd] Loaded.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          debugPrint('[RewardedAd] Failed to load: $error');
        },
      ),
    );
  }

  /// Show the rewarded ad.
  ///
  /// [onRewarded] is called when the user earns the reward (watched the
  /// full video). [onAdDismissed] is always called when the ad is closed —
  /// use it to continue navigation regardless of reward outcome.
  void showAd({
    required void Function(RewardItem reward) onRewarded,
    VoidCallback? onAdDismissed,
  }) {
    if (_rewardedAd == null) {
      debugPrint('[RewardedAd] Not loaded — requesting load.');
      loadAd();
      onAdDismissed?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('[RewardedAd] Dismissed.');
        ad.dispose();
        _rewardedAd = null;
        loadAd(); // Pre-load next.
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('[RewardedAd] Failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        loadAd();
        onAdDismissed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint(
          '[RewardedAd] User earned reward: ${reward.amount} ${reward.type}',
        );
        onRewarded(reward);
      },
    );
  }
}
