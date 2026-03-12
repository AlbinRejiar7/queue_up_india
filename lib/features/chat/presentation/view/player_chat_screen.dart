import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_options.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../../home/models/available_player_model.dart';
import '../../bloc/chat_bloc.dart';
import '../../bloc/chat_event.dart';
import '../../bloc/chat_state.dart';
import '../../models/chat_message.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';

class PlayerChatScreen extends StatefulWidget {
  const PlayerChatScreen({required this.player, super.key});

  final AvailablePlayerModel player;

  @override
  State<PlayerChatScreen> createState() => _PlayerChatScreenState();
}

class _PlayerChatScreenState extends State<PlayerChatScreen> {
  final ScrollController _scrollController = ScrollController();

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

  @override
  Widget build(BuildContext context) {
    final player = widget.player;

    return BlocProvider<ChatBloc>(
      create: (_) => ChatBloc(
        currentUserName: AppStrings.chatYou,
        replyName: player.name,
        dummyReply: AppStrings.chatDummyReply,
        initialMessages: <ChatMessage>[
          ChatMessage(
            id: 'direct-1',
            senderName: player.name,
            message: AppStrings.directChatGreeting,
            isMe: false,
            timestamp: DateTime.now(),
          ),
          ChatMessage(
            id: 'direct-2',
            senderName: AppStrings.chatYou,
            message: AppStrings.directChatResponse,
            isMe: true,
            timestamp: DateTime.now(),
          ),
        ],
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
                                      child: Text(
                                        player.name
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(fontSize: 16.sp),
                                      ),
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
                                      _scrollToBottom();
                                    },
                                    child: BlocBuilder<ChatBloc, ChatState>(
                                      builder: (context, state) {
                                        return ListView(
                                          controller: _scrollController,
                                          children: state.messages
                                              .map(
                                                (message) => ChatBubble(
                                                  message: message,
                                                ),
                                              )
                                              .toList(),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                ChatInputBar(
                                  hintText: AppStrings.chatPlaceholder,
                                  emptyMessage: AppStrings.chatEmptyMessage,
                                  onSend: (text) {
                                    context.read<ChatBloc>().add(
                                          ChatMessageSent(message: text),
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
            ),
          ),
        ),
      ),
    );
  }
}
