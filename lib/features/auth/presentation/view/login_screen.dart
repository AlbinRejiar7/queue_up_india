import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart';
import '../../bloc/registration_state.dart';
import 'widgets/login_google_section.dart';
import 'widgets/phone_otp_card.dart';
import 'widgets/registration_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                const RegistrationNavigationConsumed(),
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
                              const PhoneOtpCard(),
                              SizedBox(height: 18.h),
                              const LoginGoogleSection(),
                              SizedBox(height: 10.h),
                              TextButton(
                                onPressed: () {
                                  context.go(AppRoutes.registration);
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
    );
  }
}
