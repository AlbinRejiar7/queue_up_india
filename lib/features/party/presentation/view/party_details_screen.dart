import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../../chat/bloc/chat_bloc.dart';
import '../../../chat/viewmodel/chat_view_model.dart';
import '../../bloc/party_bloc.dart';
import '../../bloc/party_event.dart';
import '../../bloc/party_state.dart';
import 'widgets/party_chat_sheet.dart';
import 'widgets/party_overview_header.dart';
import 'widgets/player_tile.dart';

class PartyDetailsScreen extends StatefulWidget {
  const PartyDetailsScreen({required this.partyId, super.key});

  final String partyId;

  @override
  State<PartyDetailsScreen> createState() => _PartyDetailsScreenState();
}

class _PartyDetailsScreenState extends State<PartyDetailsScreen> {
  late final DraggableScrollableController _chatController;
  final ValueNotifier<double> _sheetSize = ValueNotifier(0.1);
  ChatBloc? _groupChatBloc;

  @override
  void initState() {
    super.initState();
    _chatController = DraggableScrollableController()
      ..addListener(_handleSheetChanged);
    context.read<PartyBloc>().add(
      PartyDetailsRequested(partyId: widget.partyId),
    );
  }

  @override
  void dispose() {
    _chatController.removeListener(_handleSheetChanged);
    _chatController.dispose();
    _sheetSize.dispose();
    _groupChatBloc?.close();
    super.dispose();
  }

  void _handleSheetChanged() {
    if (!_chatController.isAttached) {
      return;
    }
    _sheetSize.value = _chatController.size;
  }

  void _expandChat() {
    if (!_chatController.isAttached) {
      return;
    }
    _chatController.animateTo(
      0.9,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
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
                      if (state is PartySuccess &&
                          state.data.navigationPartyId == 'none') {
                        context.go(AppRoutes.home);
                        context.read<PartyBloc>().add(
                          const PartyNavigationConsumed(),
                        );
                      }
                      if (state is PartyError) {
                        AppSnackBar.showError(context, state.message);
                      }
                    },
                    builder: (BuildContext context, PartyState state) {
                      final party = state.data.selectedParty;

                      if (party == null || party.id != widget.partyId) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      _groupChatBloc ??= ChatBloc(
                        chatViewModel: sl<ChatViewModel>(),
                        scope: ChatScope.party,
                        targetId: party.id,
                      );

                      return Column(
                        children: <Widget>[
                          Padding(
                            padding: contentPadding,
                            child: Column(
                              children: <Widget>[
                                SizedBox(height: 6.h),
                                Row(
                                  children: <Widget>[
                                    SafeBackButton(
                                      fallbackRoute: AppRoutes.rooms,
                                    ),
                                    Expanded(
                                      child: Text(
                                        AppStrings.partyDetails,
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
                            child: LayoutBuilder(
                              builder:
                                  (
                                    BuildContext context,
                                    BoxConstraints constraints,
                                  ) {
                                  final Widget detailsChild = RepaintBoundary(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        contentPadding.left,
                                        12.h,
                                        contentPadding.right,
                                        0,
                                      ),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: <Widget>[
                                            PartyOverviewHeader(
                                              party: party,
                                              opacity: 1,
                                            ),
                                            SizedBox(height: 12.h),
                                            GlassContainer(
                                              borderRadius: 26.r,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 18.w,
                                                vertical: 14.h,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: <Widget>[
                                                      Text(
                                                        AppStrings
                                                            .partyInvitationCode,
                                                        style: AppTextStyles
                                                            .caption
                                                            .copyWith(
                                                          letterSpacing: 1.4,
                                                        ),
                                                      ),
                                                      SizedBox(height: 6.h),
                                                      Text(
                                                        party.partyCode,
                                                        style: AppTextStyles
                                                            .sectionTitle
                                                            .copyWith(
                                                          fontSize: 24.sp,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      Clipboard.setData(
                                                        ClipboardData(
                                                          text: party.partyCode,
                                                        ),
                                                      );
                                                      AppSnackBar.showSuccess(
                                                        context,
                                                        AppStrings
                                                            .partyCodeCopied,
                                                      );
                                                    },
                                                    icon: Icon(
                                                      Icons.copy,
                                                      size: 20.sp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 14.h),
                                            Text(
                                              '${AppStrings.players} (${party.playerCount}/${party.maxPlayers})',
                                              style:
                                                  AppTextStyles.pageTitle,
                                            ),
                                            SizedBox(height: 10.h),
                                            Builder(
                                              builder: (context) {
                                                final bool canKick = party
                                                        .players.isNotEmpty &&
                                                    party
                                                        .players.first.isHost;
                                                // TODO: Wire with current user ID once auth is integrated.
                                                return Column(
                                                  children: party.players
                                                      .map(
                                                        (player) => Padding(
                                                          padding:
                                                              EdgeInsets.only(
                                                            bottom: 10.h,
                                                          ),
                                                          child: PlayerTile(
                                                            player: player,
                                                            showKick: canKick,
                                                            onKick: () {
                                                              context
                                                                  .read<
                                                                    PartyBloc
                                                                  >()
                                                                  .add(
                                                                    PartyKickRequested(
                                                                      partyId:
                                                                          party
                                                                              .id,
                                                                      playerId:
                                                                          player
                                                                              .id,
                                                                    ),
                                                                  );
                                                            },
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                );
                                              },
                                            ),
                                            SizedBox(height: 12.h),
                                            PrimaryButton(
                                              label: AppStrings.leaveParty,
                                              icon: Icons.logout,
                                              isDanger: true,
                                              onPressed: () {
                                                context
                                                    .read<PartyBloc>()
                                                    .add(
                                                      PartyLeaveRequested(
                                                        partyId: party.id,
                                                      ),
                                                    );
                                              },
                                            ),
                                            SizedBox(height: 24.h),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );

                                      return Stack(
                                        children: <Widget>[
                                          ValueListenableBuilder<double>(
                                            valueListenable: _sheetSize,
                                            builder: (context, size, child) {
                                              final clamped =
                                                  size.clamp(0.1, 0.9);
                                              final detailHeight =
                                                  constraints.maxHeight *
                                                      (1 - clamped);

                                              return AnimatedPositioned(
                                                duration: const Duration(
                                                  milliseconds: 90,
                                                ),
                                                curve: Curves.easeOutCubic,
                                                top: 0,
                                                left: 0,
                                                right: 0,
                                                height: detailHeight,
                                                child: ClipRect(
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: detailsChild,
                                      ),
                                      Positioned.fill(
                                        child: RepaintBoundary(
                                          child: BlocProvider<ChatBloc>.value(
                                            value: _groupChatBloc!,
                                            child: PartyChatSheet(
                                              party: party,
                                              initialChildSize: 0.1,
                                              minChildSize: 0.1,
                                              maxChildSize: 0.9,
                                              controller: _chatController,
                                              onExpandTap: _expandChat,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
