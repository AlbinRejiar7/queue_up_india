import 'dart:developer' as developer;

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
import '../../bloc/registration_bloc.dart';
import '../../bloc/registration_event.dart';
import '../../bloc/registration_state.dart';
import 'widgets/avatar_selection_section.dart';
import 'widgets/password_credentials_card.dart';
import 'widgets/registration_header.dart';
import 'widgets/registration_username_field.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  void _returnToLogin(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        _returnToLogin(context);
      },
      child: Scaffold(
        body: GlowBackground(
          child: MultiBlocListener(
            listeners: <BlocListener<RegistrationBloc, RegistrationState>>[
              BlocListener<RegistrationBloc, RegistrationState>(
                listenWhen: (previous, current) =>
                    previous.data.didCompleteRegistration !=
                        current.data.didCompleteRegistration ||
                    (current is RegistrationError && previous != current),
                listener: (BuildContext context, RegistrationState state) {
                  if (state is RegistrationError) {
                    developer.log(
                      'Registration error shown: ${state.message}',
                      name: 'RegistrationScreen',
                    );
                    AppSnackBar.showError(context, state.message);
                  }

                  if (state is RegistrationSuccess &&
                      state.data.didCompleteRegistration) {
                    developer.log(
                      'Registration completed -> navigate home',
                      name: 'RegistrationScreen',
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
                                    IconButton(
                                      onPressed: () => _returnToLogin(context),
                                      icon: const Icon(Icons.arrow_back),
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
                                SizedBox(height: 18.h),
                                const PasswordCredentialsCard(),
                                SizedBox(height: 18.h),
                                const AvatarSelectionSection(),
                                SizedBox(height: 16.h),
                                BlocBuilder<
                                  RegistrationBloc,
                                  RegistrationState
                                >(
                                  builder: (context, state) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                text:
                                                    '${AppStrings.acceptLegalPrefix} ',
                                                style: AppTextStyles.caption,
                                                children: <TextSpan>[
                                                  TextSpan(
                                                    text: AppStrings
                                                        .privacyPolicy,
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                          color: AppColors
                                                              .electricBlue,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                                    text:
                                                        ' ${AppStrings.acceptLegalAnd} ',
                                                    style:
                                                        AppTextStyles.caption,
                                                  ),
                                                  TextSpan(
                                                    text: AppStrings
                                                        .termsOfService,
                                                    style: AppTextStyles.caption
                                                        .copyWith(
                                                          color: AppColors
                                                              .electricBlue,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                    recognizer:
                                                        TapGestureRecognizer()
                                                          ..onTap = () {
                                                            launchUrl(
                                                              Uri.parse(
                                                                AppStrings
                                                                    .termsUrl,
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
      ),
    );
  }
}
