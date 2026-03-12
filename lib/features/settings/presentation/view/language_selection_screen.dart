import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../bloc/language_bloc.dart';
import '../../bloc/language_event.dart';
import '../../bloc/language_state.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  @override
  void initState() {
    super.initState();
    final LanguageState state = context.read<LanguageBloc>().state;
    if (state is! LanguageSuccess) {
      context.read<LanguageBloc>().add(const LanguageBootstrapRequested());
    }
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
                  return BlocConsumer<LanguageBloc, LanguageState>(
                    listener: (BuildContext context, LanguageState state) {
                      if (state is LanguageSuccess &&
                          state.data.didCompleteSelection) {
                        context.go(AppRoutes.login);
                      }
                      if (state is LanguageError) {
                        AppSnackBar.showError(context, state.message);
                      }
                    },
                    builder: (BuildContext context, LanguageState state) {
                      final data = state.data;
                      final isLoading = state is LanguageLoading;

                      return Padding(
                        padding: contentPadding,
                        child: Column(
                          children: <Widget>[
                            SizedBox(height: 10.h),
                            Row(
                              children: <Widget>[
                                const SafeBackButton(
                                  fallbackRoute: AppRoutes.login,
                                  tonal: true,
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      AppStrings.stepOneOfThree,
                                      style: AppTextStyles.caption.copyWith(
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 48.w),
                              ],
                            ),
                            SizedBox(height: 22.h),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text.rich(
                                TextSpan(
                                  text: 'Choose Your\n',
                                  children: <InlineSpan>[
                                    TextSpan(
                                      text: 'Language',
                                      style: TextStyle(
                                        color: AppColors.electricBlue,
                                        fontSize: 34.sp,
                                      ),
                                    ),
                                  ],
                                ),
                                style: AppTextStyles.sectionTitle.copyWith(
                                  fontSize: 34.sp,
                                  height: 1.25,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppStrings.languageDescription,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 20.h),
                            Expanded(
                              child: ListView.separated(
                                itemCount: data.languages.length + 1,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: 12.h),
                                itemBuilder: (BuildContext context, int index) {
                                  if (index == data.languages.length) {
                                    return GlassContainer(
                                      borderRadius: 26.r,
                                      child: SizedBox(
                                        height: 46.h,
                                        child: Center(
                                          child: Text(
                                            AppStrings.moreComingSoon,
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final language = data.languages[index];
                                  final selected =
                                      language.code == data.selectedCode;

                                  return GlassContainer(
                                    borderRadius: 28.r,
                                    borderColor: selected
                                        ? AppColors.electricBlue
                                        : Colors.white.withValues(alpha: 0.08),
                                    backgroundColor: selected
                                        ? AppColors.electricBlue.withValues(
                                            alpha: 0.12,
                                          )
                                        : Colors.white.withValues(alpha: 0.025),
                                    onTap: () {
                                      context.read<LanguageBloc>().add(
                                        LanguageSelected(code: language.code),
                                      );
                                    },
                                    child: SizedBox(
                                      height: 72.h,
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text(
                                                  language.nativeLabel,
                                                  style: AppTextStyles.pageTitle
                                                      .copyWith(
                                                        fontSize: 21.sp,
                                                      ),
                                                ),
                                                SizedBox(height: 3.h),
                                                Text(
                                                  language.subtitle,
                                                  style:
                                                      AppTextStyles.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                          AnimatedOpacity(
                                            opacity: selected ? 1 : 0,
                                            duration: const Duration(
                                              milliseconds: 160,
                                            ),
                                            child: Icon(
                                              Icons.check_circle,
                                              color: AppColors.electricBlue,
                                              size: 22.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            PrimaryButton(
                              label: AppStrings.continueAction,
                              icon: Icons.arrow_forward,
                              isLoading: isLoading,
                              enabled: data.canContinue,
                              onDisabledPressed: () {
                                AppSnackBar.showError(
                                  context,
                                  AppStrings.selectLanguageFirst,
                                );
                              },
                              onPressed: () {
                                context.read<LanguageBloc>().add(
                                  const LanguageContinuePressed(),
                                );
                              },
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              AppStrings.languageSettingsHint,
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                          ],
                        ),
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
