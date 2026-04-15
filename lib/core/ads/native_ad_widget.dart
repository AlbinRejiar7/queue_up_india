import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../constants/app_colors.dart';
import 'ad_ids.dart';

/// A native ad widget styled to blend with QueueUp's card UI.
///
/// Designed for insertion into scrollable lists (every 5-8 items).
/// The ad renders inside a glass-style container that matches the
/// app's visual language.
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AdIds.nativeId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('[NativeAd] Failed to load: $error');
          ad.dispose();
          _nativeAd = null;
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: AppColors.surface,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          size: 14,
          textColor: AppColors.textPrimary,
          backgroundColor: AppColors.electricBlue,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          size: 14,
          textColor: AppColors.textPrimary,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          size: 12,
          textColor: AppColors.textSecondary,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          size: 10,
          textColor: AppColors.textSecondary,
        ),
      ),
    );
    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.electricBlue.withValues(alpha: 0.15),
        ),
      ),
      constraints: BoxConstraints(
        minWidth: 320.w,
        minHeight: 90.h,
        maxHeight: 120.h,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
