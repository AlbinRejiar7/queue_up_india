import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/glass_container.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../bloc/registration_bloc.dart';
import '../../../bloc/registration_event.dart';
import '../../../bloc/registration_state.dart';

class PasswordCredentialsCard extends StatefulWidget {
  const PasswordCredentialsCard({
    super.key,
    this.wrapInContainer = true,
    this.onForgotPasswordPressed,
  });

  final bool wrapInContainer;
  final VoidCallback? onForgotPasswordPressed;

  @override
  State<PasswordCredentialsCard> createState() =>
      _PasswordCredentialsCardState();
}

class _PasswordCredentialsCardState extends State<PasswordCredentialsCard> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationBloc, RegistrationState>(
      builder: (BuildContext context, RegistrationState state) {
        final data = state.data;
        final isRegistration = data.isRegistration;
        final isSubmitting = data.isSubmitting;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppStrings.password,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              initialValue: data.password,
              obscureText: _obscurePassword,
              textInputAction: isRegistration
                  ? TextInputAction.next
                  : TextInputAction.done,
              decoration: InputDecoration(
                hintText: AppStrings.passwordHint,
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
              onChanged: (String value) {
                context.read<RegistrationBloc>().add(
                  RegistrationPasswordChanged(password: value),
                );
              },
            ),
            if (isRegistration) ...<Widget>[
              SizedBox(height: 14.h),
              Text(
                AppStrings.confirmPassword,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                initialValue: data.confirmPassword,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: AppStrings.confirmPasswordHint,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                onChanged: (String value) {
                  context.read<RegistrationBloc>().add(
                    RegistrationConfirmPasswordChanged(confirmPassword: value),
                  );
                },
              ),
              SizedBox(height: 14.h),
              Text(
                AppStrings.recoveryEmailOptional,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                initialValue: data.recoveryEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: AppStrings.recoveryEmailHint,
                ),
                onChanged: (String value) {
                  context.read<RegistrationBloc>().add(
                    RegistrationRecoveryEmailChanged(recoveryEmail: value),
                  );
                },
              ),
              SizedBox(height: 6.h),
              Text(
                AppStrings.recoveryEmailHelp,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            SizedBox(height: 18.h),
            PrimaryButton(
              label: isRegistration
                  ? AppStrings.createAccountAction
                  : AppStrings.signInAction,
              isLoading: isSubmitting,
              enabled: data.canSubmit && !isSubmitting,
              onDisabledPressed: () {
                AppSnackBar.showError(context, _validationMessage(data));
              },
              onPressed: () {
                context.read<RegistrationBloc>().add(
                  const RegistrationSubmitPressed(),
                );
              },
            ),
            if (!isRegistration) ...<Widget>[
              SizedBox(height: 8.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: isSubmitting
                      ? null
                      : widget.onForgotPasswordPressed,
                  child: const Text(AppStrings.forgotPassword),
                ),
              ),
            ],
          ],
        );

        if (!widget.wrapInContainer) {
          return content;
        }

        return GlassContainer(
          borderRadius: 28.r,
          padding: EdgeInsets.all(16.r),
          child: content,
        );
      },
    );
  }

  String _validationMessage(RegistrationViewData data) {
    if (!data.hasUsername) {
      return AppStrings.usernameRequired;
    }
    if (data.normalizedUsername.length < 3) {
      return AppStrings.usernameInvalid;
    }
    if (!data.hasValidPassword) {
      return AppStrings.passwordTooShort;
    }
    if (data.isRegistration) {
      if (data.usernameStatus == UsernameCheckStatus.taken) {
        return AppStrings.usernameTaken;
      }
      if (data.isUsernameChecking || !data.isUsernameAvailable) {
        return AppStrings.usernameCheckFailed;
      }
      if (!data.doPasswordsMatch) {
        return AppStrings.passwordMismatch;
      }
      if (!data.hasSelectedAvatar) {
        return AppStrings.avatarRequired;
      }
      if (!data.isRecoveryEmailValid) {
        return AppStrings.invalidRecoveryEmail;
      }
      if (!data.acceptedLegal) {
        return AppStrings.acceptLegalRequired;
      }
    }
    return data.isRegistration
        ? AppStrings.createAccountFailed
        : AppStrings.loginFailed;
  }
}
