import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../di/injection_container.dart';
import '../models/activity_pulse_model.dart';
import '../services/activity_pulse_service.dart';
import '../theme/app_text_styles.dart';
import 'glass_container.dart';

class ActivityPulsePanel extends StatefulWidget {
  const ActivityPulsePanel({
    required this.gameId,
    super.key,
    this.onSoloPlayersTap,
    this.onOpenPartiesTap,
    this.compact = false,
    this.showHint = true,
  });

  final String gameId;
  final VoidCallback? onSoloPlayersTap;
  final VoidCallback? onOpenPartiesTap;
  final bool compact;
  final bool showHint;

  @override
  State<ActivityPulsePanel> createState() => _ActivityPulsePanelState();
}

class _ActivityPulsePanelState extends State<ActivityPulsePanel> {
  late Future<ActivityPulseModel> _future;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _future = _load();
      });
    });
  }

  @override
  void didUpdateWidget(covariant ActivityPulsePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      setState(() {
        _future = _load();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<ActivityPulseModel> _load() {
    return sl<ActivityPulseService>().fetchForGame(widget.gameId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ActivityPulseModel>(
      future: _future,
      builder: (context, snapshot) {
        final pulse = snapshot.data ??
            const ActivityPulseModel(
              availableSoloPlayers: 0,
              openParties: 0,
            );
        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _PulseStatCard(
                    compact: widget.compact,
                    count: pulse.availableSoloPlayers,
                    label: AppStrings.soloPlayersAvailableLabel,
                    color: AppColors.success,
                    onTap: widget.onSoloPlayersTap,
                  ),
                ),
                SizedBox(width: widget.compact ? 8.w : 10.w),
                Expanded(
                  child: _PulseStatCard(
                    compact: widget.compact,
                    count: pulse.openParties,
                    label: AppStrings.openPartiesLabel,
                    color: AppColors.electricBlue,
                    onTap: widget.onOpenPartiesTap,
                  ),
                ),
              ],
            ),
            if (widget.showHint) ...<Widget>[
              SizedBox(height: widget.compact ? 6.h : 8.h),
              Text(
                AppStrings.peakTimeHint,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PulseStatCard extends StatelessWidget {
  const _PulseStatCard({
    required this.count,
    required this.label,
    required this.color,
    required this.compact,
    this.onTap,
  });

  final int count;
  final String label;
  final Color color;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = GlassContainer(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12.w : 14.w,
        vertical: compact ? 10.h : 14.h,
      ),
      backgroundColor: Colors.white.withValues(alpha: 0.03),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$count',
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: compact ? 18.sp : 20.sp,
                    color: color,
                  ),
                ),
                SizedBox(height: compact ? 2.h : 4.h),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: compact ? 11.sp : null,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.sp,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}
