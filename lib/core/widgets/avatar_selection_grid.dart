import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_options.dart';
import '../theme/app_text_styles.dart';
import 'glass_container.dart';

class AvatarSelectionGrid extends StatefulWidget {
  const AvatarSelectionGrid({
    required this.selectedAvatarUrl,
    required this.onAvatarSelected,
    super.key,
    this.title,
    this.subtitle,
  });

  final String? selectedAvatarUrl;
  final ValueChanged<String> onAvatarSelected;
  final String? title;
  final String? subtitle;

  @override
  State<AvatarSelectionGrid> createState() => _AvatarSelectionGridState();
}

class _AvatarSelectionGridState extends State<AvatarSelectionGrid> {
  late final ScrollController _scrollController;
  bool _showRightHint = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRightHint());
  }

  @override
  void didUpdateWidget(covariant AvatarSelectionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRightHint());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    _updateRightHint();
  }

  void _updateRightHint() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final shouldShow =
        position.maxScrollExtent > 4 &&
        position.pixels < position.maxScrollExtent - 4;

    if (_showRightHint == shouldShow) {
      return;
    }

    setState(() {
      _showRightHint = shouldShow;
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRightHint());

    return GlassContainer(
      borderRadius: 28.r,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.title != null) ...<Widget>[
            Text(
              widget.title!,
              style: AppTextStyles.pageTitle.copyWith(fontSize: 18.sp),
            ),
            SizedBox(height: 4.h),
          ],
          if (widget.subtitle != null) ...<Widget>[
            Text(
              widget.subtitle!,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 12.sp),
            ),
            SizedBox(height: 14.h),
          ] else
            SizedBox(height: 10.h),
          SizedBox(
            height: 64.h,
            child: Stack(
              children: <Widget>[
                ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(right: 36.w),
                  itemCount: AppOptions.profileAvatarOptions.length,
                  separatorBuilder: (_, _) => SizedBox(width: 12.w),
                  itemBuilder: (BuildContext context, int index) {
                    final avatar = AppOptions.profileAvatarOptions[index];
                    final isSelected =
                        avatar == (widget.selectedAvatarUrl ?? '');
                    return _AvatarOption(
                      avatarUrl: avatar,
                      isSelected: isSelected,
                      onTap: () => widget.onAvatarSelected(avatar),
                    );
                  },
                ),
                if (_showRightHint)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 56.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: <Color>[
                              AppColors.navSurface.withValues(alpha: 0),
                              AppColors.navSurface.withValues(alpha: 0.94),
                            ],
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 28.w,
                          height: 28.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.electricBlue.withValues(
                              alpha: 0.16,
                            ),
                            border: Border.all(
                              color: AppColors.electricBlue.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_right_rounded,
                            color: AppColors.textPrimary,
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.avatarUrl,
    required this.isSelected,
    required this.onTap,
  });

  final String avatarUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(isSelected ? 3.r : 1.5.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppColors.electricBlue
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: <BoxShadow>[
            if (isSelected)
              BoxShadow(
                color: AppColors.electricBlue.withValues(alpha: 0.35),
                blurRadius: 18.r,
                spreadRadius: -6.r,
              ),
          ],
        ),
        child: CircleAvatar(
          radius: 26.r,
          backgroundImage: avatarUrl.startsWith('http')
              ? NetworkImage(avatarUrl)
              : AssetImage(avatarUrl) as ImageProvider,
          backgroundColor: AppColors.surface,
        ),
      ),
    );
  }
}
