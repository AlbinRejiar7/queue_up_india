import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart';
import '../../bloc/registration_state.dart';
import 'widgets/login_google_section.dart';
import 'widgets/password_credentials_card.dart';
import 'widgets/registration_header.dart';
import 'widgets/registration_username_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleBackPressed(BuildContext context) async {
    final shouldExit = await AppDialog.showConfirm(
      context,
      title: AppStrings.confirmExitTitle,
      message: AppStrings.confirmExitMessage,
      confirmLabel: AppStrings.confirmAction,
      cancelLabel: AppStrings.cancelAction,
    );
    if (shouldExit) {
      await SystemNavigator.pop();
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    context.read<RegistrationBloc>().add(
      const RegistrationPasswordResetFlowResetRequested(),
    );

    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) {
        return BlocProvider.value(
          value: context.read<RegistrationBloc>(),
          child: const _ForgotPasswordDialog(),
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    context.read<RegistrationBloc>().add(
      const RegistrationPasswordResetFlowResetRequested(),
    );

    if (sent == true) {
      AppSnackBar.showSuccess(context, AppStrings.forgotPasswordEmailSent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        await _handleBackPressed(context);
      },
      child: Scaffold(
        body: GlowBackground(
          child: MultiBlocListener(
            listeners: <BlocListener<RegistrationBloc, RegistrationState>>[
              BlocListener<RegistrationBloc, RegistrationState>(
                listenWhen: (previous, current) =>
                    previous.data.didCompleteRegistration !=
                        current.data.didCompleteRegistration ||
                    (current is RegistrationError &&
                        previous != current &&
                        current.data.passwordResetUsername.trim().isEmpty),
                listener: (BuildContext context, RegistrationState state) {
                  if (state is RegistrationError) {
                    developer.log(
                      'Login error shown: ${state.message}',
                      name: 'LoginScreen',
                    );
                    AppSnackBar.showError(context, state.message);
                  }

                  if (state is RegistrationSuccess &&
                      state.data.didCompleteRegistration) {
                    developer.log(
                      'Login completed -> navigate home',
                      name: 'LoginScreen',
                    );
                    context.go(AppRoutes.home);
                    context.read<RegistrationBloc>().add(
                      const RegistrationResetRequested(),
                    );
                  }
                },
              ),
            ],
            child: SafeArea(
              child: ResponsiveLayoutBuilder(
                builder:
                    (
                      BuildContext context,
                      BoxConstraints constraints,
                      EdgeInsets contentPadding,
                    ) {
                      final mode = context
                          .read<RegistrationBloc>()
                          .state
                          .data
                          .mode;
                      if (mode != RegistrationMode.login) {
                        context.read<RegistrationBloc>().add(
                          const RegistrationModeChanged(
                            mode: RegistrationMode.login,
                          ),
                        );
                      }
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: contentPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                SizedBox(height: 8.h),
                                Row(
                                  children: <Widget>[
                                    SizedBox(width: 48.w),
                                    Expanded(
                                      child: Text(
                                        AppStrings.appName,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.pageTitle,
                                      ),
                                    ),
                                    SizedBox(width: 48.w),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                const RegistrationHeader(
                                  title: AppStrings.loginTitle,
                                  subtitle: AppStrings.loginSubtitle,
                                ),
                                SizedBox(height: 20.h),
                                GlassContainer(
                                  borderRadius: 28.r,
                                  padding: EdgeInsets.all(16.r),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      const RegistrationUsernameField(
                                        hintText: AppStrings.username,
                                      ),
                                      SizedBox(height: 16.h),
                                      PasswordCredentialsCard(
                                        wrapInContainer: false,
                                        onForgotPasswordPressed: () {
                                          _showForgotPasswordDialog(context);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 18.h),
                                const LoginGoogleSection(),
                                SizedBox(height: 10.h),
                                TextButton(
                                  onPressed: () {
                                    context.push(AppRoutes.registration);
                                  },
                                  child: Text.rich(
                                    TextSpan(
                                      text: '${AppStrings.dontHaveAccount} ',
                                      children: <InlineSpan>[
                                        TextSpan(
                                          text: AppStrings.registerAction,
                                          style: TextStyle(
                                            color: AppColors.electricBlue,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                                SizedBox(height: 14.h),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog();

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationBloc, RegistrationState>(
      listenWhen: (RegistrationState previous, RegistrationState current) =>
          previous.data.showPasswordResetNotice !=
          current.data.showPasswordResetNotice,
      listener: (BuildContext context, RegistrationState state) {
        if (state.data.showPasswordResetNotice) {
          context.read<RegistrationBloc>().add(
            const RegistrationPasswordResetNoticeConsumed(),
          );
          Navigator.of(context).pop(true);
        }
      },
      child: BlocBuilder<RegistrationBloc, RegistrationState>(
        builder: (BuildContext context, RegistrationState state) {
          final data = state.data;
          final canSend =
              data.normalizedPasswordResetUsername.length >= 3 &&
              data.canResetPassword &&
              !data.isCheckingPasswordReset &&
              !data.isSubmitting;
          final status = _statusFor(state);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
            child: GlassContainer(
              borderRadius: 28.r,
              padding: EdgeInsets.all(20.r),
              backgroundColor: AppColors.navSurface.withValues(alpha: 0.96),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    AppStrings.forgotPasswordTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 20.sp),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    AppStrings.forgotPasswordDialogHint,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                  SizedBox(height: 18.h),
                  TextFormField(
                    controller: _usernameController,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: AppStrings.username,
                    ),
                    onChanged: (String value) {
                      context.read<RegistrationBloc>().add(
                        RegistrationPasswordResetUsernameChanged(
                          username: value,
                        ),
                      );
                    },
                    onFieldSubmitted: (_) {
                      if (canSend) {
                        context.read<RegistrationBloc>().add(
                          const RegistrationForgotPasswordPressed(),
                        );
                      }
                    },
                  ),
                  if (status != null) ...<Widget>[
                    SizedBox(height: 10.h),
                    Text(
                      status.message,
                      style: AppTextStyles.caption.copyWith(
                        color: status.color,
                      ),
                    ),
                  ],
                  SizedBox(height: 18.h),
                  PrimaryButton(
                    label: AppStrings.forgotPasswordSendAction,
                    isLoading: data.isSubmitting,
                    enabled: canSend,
                    onDisabledPressed: null,
                    onPressed: () {
                      context.read<RegistrationBloc>().add(
                        const RegistrationForgotPasswordPressed(),
                      );
                    },
                  ),
                  SizedBox(height: 10.h),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(AppStrings.cancelAction),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  _ForgotPasswordStatus? _statusFor(RegistrationState state) {
    final data = state.data;
    final hasTyped = data.passwordResetUsername.trim().isNotEmpty;

    if (state is RegistrationError && hasTyped) {
      return _ForgotPasswordStatus(state.message, AppColors.danger);
    }
    if (!hasTyped) {
      return null;
    }
    if (data.normalizedPasswordResetUsername.length < 3) {
      return _ForgotPasswordStatus(
        AppStrings.forgotPasswordEnterUsername,
        AppColors.textSecondary,
      );
    }
    if (data.isCheckingPasswordReset) {
      return _ForgotPasswordStatus(
        AppStrings.forgotPasswordChecking,
        AppColors.electricBlueBright,
      );
    }
    if (data.canResetPassword) {
      return _ForgotPasswordStatus(
        AppStrings.forgotPasswordReady,
        AppColors.success,
      );
    }
    return _ForgotPasswordStatus(
      AppStrings.forgotPasswordDisabled,
      AppColors.textSecondary,
    );
  }
}

class _ForgotPasswordStatus {
  const _ForgotPasswordStatus(this.message, this.color);

  final String message;
  final Color color;
}
