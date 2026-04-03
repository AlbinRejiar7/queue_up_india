import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_preferences.dart';

class PullToRefreshHint extends StatefulWidget {
  const PullToRefreshHint({
    required this.preferenceKey,
    required this.child,
    super.key,
    this.topPadding = 12,
  });

  final String preferenceKey;
  final Widget child;
  final double topPadding;

  @override
  State<PullToRefreshHint> createState() => _PullToRefreshHintState();
}

class _PullToRefreshHintState extends State<PullToRefreshHint>
    with SingleTickerProviderStateMixin {
  static const Duration _showDelay = Duration(milliseconds: 500);
  static const Duration _showDuration = Duration(seconds: 3);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  Timer? _showTimer;
  Timer? _hideTimer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _scheduleHintIfNeeded();
  }

  Future<void> _scheduleHintIfNeeded() async {
    final hasSeen = await AppPreferences.hasSeenPullToRefreshHint(
      widget.preferenceKey,
    );
    if (!mounted || hasSeen) {
      return;
    }

    _showTimer = Timer(_showDelay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isVisible = true;
      });
      _controller.repeat(reverse: true);
      _hideTimer = Timer(_showDuration, () async {
        if (!mounted) {
          return;
        }
        _controller.stop();
        setState(() {
          _isVisible = false;
        });
        await AppPreferences.markPullToRefreshHintSeen(widget.preferenceKey);
      });
    });
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned(
          top: widget.topPadding.h,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _isVisible ? 1 : 0,
              duration: const Duration(milliseconds: 280),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 9.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: AppColors.electricBlue.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final dy = math.sin(_controller.value * math.pi) * 8;
                          return Transform.translate(
                            offset: Offset(0, dy),
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.keyboard_double_arrow_down_rounded,
                          size: 18.sp,
                          color: AppColors.electricBlue,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        AppStrings.pullToRefreshHint,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
