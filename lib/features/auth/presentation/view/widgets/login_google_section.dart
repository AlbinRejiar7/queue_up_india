import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/glass_container.dart';
import '../../../bloc/registration_bloc.dart';
import '../../../bloc/registration_event.dart';
import '../../../bloc/registration_state.dart';

class LoginGoogleSection extends StatelessWidget {
  const LoginGoogleSection({super.key});

  Future<bool> _showGoogleConsentDialog(BuildContext context) async {
    bool accepted = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
              child: GlassContainer(
                borderRadius: 28.r,
                padding: EdgeInsets.all(20.r),
                backgroundColor: AppColors.navSurface.withValues(alpha: 0.96),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      AppStrings.googleConsentTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 20.sp,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      AppStrings.googleConsentMessage,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Checkbox(
                          value: accepted,
                          onChanged: (value) {
                            setState(() => accepted = value ?? false);
                          },
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 6.h),
                            child: Text.rich(
                              TextSpan(
                                text: '${AppStrings.acceptLegalPrefix} ',
                                style: AppTextStyles.caption,
                                children: <TextSpan>[
                                  TextSpan(
                                    text: AppStrings.privacyPolicy,
                                    style:
                                        AppTextStyles.caption.copyWith(
                                      color: AppColors.electricBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchUrl(
                                          Uri.parse(
                                            AppStrings.privacyPolicyUrl,
                                          ),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      },
                                  ),
                                  TextSpan(
                                    text: ' ${AppStrings.acceptLegalAnd} ',
                                    style: AppTextStyles.caption,
                                  ),
                                  TextSpan(
                                    text: AppStrings.termsOfService,
                                    style:
                                        AppTextStyles.caption.copyWith(
                                      color: AppColors.electricBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchUrl(
                                          Uri.parse(
                                            AppStrings.termsUrl,
                                          ),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      },
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: Text(AppStrings.cancelAction),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: accepted
                                ? () =>
                                    Navigator.of(dialogContext).pop(true)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.electricBlueBright,
                              foregroundColor: AppColors.textPrimary,
                              elevation: accepted ? 10 : 0,
                              shadowColor: AppColors.electricBlueBright
                                  .withValues(alpha: 0.5),
                            ),
                            child: Text(AppStrings.continueWithGoogle),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return result ?? false;
  }

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
                    : () async {
                        final accepted =
                            await _showGoogleConsentDialog(context);
                        if (!accepted) {
                          return;
                        }
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
