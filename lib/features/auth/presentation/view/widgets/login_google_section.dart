import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../bloc/registration_bloc.dart';
import '../../../bloc/registration_event.dart';
import '../../../bloc/registration_state.dart';

class LoginGoogleSection extends StatelessWidget {
  const LoginGoogleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationBloc, RegistrationState>(
      builder: (BuildContext context, RegistrationState state) {
        final bool isLoading = state is RegistrationLoading;

        return Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text(
                    AppStrings.orDivider,
                    style: AppTextStyles.caption.copyWith(letterSpacing: 2),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        context.read<RegistrationBloc>().add(
                          const RegistrationGooglePressed(),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navSurface.withValues(alpha: 0.9),
                ),
                icon: Icon(Icons.g_mobiledata_rounded, size: 28.sp),
                label: Text(
                  AppStrings.continueWithGoogle,
                  style: AppTextStyles.buttonText,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
