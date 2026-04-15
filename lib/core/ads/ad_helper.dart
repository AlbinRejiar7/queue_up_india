import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Initialises the Mobile Ads SDK.
///
/// Call once during app bootstrap, before any ad is loaded.
class AdHelper {
  AdHelper._();

  static bool _initialised = false;

  /// Initialise the Google Mobile Ads SDK.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  static Future<void> initialise() async {
    if (_initialised) {
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _initialised = true;
      debugPrint('[AdHelper] Mobile Ads SDK initialised.');
    } catch (error) {
      debugPrint('[AdHelper] Mobile Ads SDK init failed: $error');
    }
  }

  /// Whether the SDK has been initialised.
  static bool get isInitialised => _initialised;
}
