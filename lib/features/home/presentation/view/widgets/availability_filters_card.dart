import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_options.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/glass_container.dart';

class AvailabilityFiltersCard extends StatelessWidget {
  const AvailabilityFiltersCard({
    required this.selectedGameId,
    required this.selectedLanguage,
    required this.selectedRank,
    required this.onGameChanged,
    required this.onLanguageChanged,
    required this.onRankChanged,
    super.key,
  });

  final String? selectedGameId;
  final String? selectedLanguage;
  final String? selectedRank;
  final ValueChanged<String?> onGameChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onRankChanged;

  @override
  Widget build(BuildContext context) {
    final gameIds = AppOptions.gameOptions
        .map((GameOption game) => game.id)
        .toList(growable: false);
    final resolvedGameId = _resolveSelection(selectedGameId, gameIds);

    final rankOptions = resolvedGameId == null
        ? const <RankOption>[]
        : AppOptions.rankOptionsByGame(resolvedGameId);
    final rankNames = rankOptions
        .map((RankOption rank) => rank.name)
        .toList(growable: false);
    final resolvedRank = _resolveSelection(selectedRank, rankNames);
    final resolvedLanguage = _resolveSelection(
      selectedLanguage,
      AppOptions.languageOptions,
    );

    return GlassContainer(
      borderRadius: 22.r,
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppStrings.availabilityPreferences,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 8.h),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final fullWidth = constraints.maxWidth;
              final itemWidth = (fullWidth - 8.w) / 2;

              return Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: <Widget>[
                  SizedBox(
                    width: itemWidth,
                    child: _DropdownField(
                      label: AppStrings.game,
                      initialValue: resolvedGameId,
                      options: AppOptions.gameOptions
                          .map(
                            (GameOption game) => DropdownMenuItem<String>(
                              value: game.id,
                              child: _ImageLabelRow(
                                imageUrl: game.imageUrl,
                                text: game.name,
                              ),
                            ),
                          )
                          .toList(),
                      selectedTextOptions: AppOptions.gameOptions
                          .map((GameOption game) => game.name)
                          .toList(growable: false),
                      onChanged: onGameChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _DropdownField(
                      label: AppStrings.filterRank,
                      initialValue: resolvedRank,
                      options: rankOptions
                          .map(
                            (RankOption rank) => DropdownMenuItem<String>(
                              value: rank.name,
                              child: _ImageLabelRow(
                                imageUrl: rank.imageUrl,
                                text: rank.name,
                              ),
                            ),
                          )
                          .toList(),
                      selectedTextOptions: rankNames,
                      selectedWidgets: rankOptions
                          .map(
                            (RankOption rank) => _ImageLabelRow(
                              imageUrl: rank.imageUrl,
                              text: rank.name,
                            ),
                          )
                          .toList(),
                      onChanged: resolvedGameId == null ? null : onRankChanged,
                    ),
                  ),
                  SizedBox(
                    width: fullWidth,
                    child: _DropdownField(
                      label: AppStrings.filterLanguage,
                      initialValue: resolvedLanguage,
                      options: AppOptions.languageOptions
                          .map(
                            (String language) => DropdownMenuItem<String>(
                              value: language,
                              child: Text(language),
                            ),
                          )
                          .toList(),
                      selectedTextOptions: AppOptions.languageOptions,
                      onChanged: onLanguageChanged,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.initialValue,
    required this.options,
    required this.selectedTextOptions,
    required this.onChanged,
    this.selectedWidgets,
  });

  final String label;
  final String? initialValue;
  final List<DropdownMenuItem<String>> options;
  final List<String> selectedTextOptions;
  final ValueChanged<String?>? onChanged;
  final List<Widget>? selectedWidgets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: 4.h),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final selectedRowMaxWidth = (constraints.maxWidth - 58.w)
                .clamp(96.0, 340.0)
                .toDouble();

            return DropdownButtonFormField<String>(
              key: ValueKey<String>(
                '$label-${initialValue ?? 'none'}-${selectedTextOptions.join(',')}',
              ),
              initialValue: initialValue,
              items: options,
              selectedItemBuilder: (BuildContext context) {
                if (selectedWidgets != null) {
                  return selectedWidgets!
                      .map(
                        (Widget child) =>
                            SizedBox(width: selectedRowMaxWidth, child: child),
                      )
                      .toList();
                }
                return selectedTextOptions
                    .map(
                      (String value) => Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: selectedRowMaxWidth,
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList();
              },
              onChanged: options.isEmpty ? null : onChanged,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 10.h,
                ),
              ),
              borderRadius: BorderRadius.circular(18.r),
            );
          },
        ),
      ],
    );
  }
}

class _ImageLabelRow extends StatelessWidget {
  const _ImageLabelRow({required this.imageUrl, required this.text});

  final String imageUrl;
  final String text;

  @override
  Widget build(BuildContext context) {
    final resolvedMaxTextWidth = (MediaQuery.sizeOf(context).width * 0.36)
        .clamp(110.0, 240.0)
        .toDouble();

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: imageUrl.startsWith('http')
              ? Image.network(
                  imageUrl,
                  width: 24.w,
                  height: 24.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _ImageFallback(size: 24.w);
                  },
                )
              : Image.asset(
                  imageUrl,
                  width: 24.w,
                  height: 24.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _ImageFallback(size: 24.w);
                  },
                ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: resolvedMaxTextWidth),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.navSurface,
      alignment: Alignment.center,
      child: Icon(Icons.image, size: 14.sp, color: AppColors.textSecondary),
    );
  }
}

String? _resolveSelection(String? value, List<String> options) {
  if (value == null || !options.contains(value)) {
    return null;
  }
  return value;
}
