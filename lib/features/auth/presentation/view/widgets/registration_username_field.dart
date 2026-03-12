import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../bloc/registration_bloc.dart';
import '../../../bloc/registration_event.dart';
import '../../../bloc/registration_state.dart';

class RegistrationUsernameField extends StatelessWidget {
  const RegistrationUsernameField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationBloc, RegistrationState>(
      builder: (BuildContext context, RegistrationState state) {
        final isRegistration = state.data.isRegistration;
        final status = state.data.usernameStatus;
        final isChecking = state.data.isUsernameChecking;
        String? statusText;
        Color? statusColor;

        if (isRegistration) {
          if (isChecking) {
            statusText = AppStrings.usernameChecking;
            statusColor = AppColors.textSecondary;
          } else if (status == UsernameCheckStatus.available) {
            statusText = AppStrings.usernameAvailable;
            statusColor = AppColors.success;
          } else if (status == UsernameCheckStatus.taken) {
            statusText = AppStrings.usernameTaken;
            statusColor = AppColors.danger;
          } else if (status == UsernameCheckStatus.invalid) {
            statusText = AppStrings.usernameInvalid;
            statusColor = AppColors.textSecondary;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(AppStrings.username, style: AppTextStyles.bodyMedium),
            SizedBox(height: 8.h),
            TextFormField(
              initialValue: state.data.username,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: AppStrings.usernameHint,
              ),
              onChanged: (String value) {
                context.read<RegistrationBloc>().add(
                  RegistrationUsernameChanged(username: value),
                );
              },
            ),
            if (statusText != null) ...<Widget>[
              SizedBox(height: 6.h),
              Row(
                children: <Widget>[
                  if (isChecking)
                    SizedBox(
                      width: 14.w,
                      height: 14.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (isChecking) SizedBox(width: 6.w),
                  Text(
                    statusText,
                    style: AppTextStyles.caption.copyWith(
                      color: statusColor ?? AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
