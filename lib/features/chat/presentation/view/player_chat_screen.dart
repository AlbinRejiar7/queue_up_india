import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_options.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../../home/models/available_player_model.dart';
import '../../bloc/chat_bloc.dart';
import '../../bloc/chat_event.dart';
import '../../bloc/chat_state.dart';
import '../../viewmodel/chat_view_model.dart';
import '../widgets/chat_bubble.dart';

class PlayerChatScreen extends StatefulWidget {
  const PlayerChatScreen({required this.player, super.key});

  final AvailablePlayerModel player;

  @override
  State<PlayerChatScreen> createState() => _PlayerChatScreenState();
}

class _PlayerChatScreenState extends State<PlayerChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _stickToBottom = true;
  bool _showAllQuickMessages = false;

  static const List<String> _quickMessages = <String>[
    'Do you want to play a game with me?',
    'I am ready to queue now.',
    'Want to join my party?',
    'Which server are you on?',
    'Give me 5 minutes.',
    'Yes, let us play.',
    'No worries, maybe later.',
    'What rank are you pushing?',
    'Send your in-game ID.',
    'Share your party code.',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _sendQuickMessage(BuildContext context, String message) {
    context.read<ChatBloc>().add(ChatMessageSent(message: message));
  }

  Future<void> _promptAndSend({
    required BuildContext context,
    required String title,
    required String hint,
    required String Function(String) formatter,
  }) async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16.w,
              16.h,
              16.w,
              bottomInset + 16.h,
            ),
            child: GlassContainer(
              borderRadius: 24.r,
              padding: EdgeInsets.all(16.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: controller,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: AppTextStyles.caption,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Text(AppStrings.cancelAction),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final text = controller.text.trim();
                            if (text.isEmpty) {
                              AppSnackBar.showError(
                                context,
                                AppStrings.emptyQuickValue,
                              );
                              return;
                            }
                            Navigator.of(sheetContext).pop(text);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlueBright,
                            foregroundColor: AppColors.textPrimary,
                          ),
                          child: Text(AppStrings.sendAction),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null || result.trim().isEmpty) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    _sendQuickMessage(context, formatter(result.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight =
        MediaQuery.of(context).size.height - viewInsets;
    final quickHeightFactor = _showAllQuickMessages ? 0.35 : 0.22;
    final maxQuickHeight = max(
      80.h,
      min(
        _showAllQuickMessages ? 260.h : 150.h,
        availableHeight * quickHeightFactor,
      ),
    );
    final visibleQuickMessages = _showAllQuickMessages
        ? _quickMessages
        : _quickMessages.take(5).toList();

    return BlocProvider<ChatBloc>(
      create: (_) => ChatBloc(
        chatViewModel: sl<ChatViewModel>(),
        scope: ChatScope.direct,
        targetId: player.id,
      ),
      child: Scaffold(
        body: GlowBackground(
          child: SafeArea(
            child: ResponsiveLayoutBuilder(
              builder:
                  (
                    BuildContext context,
                    BoxConstraints constraints,
                    EdgeInsets contentPadding,
                  ) {
                    final gameName = AppOptions.gameNameById(player.gameId);

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
                                    fallbackRoute: AppRoutes.availablePlayers,
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${AppStrings.chatWith} ${player.name}',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.pageTitle,
                                    ),
                                  ),
                                  SizedBox(width: 48.w),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              GlassContainer(
                                borderRadius: 24.r,
                                padding: EdgeInsets.all(14.r),
                                child: Row(
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 22.r,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.08),
                                      backgroundImage:
                                          _avatarProvider(player.avatarUrl),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            gameName,
                                            style:
                                                AppTextStyles.bodyMedium.copyWith(
                                              color: Colors.white,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            '${player.rank} • ${player.language}',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              contentPadding.left,
                              12.h,
                              contentPadding.right,
                              contentPadding.bottom,
                            ),
                            child: Column(
                              children: <Widget>[
                                  Expanded(
                                    child: BlocListener<ChatBloc, ChatState>(
                                      listenWhen: (previous, current) =>
                                          previous.messages.length !=
                                          current.messages.length,
                                      listener: (context, state) {
                                        if (_stickToBottom &&
                                            !state.isLoadingMore) {
                                          _scrollToBottom();
                                        }
                                      },
                                      child: BlocBuilder<ChatBloc, ChatState>(
                                        builder: (context, state) {
                                          final messages = state.messages;
                                          final itemCount = messages.length +
                                              (state.isLoadingMore ? 1 : 0);

                                          return NotificationListener<
                                              ScrollNotification>(
                                            onNotification: (notification) {
                                              final metrics =
                                                  notification.metrics;
                                              final distanceToBottom =
                                                  metrics.maxScrollExtent -
                                                      metrics.pixels;
                                              _stickToBottom =
                                                  distanceToBottom <= 120.h;

                                              if (metrics.pixels <= 120.h) {
                                                context
                                                    .read<ChatBloc>()
                                                    .add(
                                                      const ChatLoadOlderRequested(),
                                                    );
                                              }
                                              return false;
                                            },
                                            child: ListView.builder(
                                              controller: _scrollController,
                                              itemCount: itemCount,
                                              itemBuilder:
                                                  (BuildContext context, int index) {
                                                if (state.isLoadingMore &&
                                                    index == 0) {
                                                  return Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom: 8.h,
                                                    ),
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  );
                                                }
                                                final messageIndex =
                                                    state.isLoadingMore
                                                        ? index - 1
                                                        : index;
                                                return ChatBubble(
                                                  message:
                                                      messages[messageIndex],
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                SizedBox(height: 10.h),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  verticalDirection: VerticalDirection.up,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              _promptAndSend(
                                                context: context,
                                                title: AppStrings.sharePlayerId,
                                                hint:
                                                    AppStrings.enterPlayerIdHint,
                                                formatter: (value) =>
                                                    AppStrings.playerIdMessage(
                                                      value,
                                                    ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.textPrimary,
                                              side: BorderSide(
                                                color: AppColors
                                                    .electricBlueBright,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14.r),
                                              ),
                                            ),
                                            child: Text(
                                              AppStrings.sharePlayerId,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              _promptAndSend(
                                                context: context,
                                                title: AppStrings.sharePartyCode,
                                                hint:
                                                    AppStrings.enterPartyCodeHint,
                                                formatter: (value) =>
                                                    AppStrings.partyCodeMessage(
                                                      value,
                                                    ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.electricBlueBright,
                                              foregroundColor:
                                                  AppColors.textPrimary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14.r),
                                              ),
                                            ),
                                            child: Text(
                                              AppStrings.sharePartyCode,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10.h),
                                    GlassContainer(
                                      borderRadius: 22.r,
                                      padding: EdgeInsets.all(14.r),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Text(
                                                AppStrings.quickMessagesTitle,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Spacer(),
                                              if (_quickMessages.length > 5)
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _showAllQuickMessages =
                                                          !_showAllQuickMessages;
                                                    });
                                                  },
                                                  child: Text(
                                                    _showAllQuickMessages
                                                        ? AppStrings.seeLess
                                                        : AppStrings.seeMore,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 8.h),
                                          AnimatedSize(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            curve: Curves.easeInOut,
                                            alignment: Alignment.bottomCenter,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxHeight: maxQuickHeight,
                                              ),
                                              child: SingleChildScrollView(
                                                child: Wrap(
                                                  spacing: 8.w,
                                                  runSpacing: 8.h,
                                                  children: visibleQuickMessages
                                                      .map(
                                                        (message) => ActionChip(
                                                          label: Text(
                                                            message,
                                                            style: AppTextStyles
                                                                .caption
                                                                .copyWith(
                                                              color: AppColors
                                                                  .textPrimary,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                            ),
                                                          ),
                                                          backgroundColor:
                                                              AppColors
                                                                  .electricBlue
                                                                  .withValues(
                                                                    alpha: 0.15,
                                                                  ),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              16.r,
                                                            ),
                                                            side: BorderSide(
                                                              color: AppColors
                                                                  .electricBlueBright
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                            ),
                                                          ),
                                                          onPressed: () {
                                                            _stickToBottom =
                                                                true;
                                                            _sendQuickMessage(
                                                              context,
                                                              message,
                                                            );
                                                          },
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
            ),
          ),
        ),
      ),
    );
  }
}

ImageProvider _avatarProvider(String url) {
  if (url.trim().isEmpty) {
    return const NetworkImage(AppImages.avatarHost);
  }
  if (url.startsWith('http')) {
    return NetworkImage(url);
  }
  return AssetImage(url);
}
