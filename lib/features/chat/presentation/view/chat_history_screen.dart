import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_options.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../../home/models/available_player_model.dart';
import '../../bloc/chat_history_bloc.dart';
import '../../bloc/chat_history_event.dart';
import '../../bloc/chat_history_state.dart';
import '../../models/chat_thread.dart';
import '../../viewmodel/chat_view_model.dart';
import '../widgets/chat_history_tile.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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
      context.read<ChatHistoryBloc>().add(const ChatHistoryLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatHistoryBloc>(
      create: (_) => ChatHistoryBloc(chatViewModel: sl<ChatViewModel>()),
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
                    return BlocBuilder<ChatHistoryBloc, ChatHistoryState>(
                      builder: (BuildContext context, ChatHistoryState state) {
                        final threads = state.threads;

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
                                        fallbackRoute:
                                            AppRoutes.availablePlayers,
                                      ),
                                      Expanded(
                                        child: Text(
                                          AppStrings.chats,
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.pageTitle,
                                        ),
                                      ),
                                      SizedBox(width: 48.w),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    AppStrings.chatHistorySubtitle,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: state.isLoading && threads.isEmpty
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : threads.isEmpty
                                      ? Center(
                                          child: Text(
                                            AppStrings.noChatsYet,
                                            style: AppTextStyles.bodyMedium,
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : ListView.separated(
                                          controller: _scrollController,
                                          padding: EdgeInsets.fromLTRB(
                                            contentPadding.left,
                                            16.h,
                                            contentPadding.right,
                                            20.h,
                                          ),
                                          itemCount: threads.length +
                                              (state.isLoadingMore ? 1 : 0),
                                          separatorBuilder: (_, __) =>
                                              SizedBox(height: 10.h),
                                          itemBuilder:
                                              (BuildContext context, int index) {
                                            if (index >= threads.length) {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 8.h,
                                                ),
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }
                                            final thread = threads[index];
                                            final subtitle =
                                                thread.lastMessage.trim().isEmpty
                                                    ? AppStrings.chatTapToOpen
                                                    : thread.lastMessage;
                                            return ChatHistoryTile(
                                              thread: thread,
                                              subtitle: subtitle,
                                              onTap: () {
                                                context.push(
                                                  AppRoutes.playerChatPath(
                                                    thread.peerId,
                                                  ),
                                                  extra: _toPlayer(thread),
                                                );
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
      ),
    );
  }
}

AvailablePlayerModel _toPlayer(ChatThread thread) {
  return AvailablePlayerModel(
    id: thread.peerId,
    name: thread.peerName,
    avatarUrl: thread.peerAvatarUrl,
    gameId: AppOptions.valorantId,
    rank: AppOptions.valorantRankOptions.first.name,
    language: AppOptions.languageOptions.first,
    availableSince: DateTime.now(),
  );
}
