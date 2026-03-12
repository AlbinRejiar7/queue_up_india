import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_options.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/glass_container.dart';

class AvailablePlayersFilters extends StatelessWidget {
  const AvailablePlayersFilters({
    required this.selectedGameId,
    required this.selectedRank,
    required this.selectedLanguage,
    required this.onGameChanged,
    required this.onRankChanged,
    required this.onLanguageChanged,
    required this.onReset,
    super.key,
  });

  final String? selectedGameId;
  final String? selectedRank;
  final String? selectedLanguage;
  final ValueChanged<String?> onGameChanged;
  final ValueChanged<String?> onRankChanged;
  final ValueChanged<String?> onLanguageChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final gameIds = AppOptions.gameOptions
        .map((GameOption game) => game.id)
        .toList(growable: false);
    final resolvedGame = _resolveSelection(selectedGameId, gameIds);

    final rankOptions = resolvedGame == null
        ? const <RankOption>[]
        : AppOptions.rankOptionsByGame(resolvedGame);
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
          Row(
            children: <Widget>[
              Text(
                AppStrings.filterLanguage,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
                  minimumSize: Size(0, 28.h),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppStrings.resetFilters,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.electricBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final maxWidth = constraints.maxWidth;
              final itemWidth = (maxWidth - 8.w) / 2;
              return Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: <Widget>[
                  SizedBox(
                    width: itemWidth,
                    child: _FilterDropdown(
                      label: AppStrings.game,
                      initialValue: resolvedGame,
                      options: AppOptions.gameOptions
                          .map(
                            (GameOption option) => DropdownMenuItem<String>(
                              value: option.id,
                              child: _ImageLabelRow(
                                imageUrl: option.imageUrl,
                                text: option.name.toUpperCase(),
                              ),
                            ),
                          )
                          .toList(),
                      selectedWidgets: AppOptions.gameOptions
                          .map(
                            (GameOption option) => _ImageLabelRow(
                              imageUrl: option.imageUrl,
                              text: option.name.toUpperCase(),
                            ),
                          )
                          .toList(),
                      onChanged: onGameChanged,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _FilterDropdown(
                      label: AppStrings.filterRank,
                      initialValue: resolvedRank,
                      options: rankOptions
                          .map(
                            (RankOption option) => DropdownMenuItem<String>(
                              value: option.name,
                              child: _ImageLabelRow(
                                imageUrl: option.imageUrl,
                                text: option.name.toUpperCase(),
                              ),
                            ),
                          )
                          .toList(),
                      selectedWidgets: rankOptions
                          .map(
                            (RankOption option) => _ImageLabelRow(
                              imageUrl: option.imageUrl,
                              text: option.name.toUpperCase(),
                            ),
                          )
                          .toList(),
                      onChanged: resolvedGame == null ? null : onRankChanged,
                    ),
                  ),
                  SizedBox(
                    width: maxWidth,
                    child: _FilterDropdown(
                      label: AppStrings.filterLanguage,
                      initialValue: resolvedLanguage,
                      options: AppOptions.languageOptions
                          .map(
                            (String option) => DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.initialValue,
    required this.options,
    required this.onChanged,
    this.selectedWidgets,
  });

  final String label;
  final String? initialValue;
  final List<DropdownMenuItem<String>> options;
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
            final selectedRowMaxWidth =
                (constraints.maxWidth - 56.w).clamp(0.0, constraints.maxWidth);

            return DropdownButtonFormField<String>(
              key: ValueKey<String>(
                '$label-${initialValue ?? 'none'}-${options.length}',
              ),
              isExpanded: true,
              initialValue: initialValue,
              items: options,
              selectedItemBuilder: (BuildContext context) {
                if (selectedWidgets == null) {
                  return options
                      .map(
                        (DropdownMenuItem<String> option) => Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: selectedRowMaxWidth,
                            child: Text(
                              option.value ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      )
                      .toList();
                }

                return selectedWidgets!
                    .map(
                      (Widget child) =>
                          SizedBox(width: selectedRowMaxWidth, child: child),
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
              borderRadius: BorderRadius.circular(16.r),
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
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: imageUrl.startsWith('http')
              ? Image.network(
                  imageUrl,
                  width: 20.w,
                  height: 20.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _ImageFallback(size: 20.w);
                  },
                )
              : Image.asset(
                  imageUrl,
                  width: 20.w,
                  height: 20.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _ImageFallback(size: 20.w);
                  },
                ),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
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
      child: Icon(Icons.image, size: 12.sp, color: AppColors.textSecondary),
    );
  }
}

String? _resolveSelection(String? value, List<String> options) {
  if (value == null || !options.contains(value)) {
    return null;
  }
  return value;
}
