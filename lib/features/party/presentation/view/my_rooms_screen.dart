import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_options.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../bloc/party_bloc.dart';
import '../../bloc/party_event.dart';
import '../../bloc/party_state.dart';
import 'widgets/empty_rooms_card.dart';
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

class _MyRoomsScreenState extends State<MyRoomsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PartyBloc>().add(const PartyRoomsRequested());
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
                      }
                    },
                    builder: (BuildContext context, PartyState state) {
                      final created = state.data.createdParties;
                      final isLoading = state is PartyLoading && created.isEmpty;
                      final selectedGameId =
                          widget.selectedGameId ?? AppOptions.valorantId;

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
                            child: isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ListView(
                                    padding: EdgeInsets.fromLTRB(
                                      contentPadding.left,
                                      14.h,
                                      contentPadding.right,
                                      22.h,
                                    ),
                                    children: <Widget>[
                                      if (created.isEmpty)
                                        const EmptyRoomsCard(
                                          message: AppStrings.noCreatedRooms,
                                        )
                                      else
                                        MyRoomsSection(
                                          title: AppStrings.createdRooms,
                                          parties: created,
                                          isCreatedSection: true,
                                          onDelete: (party) async {
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
                                            context.read<PartyBloc>().add(
                                              PartyLeaveRequested(
                                                partyId: party.id,
                                              ),
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
