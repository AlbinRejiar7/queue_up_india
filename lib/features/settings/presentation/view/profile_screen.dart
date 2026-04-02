import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
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

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _queueNameController;
  String _appVersion = '';
  bool _isEditProfileSheetOpen = false;

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    final buildNumber = info.buildNumber.trim();
    final version = buildNumber.isEmpty
        ? info.version
        : '${info.version}+$buildNumber';
    if (!mounted) {
      return;
    }
    setState(() {
      _appVersion = version;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _queueNameController = TextEditingController();
    context.read<ProfileBloc>().add(const ProfileRequested());
    _loadAppVersion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _queueNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ProfileBloc>().add(const ProfileRequested());
    }
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

  Future<void> _promptPasswordUpdate() async {
    final result = await showModalBottomSheet<_PasswordSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _PasswordSheet(),
    );

    if (!mounted || result == null) {
      return;
    }

    context.read<ProfileBloc>().add(
      ProfilePasswordRequested(
        currentPassword: result.currentPassword,
        newPassword: result.newPassword,
      ),
    );
  }

  Future<T?> _showProfileSheet<T>(Widget child) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => child,
    );
  }

  Future<void> _openEditProfileSheet() async {
    _isEditProfileSheetOpen = true;
    await _showProfileSheet<void>(
      BlocBuilder<ProfileBloc, ProfileState>(
        builder: (BuildContext context, ProfileState state) {
          final data = state.data;
          final isLoading = state is ProfileLoading;
          final isUsernameChecking = data.isUsernameChecking;
          String? usernameStatusText;
          Color? usernameStatusColor;

          if (isUsernameChecking) {
            usernameStatusText = AppStrings.usernameChecking;
            usernameStatusColor = AppColors.textSecondary;
          } else if (data.usernameStatus ==
              ProfileUsernameCheckStatus.available) {
            usernameStatusText = AppStrings.usernameAvailable;
            usernameStatusColor = AppColors.success;
          } else if (data.usernameStatus == ProfileUsernameCheckStatus.taken) {
            usernameStatusText = AppStrings.usernameTaken;
            usernameStatusColor = AppColors.danger;
          } else if (data.usernameStatus ==
              ProfileUsernameCheckStatus.invalid) {
            usernameStatusText = AppStrings.usernameInvalid;
            usernameStatusColor = AppColors.textSecondary;
          }

          return _EditProfileSheet(
            queueNameController: _queueNameController,
            data: data,
            isLoading: isLoading,
            isUsernameChecking: isUsernameChecking,
            usernameStatusText: usernameStatusText,
            usernameStatusColor: usernameStatusColor,
            onQueueNameChanged: (String value) {
              context.read<ProfileBloc>().add(
                ProfileQueueNameChanged(queueName: value),
              );
            },
            onLanguageChanged: (String value) {
              context.read<ProfileBloc>().add(
                ProfilePreferredLanguageChanged(languageCode: value),
              );
            },
            onAvatarSelected: (String avatarUrl) {
              context.read<ProfileBloc>().add(
                ProfileAvatarChanged(avatarUrl: avatarUrl),
              );
            },
            onSavePressed: () => _handleProfileSave(data, isLoading),
          );
        },
      ),
    );
    _isEditProfileSheetOpen = false;
  }

  Future<void> _openAboutAppSheet() async {
    await _showProfileSheet<void>(
      _AboutAppSheet(
        appVersion: _appVersion,
        onPrivacyPressed: () => _openExternalLink(AppStrings.privacyPolicyUrl),
        onTermsPressed: () => _openExternalLink(AppStrings.termsUrl),
      ),
    );
  }

  Future<void> _openEmailUpdateSheet(ProfileViewData data) async {
    final result = await _showProfileSheet<_EmailUpdateResult>(
      _EmailUpdateSheet(
        currentEmail: data.authEmail,
        pendingEmail: data.pendingAuthEmail,
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    context.read<ProfileBloc>().add(
      ProfileAuthEmailUpdateRequested(
        newEmail: result.newEmail,
        currentPassword: result.currentPassword,
      ),
    );
  }

  void _handleProfileSave(ProfileViewData data, bool isLoading) {
    if (isLoading) {
      return;
    }
    if (!data.isRecoveryEmailValid) {
      AppSnackBar.showError(context, AppStrings.invalidRecoveryEmail);
      return;
    }
    if (!data.canSave) {
      AppSnackBar.showInfo(context, AppStrings.noChangesToSave);
      return;
    }
    context.read<ProfileBloc>().add(const ProfileSavePressed());
  }

  Future<void> _confirmLogout() async {
    final profileBloc = context.read<ProfileBloc>();
    final shouldLogout = await AppDialog.showConfirm(
      context,
      title: AppStrings.confirmLogoutTitle,
      message: AppStrings.confirmLogoutMessage,
      confirmLabel: AppStrings.logout,
      cancelLabel: AppStrings.cancelAction,
      confirmIsDestructive: true,
    );
    if (!shouldLogout || !mounted) {
      return;
    }
    profileBloc.add(const ProfileLogoutRequested());
  }

  Future<void> _confirmDeleteAccount() async {
    final profileBloc = context.read<ProfileBloc>();
    final shouldDelete = await AppDialog.showConfirm(
      context,
      title: AppStrings.confirmDeleteAccountTitle,
      message: AppStrings.confirmDeleteAccountMessage,
      confirmLabel: AppStrings.deleteAccountConfirmAction,
      cancelLabel: AppStrings.cancelAction,
      confirmIsDestructive: true,
    );
    if (!shouldDelete || !mounted) {
      return;
    }
    profileBloc.add(const ProfileDeleteRequested());
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
                        if (_isEditProfileSheetOpen) {
                          Navigator.of(context).pop();
                          _isEditProfileSheetOpen = false;
                        }
                        AppSnackBar.showSuccess(
                          context,
                          AppStrings.profileSaved,
                        );
                        context.read<ProfileBloc>().add(
                          const ProfileSaveNoticeConsumed(),
                        );
                      }

                      if (state is ProfileSuccess &&
                          state.data.showPasswordNotice) {
                        AppSnackBar.showSuccess(
                          context,
                          AppStrings.passwordUpdated,
                        );
                        context.read<ProfileBloc>().add(
                          const ProfilePasswordNoticeConsumed(),
                        );
                      }

                      if (state is ProfileSuccess &&
                          state.data.showEmailUpdateNotice) {
                        AppSnackBar.showSuccess(
                          context,
                          AppStrings.linkedEmailVerificationSent,
                        );
                        context.read<ProfileBloc>().add(
                          const ProfileEmailUpdateNoticeConsumed(),
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
                        context.read<ProfileBloc>().add(
                          const ProfileDeleteConsumed(),
                        );
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) {
                            return;
                          }
                          context.go(AppRoutes.splash);
                        });
                      }
                    },
                    builder: (BuildContext context, ProfileState state) {
                      final data = state.data;
                      final isLoading = state is ProfileLoading;
                      final isSubmittingBugReport = data.isSubmittingBugReport;
                      final isSubmittingPassword = data.isSubmittingPassword;
                      final isSubmittingEmailUpdate =
                          data.isSubmittingEmailUpdate;
                      final displayName = data.queueName.trim().isEmpty
                          ? AppStrings.profile
                          : data.queueName.trim();
                      final aboutSubtitle = _appVersion.isEmpty
                          ? AppStrings.aboutAppSubtitle
                          : '${AppStrings.appVersionTitle}: $_appVersion';
                      final emailTitle = data.hasLinkedEmail
                          ? AppStrings.changeEmail
                          : AppStrings.addEmail;
                      final emailSubtitle = data.hasPendingAuthEmail
                          ? '${AppStrings.linkedEmailStatusPending}: ${data.pendingAuthEmail}'
                          : data.hasLinkedEmail &&
                                data.authEmail.trim().isNotEmpty
                          ? data.authEmail.trim()
                          : AppStrings.linkedEmailSubtitle;

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
                                        displayName,
                                        style: AppTextStyles.sectionTitle
                                            .copyWith(fontSize: 28.sp),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        AppStrings.profileMenuHint,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                GlassContainer(
                                  borderRadius: 24.r,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 8.h,
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      _ProfileMenuTile(
                                        icon: Icons.edit_outlined,
                                        title: AppStrings.editProfile,
                                        subtitle:
                                            AppStrings.editProfileSubtitle,
                                        onTap: _openEditProfileSheet,
                                      ),
                                      const _ProfileMenuDivider(),
                                      _ProfileMenuTile(
                                        icon: Icons.alternate_email_rounded,
                                        title: emailTitle,
                                        subtitle: emailSubtitle,
                                        trailing: isSubmittingEmailUpdate
                                            ? SizedBox(
                                                width: 18.w,
                                                height: 18.w,
                                                child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : null,
                                        enabled:
                                            !isLoading &&
                                            !isSubmittingEmailUpdate,
                                        onTap: () =>
                                            _openEmailUpdateSheet(data),
                                      ),
                                      const _ProfileMenuDivider(),
                                      _ProfileMenuTile(
                                        icon: Icons.lock_outline_rounded,
                                        title: AppStrings.managePassword,
                                        subtitle:
                                            AppStrings.changePasswordSubtitle,
                                        trailing: isSubmittingPassword
                                            ? SizedBox(
                                                width: 18.w,
                                                height: 18.w,
                                                child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : null,
                                        enabled:
                                            !isLoading && !isSubmittingPassword,
                                        onTap: _promptPasswordUpdate,
                                      ),
                                      const _ProfileMenuDivider(),
                                      _ProfileMenuTile(
                                        icon: Icons.support_agent_outlined,
                                        title: AppStrings.supportSection,
                                        subtitle: AppStrings.supportSubtitle,
                                        trailing: isSubmittingBugReport
                                            ? SizedBox(
                                                width: 18.w,
                                                height: 18.w,
                                                child:
                                                    const CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : null,
                                        enabled:
                                            !isLoading &&
                                            !isSubmittingBugReport,
                                        onTap: _promptBugReport,
                                      ),
                                      const _ProfileMenuDivider(),
                                      _ProfileMenuTile(
                                        icon: Icons.info_outline_rounded,
                                        title: AppStrings.aboutQueueUp,
                                        subtitle: aboutSubtitle,
                                        onTap: _openAboutAppSheet,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    AppStrings.accountActions,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                GlassContainer(
                                  borderRadius: 24.r,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 8.h,
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      _ProfileMenuTile(
                                        icon: Icons.logout_rounded,
                                        title: AppStrings.logout,
                                        subtitle: AppStrings.logoutSubtitle,
                                        isDanger: true,
                                        enabled: !isLoading,
                                        onTap: _confirmLogout,
                                      ),
                                      const _ProfileMenuDivider(),
                                      _ProfileMenuTile(
                                        icon: Icons.delete_outline_rounded,
                                        title: AppStrings.deleteAccount,
                                        subtitle:
                                            AppStrings.deleteAccountSubtitle,
                                        isDanger: true,
                                        enabled: !isLoading,
                                        onTap: _confirmDeleteAccount,
                                      ),
                                    ],
                                  ),
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

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.enabled = true,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function()? onTap;
  final Widget? trailing;
  final bool enabled;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDanger ? AppColors.danger : AppColors.textPrimary;
    final subtitleColor = enabled
        ? AppColors.textSecondary
        : AppColors.textSecondary.withValues(alpha: 0.65);
    final iconColor = enabled ? titleColor : titleColor.withValues(alpha: 0.65);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        enabled: enabled,
        contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        leading: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: (isDanger ? AppColors.danger : AppColors.electricBlue)
                .withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14.r),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 20.sp),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(color: subtitleColor),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: subtitleColor,
              size: 22.sp,
            ),
        onTap: enabled && onTap != null ? () => onTap!.call() : null,
      ),
    );
  }
}

class _ProfileMenuDivider extends StatelessWidget {
  const _ProfileMenuDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.08),
      ),
    );
  }
}

class _EditProfileSheet extends StatelessWidget {
  const _EditProfileSheet({
    required this.queueNameController,
    required this.data,
    required this.isLoading,
    required this.isUsernameChecking,
    required this.usernameStatusText,
    required this.usernameStatusColor,
    required this.onQueueNameChanged,
    required this.onLanguageChanged,
    required this.onAvatarSelected,
    required this.onSavePressed,
  });

  final TextEditingController queueNameController;
  final ProfileViewData data;
  final bool isLoading;
  final bool isUsernameChecking;
  final String? usernameStatusText;
  final Color? usernameStatusColor;
  final ValueChanged<String> onQueueNameChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onAvatarSelected;
  final VoidCallback onSavePressed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, bottomInset + 16.h),
        child: GlassContainer(
          borderRadius: 26.r,
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                AppStrings.editProfile,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppStrings.editProfileSubtitle,
                style: AppTextStyles.caption,
              ),
              SizedBox(height: 14.h),
              Center(
                child: CircleAvatar(
                  radius: 34.r,
                  backgroundColor: AppColors.electricBlue.withValues(
                    alpha: 0.2,
                  ),
                  backgroundImage: _avatarProvider(data.avatarUrl),
                  child: data.avatarUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 32.sp,
                          color: AppColors.electricBlue,
                        )
                      : null,
                ),
              ),
              SizedBox(height: 14.h),
              Text(AppStrings.queueName, style: AppTextStyles.bodyMedium),
              SizedBox(height: 8.h),
              TextField(
                controller: queueNameController,
                textInputAction: TextInputAction.next,
                onChanged: onQueueNameChanged,
                decoration: const InputDecoration(
                  hintText: AppStrings.queueNameHint,
                ),
              ),
              if (usernameStatusText != null) ...<Widget>[
                SizedBox(height: 6.h),
                Row(
                  children: <Widget>[
                    if (isUsernameChecking)
                      SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (isUsernameChecking) SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        usernameStatusText!,
                        style: AppTextStyles.caption.copyWith(
                          color: usernameStatusColor ?? AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 16.h),
              Text(
                AppStrings.preferredQueueLanguage,
                style: AppTextStyles.bodyMedium,
              ),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                key: ValueKey<String>(data.preferredLanguageCode),
                initialValue: data.preferredLanguageCode.isEmpty
                    ? null
                    : data.preferredLanguageCode,
                items: data.languages
                    .map(
                      (language) => DropdownMenuItem<String>(
                        value: language.code,
                        child: Text(language.englishLabel),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    onLanguageChanged(value);
                  }
                },
                decoration: const InputDecoration(),
                borderRadius: BorderRadius.circular(18.r),
              ),
              SizedBox(height: 16.h),
              AvatarSelectionGrid(
                selectedAvatarUrl: data.avatarUrl,
                title: AppStrings.changeAvatar,
                onAvatarSelected: onAvatarSelected,
              ),
              SizedBox(height: 14.h),
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
                      onPressed: isLoading ? null : onSavePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlueBright,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(AppStrings.saveChanges),
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

class _EmailUpdateResult {
  const _EmailUpdateResult({
    required this.newEmail,
    required this.currentPassword,
  });

  final String newEmail;
  final String currentPassword;
}

class _EmailUpdateSheet extends StatefulWidget {
  const _EmailUpdateSheet({
    required this.currentEmail,
    required this.pendingEmail,
  });

  final String currentEmail;
  final String pendingEmail;

  @override
  State<_EmailUpdateSheet> createState() => _EmailUpdateSheetState();
}

class _EmailUpdateSheetState extends State<_EmailUpdateSheet> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.pendingEmail.isNotEmpty
          ? widget.pendingEmail
          : widget.currentEmail,
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final newEmail = _emailController.text.trim();
    final currentPassword = _passwordController.text.trim();
    if (newEmail.isEmpty) {
      AppSnackBar.showError(context, AppStrings.linkedEmailInvalid);
      return;
    }
    if (currentPassword.isEmpty) {
      AppSnackBar.showError(context, AppStrings.currentPasswordRequired);
      return;
    }

    Navigator.of(context).pop(
      _EmailUpdateResult(newEmail: newEmail, currentPassword: currentPassword),
    );
  }

  bool get _isResendFlow {
    final pendingEmail = widget.pendingEmail.trim().toLowerCase();
    final enteredEmail = _emailController.text.trim().toLowerCase();
    return pendingEmail.isNotEmpty && enteredEmail == pendingEmail;
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
                AppStrings.linkedEmailTitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(AppStrings.linkedEmailHint, style: AppTextStyles.caption),
              if (widget.currentEmail.trim().isNotEmpty) ...<Widget>[
                SizedBox(height: 14.h),
                _ProfileInfoRow(
                  label: AppStrings.linkedEmailCurrentLabel,
                  value: widget.currentEmail,
                ),
              ],
              if (widget.pendingEmail.trim().isNotEmpty) ...<Widget>[
                SizedBox(height: 10.h),
                Text(
                  '${AppStrings.linkedEmailPendingTitle}: ${widget.pendingEmail}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppStrings.linkedEmailResendHint,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              SizedBox(height: 14.h),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: AppStrings.linkedEmailNewHint,
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: AppStrings.linkedEmailPasswordHint,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(height: 14.h),
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
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlueBright,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: Text(
                        _isResendFlow
                            ? AppStrings.linkedEmailResendAction
                            : widget.currentEmail.trim().isEmpty
                            ? AppStrings.addEmail
                            : AppStrings.changeEmail,
                      ),
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

class _AboutAppSheet extends StatelessWidget {
  const _AboutAppSheet({
    required this.appVersion,
    required this.onPrivacyPressed,
    required this.onTermsPressed,
  });

  final String appVersion;
  final VoidCallback onPrivacyPressed;
  final VoidCallback onTermsPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        child: GlassContainer(
          borderRadius: 24.r,
          padding: EdgeInsets.all(16.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                AppStrings.aboutQueueUp,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(AppStrings.aboutAppSubtitle, style: AppTextStyles.caption),
              SizedBox(height: 16.h),
              _ProfileInfoRow(
                label: AppStrings.appVersionTitle,
                value: appVersion.isEmpty
                    ? AppStrings.loadingLabel
                    : appVersion,
              ),
              SizedBox(height: 14.h),
              Text(
                AppStrings.legalLinksTitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: <Widget>[
                  TextButton(
                    onPressed: onPrivacyPressed,
                    child: Text(AppStrings.privacyPolicy),
                  ),
                  TextButton(
                    onPressed: onTermsPressed,
                    child: Text(AppStrings.termsOfService),
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

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        SizedBox(width: 12.w),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordSheetResult {
  const _PasswordSheetResult({required this.newPassword, this.currentPassword});

  final String newPassword;
  final String? currentPassword;
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (newPassword.length < 6) {
      AppSnackBar.showError(context, AppStrings.passwordTooShort);
      return;
    }
    if (newPassword != confirmPassword) {
      AppSnackBar.showError(context, AppStrings.passwordMismatch);
      return;
    }

    Navigator.of(context).pop(
      _PasswordSheetResult(
        currentPassword: _currentPasswordController.text.trim().isEmpty
            ? null
            : _currentPasswordController.text.trim(),
        newPassword: newPassword,
      ),
    );
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
                AppStrings.managePasswordTitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(AppStrings.managePasswordHint, style: AppTextStyles.caption),
              SizedBox(height: 12.h),
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  hintText: AppStrings.currentPasswordHint,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureCurrent = !_obscureCurrent;
                      });
                    },
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  hintText: AppStrings.newPasswordHint,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: AppStrings.confirmNewPasswordHint,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
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
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlueBright,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: Text(AppStrings.managePassword),
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
