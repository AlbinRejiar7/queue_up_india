import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_options.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../bloc/party_bloc.dart';
import '../../bloc/party_event.dart';
import '../../bloc/party_state.dart';

class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({
    required this.gameId,
    super.key,
    this.showBackButton = true,
  });

  final String gameId;
  final bool showBackButton;

  @override
  State<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  late final TextEditingController _partyNameController;
  late final TextEditingController _partyCodeController;

  @override
  void initState() {
    super.initState();
    _partyNameController = TextEditingController();
    _partyCodeController = TextEditingController();
    context.read<PartyBloc>().add(PartyCreateStarted(gameId: widget.gameId));
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _partyCodeController.dispose();
    super.dispose();
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
                  return BlocConsumer<PartyBloc, PartyState>(
                    listener: (BuildContext context, PartyState state) {
                      if (_partyNameController.text !=
                          state.data.form.partyName) {
                        _partyNameController.value = TextEditingValue(
                          text: state.data.form.partyName,
                          selection: TextSelection.collapsed(
                            offset: state.data.form.partyName.length,
                          ),
                        );
                      }

                      if (_partyCodeController.text !=
                          state.data.form.partyCode) {
                        _partyCodeController.text = state.data.form.partyCode;
                      }

                      if (state is PartySuccess &&
                          state.data.isCreateCompleted &&
                          state.data.navigationPartyId != null) {
                        context.push(
                          AppRoutes.partyDetailsPath(
                            state.data.navigationPartyId!,
                          ),
                        );
                        context.read<PartyBloc>().add(
                          const PartyNavigationConsumed(),
                        );
                      }

                      if (state is PartyError) {
                        AppSnackBar.showError(context, state.message);
                      }
                    },
                    builder: (BuildContext context, PartyState state) {
                      final form = state.data.form;
                      final isLoading = state is PartyLoading;
                      final neededPlayers = form.maxPlayers - 1;
                      final requestedGameId = form.gameId.isEmpty
                          ? widget.gameId
                          : form.gameId;
                      final knownGameIds = AppOptions.gameOptions
                          .map((GameOption game) => game.id)
                          .toList(growable: false);
                      final gameId =
                          _resolveSelection(
                            requestedGameId,
                            knownGameIds,
                            fallbackToFirst: true,
                          ) ??
                          AppOptions.valorantId;
                      final rankOptions = AppOptions.rankOptionsByGame(gameId);

                      return Column(
                        children: <Widget>[
                          Padding(
                            padding: contentPadding,
                            child: Column(
                              children: <Widget>[
                                SizedBox(height: 6.h),
                                Row(
                                  children: <Widget>[
                                    if (widget.showBackButton)
                                      SafeBackButton(
                                        fallbackRoute: AppRoutes.partyListPath(
                                          gameId,
                                        ),
                                      )
                                    else
                                      SizedBox(width: 48.w),
                                    Expanded(
                                      child: Text(
                                        AppStrings.createParty,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.pageTitle,
                                      ),
                                    ),
                                    SizedBox(width: 48.w),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                contentPadding.left,
                                12.h,
                                contentPadding.right,
                                24.h,
                              ),
                              children: <Widget>[
                                _GameDropdownField(
                                  value: gameId,
                                  options: AppOptions.gameOptions,
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      context.read<PartyBloc>().add(
                                        PartyFormGameChanged(value: value),
                                      );
                                    }
                                  },
                                ),
                                SizedBox(height: 16.h),
                                _Label(text: AppStrings.partyName),
                                SizedBox(height: 8.h),
                                TextField(
                                  controller: _partyNameController,
                                  onChanged: (String value) {
                                    context.read<PartyBloc>().add(
                                      PartyFormNameChanged(value: value),
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText: AppStrings.partyNameHint,
                                  ),
                                ),
                                SizedBox(height: 18.h),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _RankDropdownField(
                                        value: form.rank,
                                        options: rankOptions,
                                        onChanged: (String? value) {
                                          if (value != null) {
                                            context.read<PartyBloc>().add(
                                              PartyFormRankChanged(
                                                value: value,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: _DropdownField(
                                        label: AppStrings.filterLanguage,
                                        value: form.language,
                                        options: AppOptions.languageOptions,
                                        onChanged: (String? value) {
                                          if (value != null) {
                                            context.read<PartyBloc>().add(
                                              PartyFormLanguageChanged(
                                                value: value,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 18.h),
                                const _Label(text: AppStrings.maxPlayers),
                                SizedBox(height: 8.h),
                                GlassContainer(
                                  borderRadius: 24.r,
                                  child: Row(
                                    children: <Widget>[
                                      IconButton(
                                        onPressed: () {
                                          context.read<PartyBloc>().add(
                                            const PartyFormMaxPlayersDecremented(),
                                          );
                                        },
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              AppColors.textPrimary,
                                          foregroundColor: AppColors.navSurface,
                                          minimumSize: Size(48.w, 48.w),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14.r,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(Icons.remove, size: 22.sp),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            '$neededPlayers',
                                            style: AppTextStyles.sectionTitle
                                                .copyWith(fontSize: 24.sp),
                                          ),
                                        ),
                                      ),
                                      IconButton.filled(
                                        onPressed: () {
                                          context.read<PartyBloc>().add(
                                            const PartyFormMaxPlayersIncremented(),
                                          );
                                        },
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              AppColors.electricBlue,
                                          foregroundColor: Colors.white,
                                          minimumSize: Size(52.w, 52.w),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(Icons.add, size: 24.sp),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      AppStrings.minTwo,
                                      style: AppTextStyles.caption.copyWith(
                                        letterSpacing: 1.6,
                                      ),
                                    ),
                                    Text(
                                      AppStrings.maxFive,
                                      style: AppTextStyles.caption.copyWith(
                                        letterSpacing: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 18.h),
                                _Label(text: AppStrings.partyCode),
                                SizedBox(height: 8.h),
                                TextField(
                                  controller: _partyCodeController,
                                  onChanged: (String value) {
                                    context.read<PartyBloc>().add(
                                      PartyFormCodeChanged(value: value),
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText: AppStrings.partyCodeHint,
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                PrimaryButton(
                                  label: AppStrings.createParty,
                                  icon: Icons.group_add_rounded,
                                  isLoading: isLoading,
                                  enabled: form.isValid,
                                  onDisabledPressed: () {
                                    AppSnackBar.showError(
                                      context,
                                      AppStrings.completePartyDetails,
                                    );
                                  },
                                  onPressed: () {
                                    context.read<PartyBloc>().add(
                                      const PartyCreateSubmitted(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: AppTextStyles.bodyMedium),
    );
  }
}

class _GameDropdownField extends StatelessWidget {
  const _GameDropdownField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<GameOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ids = options
        .map((GameOption game) => game.id)
        .toList(growable: false);
    final selected = _resolveSelection(value, ids, fallbackToFirst: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Label(text: AppStrings.game),
        SizedBox(height: 8.h),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final selectedRowMaxWidth = (constraints.maxWidth - 24.w)
                .clamp(120.0, constraints.maxWidth)
                .toDouble();
            final maxTextWidth = (selectedRowMaxWidth - 44.w).clamp(
              80.0,
              selectedRowMaxWidth,
            );

            return DropdownButtonFormField<String>(
              key: ValueKey<String>(
                'game-${selected ?? 'none'}-${ids.join(',')}',
              ),
              initialValue: selected,
              isExpanded: true,
              items: options
                  .map(
                    (game) => DropdownMenuItem<String>(
                      value: game.id,
                      child: _ImageLabelRow(
                        imageUrl: game.imageUrl,
                        text: game.name,
                        maxTextWidth: maxTextWidth,
                        fitText: false,
                        showEllipsis: false,
                      ),
                    ),
                  )
                  .toList(),
              selectedItemBuilder: (BuildContext context) {
                return options
                    .map(
                      (GameOption game) => SizedBox(
                        width: selectedRowMaxWidth,
                        child: _ImageLabelRow(
                          imageUrl: game.imageUrl,
                          text: game.name,
                          maxTextWidth: maxTextWidth,
                          fitText: true,
                          showEllipsis: false,
                        ),
                      ),
                    )
                    .toList();
              },
              onChanged: ids.isEmpty ? null : onChanged,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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

class _RankDropdownField extends StatelessWidget {
  const _RankDropdownField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<RankOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final names = options
        .map((RankOption rank) => rank.name)
        .toList(growable: false);
    final selected = _resolveSelection(value, names, fallbackToFirst: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Label(text: AppStrings.filterRank),
        SizedBox(height: 8.h),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final selectedRowMaxWidth = (constraints.maxWidth - 24.w)
                .clamp(120.0, constraints.maxWidth)
                .toDouble();
            final maxTextWidth = (selectedRowMaxWidth - 44.w).clamp(
              80.0,
              selectedRowMaxWidth,
            );

            return DropdownButtonFormField<String>(
              key: ValueKey<String>(
                'rank-${selected ?? 'none'}-${names.join(',')}',
              ),
              initialValue: selected,
              isExpanded: true,
              items: options
                  .map(
                    (rank) => DropdownMenuItem<String>(
                      value: rank.name,
                      child: _ImageLabelRow(
                        imageUrl: rank.imageUrl,
                        text: rank.name,
                        maxTextWidth: maxTextWidth,
                        fitText: false,
                        showEllipsis: false,
                      ),
                    ),
                  )
                  .toList(),
              selectedItemBuilder: (BuildContext context) {
                return options
                    .map(
                      (RankOption rank) => SizedBox(
                        width: selectedRowMaxWidth,
                        child: _ImageLabelRow(
                          imageUrl: rank.imageUrl,
                          text: rank.name,
                          maxTextWidth: maxTextWidth,
                          fitText: true,
                          showEllipsis: false,
                        ),
                      ),
                    )
                    .toList();
              },
              onChanged: names.isEmpty ? null : onChanged,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _resolveSelection(value, options, fallbackToFirst: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Label(text: label),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('$label-${selected ?? 'none'}'),
          initialValue: selected,
          isExpanded: true,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: options.isEmpty ? null : onChanged,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          borderRadius: BorderRadius.circular(18.r),
        ),
      ],
    );
  }
}

class _ImageLabelRow extends StatelessWidget {
  const _ImageLabelRow({
    required this.imageUrl,
    required this.text,
    this.maxTextWidth,
    this.showEllipsis = true,
    this.fitText = false,
  });

  final String imageUrl;
  final String text;
  final double? maxTextWidth;
  final bool showEllipsis;
  final bool fitText;

  @override
  Widget build(BuildContext context) {
    final resolvedMaxTextWidth =
        maxTextWidth ??
        (MediaQuery.sizeOf(context).width * 0.5).clamp(140.0, 420.0).toDouble();

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: imageUrl.startsWith('http')
              ? AppNetworkImage(
                  imageUrl: imageUrl,
                  width: 24.w,
                  height: 24.w,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.image,
                  placeholderIconSize: 14.sp,
                  backgroundColor: AppColors.navSurface,
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
            child: fitText
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                : Text(
                    text,
                    maxLines: 1,
                    overflow: showEllipsis
                        ? TextOverflow.ellipsis
                        : TextOverflow.visible,
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

String? _resolveSelection(
  String? value,
  List<String> options, {
  required bool fallbackToFirst,
}) {
  if (options.isEmpty) {
    return null;
  }

  if (value != null && options.contains(value)) {
    return value;
  }

  return fallbackToFirst ? options.first : null;
}
