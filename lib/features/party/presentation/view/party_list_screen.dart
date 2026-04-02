import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../bloc/party_bloc.dart';
import '../../bloc/party_event.dart';
import '../../bloc/party_state.dart';
import 'widgets/party_card.dart';

class PartyListScreen extends StatefulWidget {
  const PartyListScreen({required this.gameId, super.key});

  final String gameId;

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  final Set<String> _pendingJoinIds = <String>{};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<PartyBloc>().add(PartyListRequested(gameId: widget.gameId));
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= 200.h) {
      context.read<PartyBloc>().add(const PartyListLoadMoreRequested());
    }
  }

  Future<void> _handleRefresh() async {
    final bloc = context.read<PartyBloc>();
    bloc.add(const PartyListRefreshRequested());
    await bloc.stream.firstWhere((state) => state is PartyLoading);
    await bloc.stream.firstWhere((state) => state is! PartyLoading);
  }

  Future<void> _handleJoin(String partyId) async {
    if (_pendingJoinIds.contains(partyId)) {
      return;
    }
    setState(() {
      _pendingJoinIds.add(partyId);
    });
    context.read<PartyBloc>().add(PartyJoinRequested(partyId: partyId));
    await context.push(AppRoutes.partyDetailsPath(partyId));
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingJoinIds.remove(partyId);
    });
  }

  Future<void> _showRankFilterSheet({
    required String gameId,
    required String? selected,
  }) async {
    final options = AppOptions.rankOptionsByGame(gameId);
    final result = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(AppStrings.filterRank, style: AppTextStyles.sectionTitle),
                SizedBox(height: 12.h),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length + 1,
                    separatorBuilder: (_, _) => SizedBox(height: 8.h),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return _FilterSheetTile(
                          label: AppStrings.filterAllRanks,
                          isSelected: selected == null,
                          onTap: () => Navigator.of(context).pop(null),
                        );
                      }
                      final option = options[index - 1];
                      return _FilterSheetTile(
                        label: option.name,
                        isSelected: option.name == selected,
                        rankImagePath: option.imageUrl,
                        onTap: () => Navigator.of(context).pop(option.name),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    context.read<PartyBloc>().add(PartyFilterRankChanged(value: result));
  }

  Future<void> _showLanguageFilterSheet({required String? selected}) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.filterLanguage,
                  style: AppTextStyles.sectionTitle,
                ),
                SizedBox(height: 12.h),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: AppOptions.languageOptions.length + 1,
                    separatorBuilder: (_, _) => SizedBox(height: 8.h),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return _FilterSheetTile(
                          label: AppStrings.filterAllLanguages,
                          isSelected: selected == null,
                          onTap: () => Navigator.of(context).pop(null),
                        );
                      }
                      final option = AppOptions.languageOptions[index - 1];
                      return _FilterSheetTile(
                        label: option,
                        isSelected: option == selected,
                        onTap: () => Navigator.of(context).pop(option),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    context.read<PartyBloc>().add(PartyFilterLanguageChanged(value: result));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: ResponsiveLayoutBuilder(
            tabletMaxWidth: 960,
            tabletHorizontalPadding: 32,
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsets contentPadding,
                ) {
                  return BlocConsumer<PartyBloc, PartyState>(
                    listener: (BuildContext context, PartyState state) {
                      if (state is PartyError) {
                        AppSnackBar.showError(context, state.message);
                        _pendingJoinIds.clear();
                      }
                    },
                    builder: (BuildContext context, PartyState state) {
                      final rankFilter = state.data.selectedRankFilter;
                      final languageFilter = state.data.selectedLanguageFilter;
                      final parties = state.data.parties;
                      final isLoadingMore = state.data.isLoadingMoreParties;
                      final title =
                          '${AppOptions.gameNameById(widget.gameId)} ${AppStrings.parties}';
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;
                      final bool isTablet = constraints.maxWidth >= 600;

                      return Column(
                        children: <Widget>[
                          Padding(
                            padding: contentPadding,
                            child: Column(
                              children: <Widget>[
                                SizedBox(height: 6.h),
                                Row(
                                  children: <Widget>[
                                    const SafeBackButton(
                                      fallbackRoute: AppRoutes.gameSelection,
                                    ),
                                    SizedBox(width: 6.w),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: AppTextStyles.pageTitle,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: <Widget>[
                                      _FilterChip(
                                        label:
                                            rankFilter ?? AppStrings.filterRank,
                                        onTap: () {
                                          _showRankFilterSheet(
                                            gameId: widget.gameId,
                                            selected: rankFilter,
                                          );
                                        },
                                      ),
                                      const _Gap(),
                                      _FilterChip(
                                        label:
                                            languageFilter ??
                                            AppStrings.filterLanguage,
                                        onTap: () {
                                          _showLanguageFilterSheet(
                                            selected: languageFilter,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                PrimaryButton(
                                  label: AppStrings.seeAvailableSoloPlayers,
                                  icon: Icons.groups_rounded,
                                  onPressed: () {
                                    context.push(
                                      '${AppRoutes.availablePlayers}?gameId=${widget.gameId}',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _handleRefresh,
                              child: state is PartyLoading && parties.isEmpty
                                  ? ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.fromLTRB(
                                        contentPadding.left,
                                        120.h,
                                        contentPadding.right,
                                        24.h,
                                      ),
                                      children: const <Widget>[
                                        Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ],
                                    )
                                  : parties.isEmpty
                                  ? ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.fromLTRB(
                                        contentPadding.left,
                                        120.h,
                                        contentPadding.right,
                                        24.h,
                                      ),
                                      children: <Widget>[
                                        Center(
                                          child: Text(
                                            AppStrings.noPartiesAvailable,
                                            style: AppTextStyles.bodyMedium,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    )
                                  : (isTablet
                                        ? GridView.builder(
                                            controller: _scrollController,
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            padding: EdgeInsets.fromLTRB(
                                              contentPadding.left,
                                              4.h,
                                              contentPadding.right,
                                              24.h,
                                            ),
                                            itemCount:
                                                parties.length +
                                                (isLoadingMore ? 1 : 0),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 2,
                                                  mainAxisExtent: 320.h,
                                                  mainAxisSpacing: 14.h,
                                                  crossAxisSpacing: 14.w,
                                                ),
                                            itemBuilder:
                                                (
                                                  BuildContext context,
                                                  int index,
                                                ) {
                                                  if (index >= parties.length) {
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  }
                                                  final party = parties[index];
                                                  return PartyCard(
                                                    party: party,
                                                    isJoining: _pendingJoinIds
                                                        .contains(party.id),
                                                    onJoin: () {
                                                      final isOwner =
                                                          currentUserId !=
                                                              null &&
                                                          party.hostId ==
                                                              currentUserId;
                                                      if (isOwner) {
                                                        AppSnackBar.showError(
                                                          context,
                                                          AppStrings
                                                              .cannotJoinOwnParty,
                                                        );
                                                        return;
                                                      }
                                                      _handleJoin(party.id);
                                                    },
                                                  );
                                                },
                                          )
                                        : ListView.separated(
                                            controller: _scrollController,
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            padding: EdgeInsets.fromLTRB(
                                              contentPadding.left,
                                              4.h,
                                              contentPadding.right,
                                              24.h,
                                            ),
                                            itemCount:
                                                parties.length +
                                                (isLoadingMore ? 1 : 0),
                                            separatorBuilder:
                                                (context, index) =>
                                                    SizedBox(height: 14.h),
                                            itemBuilder:
                                                (
                                                  BuildContext context,
                                                  int index,
                                                ) {
                                                  if (index >= parties.length) {
                                                    return Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 8.h,
                                                          ),
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  }
                                                  final party = parties[index];
                                                  return PartyCard(
                                                    party: party,
                                                    isJoining: _pendingJoinIds
                                                        .contains(party.id),
                                                    onJoin: () {
                                                      final isOwner =
                                                          currentUserId !=
                                                              null &&
                                                          party.hostId ==
                                                              currentUserId;
                                                      if (isOwner) {
                                                        AppSnackBar.showError(
                                                          context,
                                                          AppStrings
                                                              .cannotJoinOwnParty,
                                                        );
                                                        return;
                                                      }
                                                      _handleJoin(party.id);
                                                    },
                                                  );
                                                },
                                          )),
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

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => SizedBox(width: 10.w);
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999.r),
          color: AppColors.electricBlue.withValues(alpha: 0.12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.expand_more, size: 18.sp),
          ],
        ),
      ),
    );
  }
}

class _FilterSheetTile extends StatelessWidget {
  const _FilterSheetTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.rankImagePath,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? rankImagePath;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: isSelected
              ? AppColors.electricBlue.withValues(alpha: 0.18)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.electricBlue : AppColors.navSurface,
          ),
        ),
        child: Row(
          children: <Widget>[
            if (rankImagePath != null) ...<Widget>[
              _RankImage(path: rankImagePath!),
              SizedBox(width: 10.w),
            ],
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: AppColors.electricBlue, size: 18.sp),
          ],
        ),
      ),
    );
  }
}

class _RankImage extends StatelessWidget {
  const _RankImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final size = 22.w;
    if (path.startsWith('http')) {
      return AppNetworkImage(
        imageUrl: path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderIcon: Icons.workspace_premium,
        placeholderIconSize: size,
        iconColor: AppColors.textSecondary,
        backgroundColor: Colors.transparent,
        showLoadingIndicator: false,
      );
    }
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _fallback(size),
    );
  }

  Widget _fallback(double size) {
    return Icon(
      Icons.workspace_premium,
      size: size,
      color: AppColors.textSecondary,
    );
  }
}
