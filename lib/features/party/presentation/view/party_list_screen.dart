import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_options.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glow_background.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<PartyBloc>().add(PartyListRequested(gameId: widget.gameId));
  }

  Future<void> _handleJoin(String partyId) async {
    if (_pendingJoinIds.contains(partyId)) {
      return;
    }
    setState(() {
      _pendingJoinIds.add(partyId);
    });
    context.read<PartyBloc>().add(
          PartyJoinRequested(
            partyId: partyId,
          ),
        );
    await context.push(AppRoutes.partyDetailsPath(partyId));
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingJoinIds.remove(partyId);
    });
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
                      if (state is PartyError) {
                        AppSnackBar.showError(context, state.message);
                        _pendingJoinIds.clear();
                      }
                    },
                    builder: (BuildContext context, PartyState state) {
                      final parties = state.data.parties;
                      final title =
                          '${AppOptions.gameNameById(widget.gameId)} ${AppStrings.parties}';

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
                                    IconButton(
                                      onPressed: () {},
                                      icon: Icon(Icons.search, size: 22.sp),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: const <Widget>[
                                      _FilterChip(label: AppStrings.filterRank),
                                      _Gap(),
                                      _FilterChip(
                                        label: AppStrings.filterLanguage,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Expanded(
                            child: state is PartyLoading && parties.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.fromLTRB(
                                      contentPadding.left,
                                      4.h,
                                      contentPadding.right,
                                      24.h,
                                    ),
                                    itemCount: parties.length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(height: 14.h),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          final party = parties[index];
                                          return PartyCard(
                                            party: party,
                                            isJoining: _pendingJoinIds.contains(
                                              party.id,
                                            ),
                                            onJoin: () {
                                              _handleJoin(party.id);
                                            },
                                          );
                                        },
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
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
