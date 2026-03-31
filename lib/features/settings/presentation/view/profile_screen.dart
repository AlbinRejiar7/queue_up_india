import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../../auth/bloc/registration_bloc.dart';
import '../../../auth/bloc/registration_event.dart';
import '../../bloc/profile_bloc.dart';
import '../../bloc/profile_event.dart';
import '../../bloc/profile_state.dart';
import '../../../../core/widgets/avatar_selection_grid.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _queueNameController;

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();
    _queueNameController = TextEditingController();
    context.read<ProfileBloc>().add(const ProfileRequested());
  }

  @override
  void dispose() {
    _queueNameController.dispose();
    super.dispose();
  }

  Future<void> _promptBugReport() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _BugReportSheet(),
    );

    if (!mounted || result == null) {
      return;
    }

    context.read<ProfileBloc>().add(ProfileBugReportRequested(details: result));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: ResponsiveLayoutBuilder(
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsets contentPadding,
                ) {
                  return BlocConsumer<ProfileBloc, ProfileState>(
                    listener: (BuildContext context, ProfileState state) {
                      if (_queueNameController.text != state.data.queueName) {
                        _queueNameController.text = state.data.queueName;
                        _queueNameController.selection =
                            TextSelection.fromPosition(
                              TextPosition(
                                offset: _queueNameController.text.length,
                              ),
                            );
                      }

                      if (state is ProfileError) {
                        AppSnackBar.showError(context, state.message);
                      }

                      if (state is ProfileSuccess &&
                          state.data.showSavedNotice) {
                        AppSnackBar.showSuccess(
                          context,
                          AppStrings.profileSaved,
                        );
                        context.read<ProfileBloc>().add(
                          const ProfileSaveNoticeConsumed(),
                        );
                      }

                      if (state is ProfileSuccess &&
                          state.data.showBugReportNotice) {
                        AppSnackBar.showSuccess(
                          context,
                          AppStrings.bugReportSubmitted,
                        );
                        context.read<ProfileBloc>().add(
                          const ProfileBugReportNoticeConsumed(),
                        );
                      }

                      if (state is ProfileSuccess && state.data.didLogout) {
                        context.read<RegistrationBloc>().add(
                          const RegistrationResetRequested(),
                        );
                        context.go(AppRoutes.login);
                        context.read<ProfileBloc>().add(
                          const ProfileLogoutConsumed(),
                        );
                      }

                      if (state is ProfileSuccess &&
                          state.data.didDeleteAccount) {
                        AppSnackBar.showSuccess(
                          context,
                          AppStrings.deleteAccountSuccess,
                        );
                        context.read<RegistrationBloc>().add(
                          const RegistrationResetRequested(),
                        );
                        context.go(AppRoutes.login);
                        context.read<ProfileBloc>().add(
                          const ProfileDeleteConsumed(),
                        );
                      }
                    },
                    builder: (BuildContext context, ProfileState state) {
                      final data = state.data;
                      final isLoading = state is ProfileLoading;
                      final isSubmittingBugReport = data.isSubmittingBugReport;

                      return Column(
                        children: <Widget>[
                          Padding(
                            padding: contentPadding,
                            child: Column(
                              children: <Widget>[
                                SizedBox(height: 6.h),
                                Row(
                                  children: <Widget>[
                                    if (widget.showBackButton)
                                      const SafeBackButton(
                                        fallbackRoute: AppRoutes.home,
                                      )
                                    else
                                      SizedBox(width: 48.w),
                                    Expanded(
                                      child: Text(
                                        AppStrings.profile,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.pageTitle,
                                      ),
                                    ),
                                    SizedBox(width: 48.w),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                contentPadding.left,
                                14.h,
                                contentPadding.right,
                                24.h,
                              ),
                              children: <Widget>[
                                Center(
                                  child: Column(
                                    children: <Widget>[
                                      CircleAvatar(
                                        radius: 44.r,
                                        backgroundColor: AppColors.electricBlue
                                            .withValues(alpha: 0.2),
                                        backgroundImage: _avatarProvider(
                                          data.avatarUrl,
                                        ),
                                        child: data.avatarUrl.isEmpty
                                            ? Icon(
                                                Icons.person,
                                                size: 42.sp,
                                                color: AppColors.electricBlue,
                                              )
                                            : null,
                                      ),
                                      SizedBox(height: 10.h),
                                      Text(
                                        AppStrings.profileDetails,
                                        style: AppTextStyles.sectionTitle
                                            .copyWith(fontSize: 28.sp),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        AppStrings.queuePreferenceHint,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                GlassContainer(
                                  borderRadius: 28.r,
                                  padding: EdgeInsets.all(16.r),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        AppStrings.queueName,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                      SizedBox(height: 8.h),
                                      TextField(
                                        controller: _queueNameController,
                                        onChanged: (String value) {
                                          context.read<ProfileBloc>().add(
                                            ProfileQueueNameChanged(
                                              queueName: value,
                                            ),
                                          );
                                        },
                                        decoration: const InputDecoration(
                                          hintText: AppStrings.queueNameHint,
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        AppStrings.preferredQueueLanguage,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                      SizedBox(height: 8.h),
                                      DropdownButtonFormField<String>(
                                        key: ValueKey<String>(
                                          data.preferredLanguageCode,
                                        ),
                                        initialValue:
                                            data.preferredLanguageCode.isEmpty
                                            ? null
                                            : data.preferredLanguageCode,
                                        items: data.languages
                                            .map(
                                              (language) =>
                                                  DropdownMenuItem<String>(
                                                    value: language.code,
                                                    child: Text(
                                                      language.englishLabel,
                                                    ),
                                                  ),
                                            )
                                            .toList(),
                                        onChanged: (String? value) {
                                          if (value != null) {
                                            context.read<ProfileBloc>().add(
                                              ProfilePreferredLanguageChanged(
                                                languageCode: value,
                                              ),
                                            );
                                          }
                                        },
                                        decoration: const InputDecoration(),
                                        borderRadius: BorderRadius.circular(
                                          18.r,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                AvatarSelectionGrid(
                                  selectedAvatarUrl: data.avatarUrl,
                                  title: AppStrings.changeAvatar,
                                  onAvatarSelected: (String avatarUrl) {
                                    context.read<ProfileBloc>().add(
                                      ProfileAvatarChanged(
                                        avatarUrl: avatarUrl,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 20.h),
                                PrimaryButton(
                                  label: AppStrings.saveChanges,
                                  isLoading: isLoading,
                                  enabled: data.canSave,
                                  onDisabledPressed: () {
                                    AppSnackBar.showInfo(
                                      context,
                                      AppStrings.noChangesToSave,
                                    );
                                  },
                                  onPressed: () {
                                    context.read<ProfileBloc>().add(
                                      const ProfileSavePressed(),
                                    );
                                  },
                                ),
                                SizedBox(height: 12.h),
                                GlassContainer(
                                  borderRadius: 22.r,
                                  padding: EdgeInsets.all(14.r),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        AppStrings.privacy,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                      SizedBox(height: 6.h),
                                      Wrap(
                                        spacing: 8.w,
                                        children: <Widget>[
                                          TextButton(
                                            onPressed: () => _openExternalLink(
                                              AppStrings.privacyPolicyUrl,
                                            ),
                                            child: Text(
                                              AppStrings.privacyPolicy,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => _openExternalLink(
                                              AppStrings.termsUrl,
                                            ),
                                            child: Text(
                                              AppStrings.termsOfService,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                PrimaryButton(
                                  label: AppStrings.reportBug,
                                  icon: Icons.bug_report_outlined,
                                  isLoading: isSubmittingBugReport,
                                  enabled: !isLoading && !isSubmittingBugReport,
                                  onPressed: _promptBugReport,
                                ),
                                SizedBox(height: 12.h),
                                PrimaryButton(
                                  label: AppStrings.logout,
                                  isDanger: true,
                                  enabled: !isLoading,
                                  onPressed: () async {
                                    final profileBloc = context
                                        .read<ProfileBloc>();
                                    final shouldLogout =
                                        await AppDialog.showConfirm(
                                          context,
                                          title: AppStrings.confirmLogoutTitle,
                                          message:
                                              AppStrings.confirmLogoutMessage,
                                          confirmLabel: AppStrings.logout,
                                          cancelLabel: AppStrings.cancelAction,
                                          confirmIsDestructive: true,
                                        );
                                    if (!shouldLogout) {
                                      return;
                                    }
                                    if (!mounted) {
                                      return;
                                    }
                                    profileBloc.add(
                                      const ProfileLogoutRequested(),
                                    );
                                  },
                                ),
                                SizedBox(height: 12.h),
                                PrimaryButton(
                                  label: AppStrings.deleteAccount,
                                  isDanger: true,
                                  enabled: !isLoading,
                                  onPressed: () async {
                                    final profileBloc = context
                                        .read<ProfileBloc>();
                                    final shouldDelete =
                                        await AppDialog.showConfirm(
                                          context,
                                          title: AppStrings
                                              .confirmDeleteAccountTitle,
                                          message: AppStrings
                                              .confirmDeleteAccountMessage,
                                          confirmLabel: AppStrings
                                              .deleteAccountConfirmAction,
                                          cancelLabel: AppStrings.cancelAction,
                                          confirmIsDestructive: true,
                                        );
                                    if (!shouldDelete) {
                                      return;
                                    }
                                    if (!mounted) {
                                      return;
                                    }
                                    profileBloc.add(
                                      const ProfileDeleteRequested(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
          ),
        ),
      ),
    );
  }
}

class _BugReportSheet extends StatefulWidget {
  const _BugReportSheet();

  @override
  State<_BugReportSheet> createState() => _BugReportSheetState();
}

class _BugReportSheetState extends State<_BugReportSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, bottomInset + 16.h),
        child: GlassContainer(
          borderRadius: 24.r,
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                AppStrings.reportBugTitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(AppStrings.reportBugHint, style: AppTextStyles.caption),
              SizedBox(height: 10.h),
              TextField(
                controller: _controller,
                maxLines: 5,
                minLines: 4,
                maxLength: 1000,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: AppStrings.reportBugFieldHint,
                  hintStyle: AppTextStyles.caption,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.cancelAction),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(_controller.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlueBright,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: Text(AppStrings.reportBugSubmit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ImageProvider? _avatarProvider(String avatarUrl) {
  if (avatarUrl.trim().isEmpty) {
    return null;
  }
  if (avatarUrl.startsWith('http')) {
    return NetworkImage(avatarUrl);
  }
  return AssetImage(avatarUrl);
}
