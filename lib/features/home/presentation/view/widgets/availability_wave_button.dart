import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';

class AvailabilityWaveButton extends StatefulWidget {
  const AvailabilityWaveButton({
    required this.isAvailable,
    required this.enabled,
    required this.onPressed,
    required this.diameter,
    super.key,
  });

  static const double waveScale = 1.72;

  final bool isAvailable;
  final bool enabled;
  final VoidCallback onPressed;
  final double diameter;

  @override
  State<AvailabilityWaveButton> createState() => _AvailabilityWaveButtonState();
}

class _AvailabilityWaveButtonState extends State<AvailabilityWaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AvailabilityWaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAvailable != widget.isAvailable) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.enabled && widget.isAvailable) {
      _controller.repeat();
      return;
    }
    _controller
      ..stop()
      ..value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waveAreaSize = widget.diameter * AvailabilityWaveButton.waveScale;

    return GestureDetector(
      onTap: widget.enabled ? widget.onPressed : null,
      child: SizedBox(
        width: waveAreaSize,
        height: waveAreaSize,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final progress = _controller.value;
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (widget.enabled && widget.isAvailable) ...<Widget>[
                  _buildWave(progress, phase: 0.0),
                  _buildWave(progress, phase: 0.34),
                  _buildWave(progress, phase: 0.68),
                ],
                child!,
              ],
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: widget.diameter,
            height: widget.diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: !widget.enabled
                  ? AppColors.navSurface
                  : widget.isAvailable
                  ? AppColors.success
                  : AppColors.electricBlue,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: (!widget.enabled
                          ? AppColors.navSurface
                          : widget.isAvailable
                          ? AppColors.success
                          : AppColors.electricBlue)
                      .withValues(alpha: widget.enabled ? 0.45 : 0.16),
                  blurRadius: 38.r,
                  spreadRadius: -10.r,
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: Text(
                  widget.isAvailable
                      ? AppStrings.availabilityOn
                      : AppStrings.availabilityOff,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.buttonText.copyWith(
                    fontSize: 16.sp,
                    letterSpacing: 1.2,
                    color: widget.enabled
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWave(double progress, {required double phase}) {
    final waveProgress = (progress + phase) % 1;
    final scale =
        1 + (waveProgress * (AvailabilityWaveButton.waveScale - 1));
    final opacity = (1 - waveProgress) * 0.28;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.diameter,
        height: widget.diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success.withValues(alpha: opacity * 0.45),
          border: Border.all(
            color: AppColors.success.withValues(alpha: opacity),
            width: math.max(1.2, 2.2 - (waveProgress * 1.2)),
          ),
        ),
      ),
    );
  }
}
