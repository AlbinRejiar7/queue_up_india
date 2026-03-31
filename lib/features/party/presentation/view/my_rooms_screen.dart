import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../bloc/party_bloc.dart';
import '../../bloc/party_event.dart';
import '../../bloc/party_state.dart';
import 'widgets/empty_rooms_card.dart';
import 'widgets/my_room_card.dart';
import 'widgets/my_rooms_section.dart';

class MyRoomsScreen extends StatefulWidget {
  const MyRoomsScreen({
    super.key,
    this.showBackButton = true,
    this.selectedGameId,
  });

  final bool showBackButton;
  final String? selectedGameId;

  @override
  State<MyRoomsScreen> createState() => _MyRoomsScreenState();
}

class _MyRoomsScreenState extends State<MyRoomsScreen>
    with AutomaticKeepAliveClientMixin<MyRoomsScreen> {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<PartyBloc>();
    if (bloc.state.data.createdParties.isEmpty) {
      bloc.add(const PartyRoomsRequested());
    }
  }

  Future<void> _handleRefresh() async {
    final bloc = context.read<PartyBloc>();
    bloc.add(const PartyRoomsRequested());
    await bloc.stream.firstWhere((state) => state is PartyLoading);
    await bloc.stream.firstWhere((state) => state is! PartyLoading);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                      }
                    },
                    builder: (BuildContext context, PartyState state) {
                      final created = state.data.createdParties;
                      final isLoading =
                          state is PartyLoading && created.isEmpty;
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
                                    if (widget.showBackButton)
                                      const SafeBackButton(
                                        fallbackRoute: AppRoutes.home,
                                      )
                                    else
                                      SizedBox(width: 48.w),
                                    Expanded(
                                      child: Text(
                                        AppStrings.myRooms,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.pageTitle,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        context.read<PartyBloc>().add(
                                          const PartyRoomsRequested(),
                                        );
                                      },
                                      icon: const Icon(Icons.refresh_rounded),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _handleRefresh,
                              child: isLoading
                                  ? ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.fromLTRB(
                                        contentPadding.left,
                                        120.h,
                                        contentPadding.right,
                                        22.h,
                                      ),
                                      children: const <Widget>[
                                        Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ],
                                    )
                                  : ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.fromLTRB(
                                        contentPadding.left,
                                        14.h,
                                        contentPadding.right,
                                        22.h,
                                      ),
                                      children: <Widget>[
                                        GlassContainer(
                                          padding: EdgeInsets.all(14.w),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Icon(
                                                Icons.info_outline_rounded,
                                                size: 20.sp,
                                                color: Colors.white70,
                                              ),
                                              SizedBox(width: 10.w),
                                              Expanded(
                                                child: Text(
                                                  AppStrings
                                                      .partyAutoDeleteInfo,
                                                  style:
                                                      AppTextStyles.bodyMedium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 14.h),
                                        if (created.isEmpty)
                                          const EmptyRoomsCard(
                                            message: AppStrings.noCreatedRooms,
                                          )
                                        else if (isTablet)
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                AppStrings.createdRooms,
                                                style: AppTextStyles
                                                    .sectionTitle
                                                    .copyWith(fontSize: 21.sp),
                                              ),
                                              SizedBox(height: 10.h),
                                              GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount: created.length,
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2,
                                                      mainAxisExtent: 190.h,
                                                      mainAxisSpacing: 12.h,
                                                      crossAxisSpacing: 12.w,
                                                    ),
                                                itemBuilder: (BuildContext context, int index) {
                                                  final party = created[index];
                                                  return MyRoomCard(
                                                    party: party,
                                                    isCreatedRoom: true,
                                                    onOpen: () {
                                                      context.push(
                                                        AppRoutes.partyDetailsPath(
                                                          party.id,
                                                        ),
                                                      );
                                                    },
                                                    onDelete: () async {
                                                      final partyBloc = context
                                                          .read<PartyBloc>();
                                                      final shouldDelete =
                                                          await AppDialog.showConfirm(
                                                            context,
                                                            title: AppStrings
                                                                .confirmDeletePartyTitle,
                                                            message: AppStrings
                                                                .confirmDeletePartyMessage,
                                                            confirmLabel:
                                                                AppStrings
                                                                    .deleteParty,
                                                            cancelLabel:
                                                                AppStrings
                                                                    .cancelAction,
                                                            confirmIsDestructive:
                                                                true,
                                                          );
                                                      if (!shouldDelete) {
                                                        return;
                                                      }
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      partyBloc.add(
                                                        PartyLeaveRequested(
                                                          partyId: party.id,
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          )
                                        else
                                          MyRoomsSection(
                                            title: AppStrings.createdRooms,
                                            parties: created,
                                            isCreatedSection: true,
                                            onDelete: (party) async {
                                              final partyBloc = context
                                                  .read<PartyBloc>();
                                              final shouldDelete =
                                                  await AppDialog.showConfirm(
                                                    context,
                                                    title: AppStrings
                                                        .confirmDeletePartyTitle,
                                                    message: AppStrings
                                                        .confirmDeletePartyMessage,
                                                    confirmLabel:
                                                        AppStrings.deleteParty,
                                                    cancelLabel:
                                                        AppStrings.cancelAction,
                                                    confirmIsDestructive: true,
                                                  );
                                              if (!shouldDelete) {
                                                return;
                                              }
                                              if (!context.mounted) {
                                                return;
                                              }
                                              partyBloc.add(
                                                PartyLeaveRequested(
                                                  partyId: party.id,
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
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
