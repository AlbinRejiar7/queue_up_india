import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/country_codes.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/glass_container.dart';
import '../../../../../core/widgets/primary_button.dart';
import '../../../bloc/registration_bloc.dart';
import '../../../bloc/registration_event.dart';
import '../../../bloc/registration_state.dart';

class PhoneOtpCard extends StatelessWidget {
  const PhoneOtpCard({super.key});

  Future<CountryCodeOption?> _showCountryCodeSheet(
    BuildContext context,
    CountryCodeOption selected,
  ) async {
    final result = await showModalBottomSheet<CountryCodeOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _CountryCodeSheet(selected: selected);
      },
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistrationBloc, RegistrationState>(
      builder: (BuildContext context, RegistrationState state) {
        final data = state.data;
        final bool isLoading = state is RegistrationLoading;
        final bool canVerify = data.canVerifyOtp && !isLoading;
        final String otpLabel = data.isOtpSent
            ? AppStrings.resendOtp
            : AppStrings.sendOtp;
        final bool needsUsername = data.isRegistration;
        final bool hasUsername = data.hasUsername;
        final selectedCountry =
            countryCodeOptionById(data.selectedCountryCodeId) ??
            countryCodeOptions.first;

        return GlassContainer(
          borderRadius: 28.r,
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                AppStrings.phoneNumber,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: <Widget>[
                  SizedBox(
                    width: 110.w,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18.r),
                      onTap: () async {
                        final option = await _showCountryCodeSheet(
                          context,
                          selectedCountry,
                        );
                        if (option == null) {
                          return;
                        }
                        context.read<RegistrationBloc>().add(
                          RegistrationCountryCodeChanged(
                            countryCodeId: option.id,
                          ),
                        );
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                selectedCountry.dialCode,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            Icon(
                              Icons.expand_more,
                              size: 18.sp,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextFormField(
                      initialValue: data.phoneNumber,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: const InputDecoration(
                        hintText: AppStrings.phoneNumberHint,
                      ),
                      onChanged: (String value) {
                        context.read<RegistrationBloc>().add(
                          RegistrationPhoneChanged(phoneNumber: value),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (!data.canSendOtp) {
                            if (needsUsername && !data.acceptedLegal) {
                              AppSnackBar.showError(
                                context,
                                AppStrings.acceptLegalRequired,
                              );
                              return;
                            }
                            if (needsUsername && !hasUsername) {
                              AppSnackBar.showError(
                                context,
                                AppStrings.usernameRequired,
                              );
                              return;
                            }
                            AppSnackBar.showError(
                              context,
                              AppStrings.invalidPhoneNumber,
                            );
                            return;
                          }
                          context.read<RegistrationBloc>().add(
                            const RegistrationSendOtpPressed(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: data.canSendOtp
                        ? AppColors.navSurface.withValues(alpha: 0.9)
                        : AppColors.navSurface.withValues(alpha: 0.35),
                    disabledBackgroundColor: AppColors.navSurface.withValues(
                      alpha: 0.35,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          otpLabel,
                          style: AppTextStyles.buttonText.copyWith(
                            fontSize: 14.sp,
                          ),
                        ),
                ),
              ),
              if (data.isOtpSent) ...<Widget>[
                SizedBox(height: 12.h),
                Text(
                  AppStrings.enterOtp,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  initialValue: data.otp,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    hintText: AppStrings.otpHint,
                  ),
                  onChanged: (String value) {
                    context.read<RegistrationBloc>().add(
                      RegistrationOtpChanged(otp: value),
                    );
                  },
                ),
                SizedBox(height: 14.h),
                PrimaryButton(
                  label: AppStrings.verifyOtp,
                  isLoading: isLoading,
                  enabled: canVerify,
                  onDisabledPressed: () {
                    if (needsUsername && !data.acceptedLegal) {
                      AppSnackBar.showError(
                        context,
                        AppStrings.acceptLegalRequired,
                      );
                      return;
                    }
                    if (needsUsername && !hasUsername) {
                      AppSnackBar.showError(
                        context,
                        AppStrings.usernameRequired,
                      );
                      return;
                    }
                    AppSnackBar.showError(context, AppStrings.invalidOtp);
                  },
                  onPressed: () {
                    context.read<RegistrationBloc>().add(
                      const RegistrationVerifyOtpPressed(),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CountryCodeSheet extends StatefulWidget {
  const _CountryCodeSheet({required this.selected});

  final CountryCodeOption selected;

  @override
  State<_CountryCodeSheet> createState() => _CountryCodeSheetState();
}

class _CountryCodeSheetState extends State<_CountryCodeSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? countryCodeOptions
        : countryCodeOptions
            .where(
              (option) =>
                  option.name.toLowerCase().contains(query) ||
                  option.dialCode.contains(query) ||
                  option.isoCode.toLowerCase().contains(query),
            )
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return GlassContainer(
          borderRadius: 28.r,
          padding: EdgeInsets.zero,
          backgroundColor: AppColors.navSurface.withValues(alpha: 0.96),
          child: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 42.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999.r),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        AppStrings.selectCountryCode,
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: AppStrings.searchCountry,
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final option = filtered[index];
                    final isSelected = option.id == widget.selected.id;
                    return Column(
                      children: <Widget>[
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          title: Text(
                            option.name,
                            style: AppTextStyles.bodyMedium,
                          ),
                          subtitle: Text(
                            option.dialCode,
                            style: AppTextStyles.caption,
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppColors.electricBlueBright,
                                  size: 18.sp,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(option),
                        ),
                        if (index != filtered.length - 1)
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                      ],
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            ],
          ),
        );
      },
    );
  }
}
