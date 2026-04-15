import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralised ad-unit ID registry.
///
/// Ad unit IDs are now loaded from the .env file.
abstract final class AdIds {
  static bool get _useTestIds => dotenv.get('ADMOB_USE_TEST_IDS', fallback: 'true') == 'true';

  static String get bannerId {
    if (_useTestIds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? dotenv.get('ADMOB_BANNER_ANDROID_ID')
        : dotenv.get('ADMOB_BANNER_IOS_ID');
  }

  static String get interstitialId {
    if (_useTestIds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? dotenv.get('ADMOB_INTERSTITIAL_ANDROID_ID')
        : dotenv.get('ADMOB_INTERSTITIAL_IOS_ID');
  }

  static String get rewardedId {
    if (_useTestIds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid
        ? dotenv.get('ADMOB_REWARDED_ANDROID_ID')
        : dotenv.get('ADMOB_REWARDED_IOS_ID');
  }

  static String get appOpenId {
    if (_useTestIds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9257395921'
          : 'ca-app-pub-3940256099942544/5575463023';
    }
    return Platform.isAndroid
        ? dotenv.get('ADMOB_APPOPEN_ANDROID_ID')
        : dotenv.get('ADMOB_APPOPEN_IOS_ID');
  }

  static String get nativeId {
    if (_useTestIds) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110'
          : 'ca-app-pub-3940256099942544/3986624511';
    }
    return Platform.isAndroid
        ? dotenv.get('ADMOB_NATIVE_ANDROID_ID')
        : dotenv.get('ADMOB_NATIVE_IOS_ID');
  }
}
