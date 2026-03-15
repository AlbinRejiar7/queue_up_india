import 'package:flutter/gestures.dart';
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
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart';
import '../../bloc/registration_state.dart';
import 'widgets/avatar_selection_section.dart';
import 'widgets/phone_otp_card.dart';
import 'widgets/registration_header.dart';
import 'widgets/registration_username_field.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: BlocListener<RegistrationBloc, RegistrationState>(
          listener: (BuildContext context, RegistrationState state) {
            if (state is RegistrationError) {
              AppSnackBar.showError(context, state.message);
            }

            if (state is RegistrationSuccess &&
                state.data.didCompleteRegistration) {
              context.go(AppRoutes.home);
              context.read<RegistrationBloc>().add(
                const RegistrationResetRequested(),
              );
            }
          },
          child: SafeArea(
            child: ResponsiveLayoutBuilder(
              builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsets contentPadding,
                ) {
                  final mode =
                      context.read<RegistrationBloc>().state.data.mode;
                  if (mode != RegistrationMode.register) {
                    context.read<RegistrationBloc>().add(
                          const RegistrationModeChanged(
                            mode: RegistrationMode.register,
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
                                const SafeBackButton(
                                  fallbackRoute: AppRoutes.login,
                                ),
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
                            const RegistrationHeader(),
                            SizedBox(height: 18.h),
                            const RegistrationUsernameField(),
                            SizedBox(height: 20.h),
                            const AvatarSelectionSection(),
                            SizedBox(height: 18.h),
                            const PhoneOtpCard(),
                            SizedBox(height: 16.h),
                            BlocBuilder<RegistrationBloc, RegistrationState>(
                              builder: (context, state) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Checkbox(
                                      value: state.data.acceptedLegal,
                                      onChanged: (value) {
                                        context.read<RegistrationBloc>().add(
                                          RegistrationLegalAcceptedChanged(
                                            accepted: value ?? false,
                                          ),
                                        );
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
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                  color: AppColors.electricBlue,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () {
                                                    launchUrl(
                                                      Uri.parse(
                                                        AppStrings
                                                            .privacyPolicyUrl,
                                                      ),
                                                      mode: LaunchMode
                                                          .externalApplication,
                                                    );
                                                  },
                                              ),
                                              TextSpan(
                                                text: ' ${AppStrings.acceptLegalAnd} ',
                                                style: AppTextStyles.caption,
                                              ),
                                              TextSpan(
                                                text: AppStrings.termsOfService,
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                  color: AppColors.electricBlue,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () {
                                                    launchUrl(
                                                      Uri.parse(
                                                        AppStrings.termsUrl,
                                                      ),
                                                      mode: LaunchMode
                                                          .externalApplication,
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
                                );
                              },
                            ),
                            SizedBox(height: 20.h),
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
    );
  }
}
