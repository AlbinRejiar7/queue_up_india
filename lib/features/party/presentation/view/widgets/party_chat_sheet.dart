import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/glass_container.dart';
import '../../../../chat/bloc/chat_bloc.dart';
import '../../../../chat/bloc/chat_event.dart';
import '../../../../chat/bloc/chat_state.dart';
import '../../../../chat/presentation/widgets/chat_bubble.dart';
import '../../../../chat/presentation/widgets/chat_input_bar.dart';
import '../../../models/party_model.dart';

class PartyChatSheet extends StatelessWidget {
  const PartyChatSheet({
    required this.party,
    super.key,
    this.initialChildSize = 0.1,
    this.minChildSize = 0.1,
    this.maxChildSize = 0.9,
    this.controller,
    this.onExpandTap,
  });

  final PartyModel party;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final DraggableScrollableController? controller;
  final VoidCallback? onExpandTap;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      snap: true,
      snapSizes: <double>[minChildSize, maxChildSize],
      builder: (BuildContext context, ScrollController scrollController) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isCompact = constraints.maxHeight < 200.h;
            final EdgeInsets contentPadding = isCompact
                ? EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 10.h)
                : EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h);

            return GlassContainer(
              borderRadius: 32.r,
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.navSurface.withValues(alpha: 0.92),
              blurSigma: 6,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: BlocListener<ChatBloc, ChatState>(
                      listenWhen: (previous, current) =>
                          previous.messages.length !=
                          current.messages.length,
                      listener: (context, state) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!scrollController.hasClients) {
                            return;
                          }
                          scrollController.animateTo(
                            scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                          );
                        });
                      },
                      child: ListView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: contentPadding.copyWith(
                          bottom: isCompact ? contentPadding.bottom : 86.h,
                        ),
                        children: <Widget>[
                          GestureDetector(
                            onTap: onExpandTap,
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              children: <Widget>[
                                Container(
                                  width: 44.w,
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(999.r),
                                  ),
                                ),
                                SizedBox(height: 6.h),
                              if (isCompact) ...<Widget>[
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 6.w),
                                  child: BlocBuilder<ChatBloc, ChatState>(
                                    builder: (context, state) {
                                      final lastMessage = state.messages.isEmpty
                                          ? null
                                          : state.messages.last;
                                      final bool showUnreadDot =
                                          isCompact &&
                                          lastMessage != null &&
                                          !lastMessage.isMe;
                                      final previewText = lastMessage == null
                                          ? AppStrings.chatTapToOpen
                                          : '${lastMessage.senderName}: ${lastMessage.message}';

                                      return Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Row(
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: Text(
                                                        AppStrings.groupChat,
                                                        style: AppTextStyles
                                                            .sectionTitle
                                                            .copyWith(
                                                          fontSize: 18.sp,
                                                        ),
                                                      ),
                                                    ),
                                                    Stack(
                                                      clipBehavior: Clip.none,
                                                      children: <Widget>[
                                                        Icon(
                                                          Icons.chat,
                                                          color: AppColors
                                                              .textSecondary,
                                                          size: 18.sp,
                                                        ),
                                                        if (showUnreadDot)
                                                          Positioned(
                                                            right: -1.w,
                                                            top: -3.h,
                                                            child: Container(
                                                              width: 8.w,
                                                              height: 8.w,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: AppColors
                                                                    .danger,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  previewText,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextStyles.caption,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ] else ...<Widget>[
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        AppStrings.groupChat,
                                        style: AppTextStyles.sectionTitle
                                            .copyWith(fontSize: 18.sp),
                                      ),
                                      Text(
                                        '${party.playerCount} ${AppStrings.online}',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!isCompact) ...<Widget>[
                            SizedBox(height: 12.h),
                          BlocBuilder<ChatBloc, ChatState>(
                            builder: (context, state) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: state.messages
                                    .map(
                                      (message) =>
                                          ChatBubble(message: message),
                                    )
                                      .toList(),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (!isCompact)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          contentPadding.left,
                          10.h,
                          contentPadding.right,
                          contentPadding.bottom,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.navSurface,
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                            child: ChatInputBar(
                              hintText: AppStrings.chatPlaceholder,
                              emptyMessage: AppStrings.chatEmptyMessage,
                              onSend: (text) {
                                context.read<ChatBloc>().add(
                                      ChatMessageSent(message: text),
                                    );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
