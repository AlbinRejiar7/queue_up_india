import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import '../../../../core/widgets/app_dialog.dart';
import '../../../chat/bloc/chat_bloc.dart';
import '../../../chat/viewmodel/chat_view_model.dart';
import '../../bloc/party_bloc.dart';
import '../../bloc/party_event.dart';
import '../../bloc/party_state.dart';
import '../../models/party_model.dart';
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
  void didUpdateWidget(covariant PartyDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partyId == widget.partyId) {
      return;
    }
    _groupChatBloc?.close();
    _groupChatBloc = null;
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

  Future<void> _requestLeaveParty({
    required PartyModel party,
    required bool isHost,
  }) async {
    final blocState = context.read<PartyBloc>().state;
    if (blocState is PartyLoading) {
      return;
    }

    final message = isHost
        ? party.playerCount <= 1
              ? AppStrings.leavePartyHostDeleteConfirmMessage
              : AppStrings.leavePartyHostTransferConfirmMessage
        : AppStrings.leavePartyMemberConfirmMessage;

    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppStrings.leavePartyConfirmTitle,
      message: message,
      confirmLabel: AppStrings.leaveParty,
      cancelLabel: AppStrings.cancelAction,
      confirmIsDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    context.read<PartyBloc>().add(PartyLeaveRequested(partyId: party.id));
  }

  Future<void> _handleBackNavigation({
    required PartyModel party,
    required bool isHost,
  }) async {
    if (isHost) {
      if (!mounted) {
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.rooms);
      }
      return;
    }

    await _requestLeaveParty(party: party, isHost: false);
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
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;

                      if (party == null || party.id != widget.partyId) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final bool canAccessPartyChat =
                          currentUserId != null &&
                          party.players.any(
                            (player) => player.id == currentUserId,
                          );

                      if (canAccessPartyChat && _groupChatBloc == null) {
                        _groupChatBloc = ChatBloc(
                          chatViewModel: sl<ChatViewModel>(),
                          scope: ChatScope.party,
                          targetId: party.id,
                          targetLabel: party.name,
                        );
                      } else if (!canAccessPartyChat &&
                          _groupChatBloc != null) {
                        _groupChatBloc?.close();
                        _groupChatBloc = null;
                      }

                      final bool isHost =
                          currentUserId != null &&
                          currentUserId == party.hostId;

                      return PopScope<Object?>(
                        canPop: false,
                        onPopInvokedWithResult:
                            (bool didPop, Object? result) async {
                              if (didPop) {
                                return;
                              }
                              await _handleBackNavigation(
                                party: party,
                                isHost: isHost,
                              );
                            },
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: contentPadding,
                              child: Column(
                                children: <Widget>[
                                  SizedBox(height: 6.h),
                                  Row(
                                    children: <Widget>[
                                      IconButton(
                                        onPressed: () {
                                          _handleBackNavigation(
                                            party: party,
                                            isHost: isHost,
                                          );
                                        },
                                        icon: const Icon(Icons.arrow_back),
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
                                builder: (BuildContext context, BoxConstraints constraints) {
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
                                                              letterSpacing:
                                                                  1.4,
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
                                              style: AppTextStyles.pageTitle,
                                            ),
                                            SizedBox(height: 10.h),
                                            Builder(
                                              builder: (context) {
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
                                                            showKick:
                                                                isHost &&
                                                                player.id !=
                                                                    currentUserId,
                                                            onKick:
                                                                isHost &&
                                                                    player.id !=
                                                                        currentUserId
                                                                ? () {
                                                                    context.read<PartyBloc>().add(
                                                                      PartyKickRequested(
                                                                        partyId:
                                                                            party.id,
                                                                        playerId:
                                                                            player.id,
                                                                      ),
                                                                    );
                                                                  }
                                                                : null,
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
                                                _requestLeaveParty(
                                                  party: party,
                                                  isHost: isHost,
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
                                          final clamped = canAccessPartyChat
                                              ? size.clamp(0.1, 0.9)
                                              : 0.0;
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
                                            child: ClipRect(child: child),
                                          );
                                        },
                                        child: detailsChild,
                                      ),
                                      if (canAccessPartyChat &&
                                          _groupChatBloc != null)
                                        Positioned.fill(
                                          child: RepaintBoundary(
                                            child: BlocProvider<ChatBloc>.value(
                                              value: _groupChatBloc!,
                                              child: PartyChatSheet(
                                                key: ValueKey<String>(
                                                  'party-chat-${party.id}',
                                                ),
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
