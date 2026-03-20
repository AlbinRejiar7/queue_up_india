import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/chat_time_formatter.dart';
import '../../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final align =
        message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.isMe
        ? AppColors.electricBlue.withValues(alpha: 0.18)
        : AppColors.surface.withValues(alpha: 0.8);
    final textColor =
        message.isMe ? AppColors.textPrimary : AppColors.textSecondary;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: align,
        children: <Widget>[
          Text(
            message.senderName,
            textAlign: message.isMe ? TextAlign.right : TextAlign.left,
            style: AppTextStyles.caption,
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            constraints: BoxConstraints(maxWidth: 260.w),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              crossAxisAlignment: align,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  message.message,
                  textAlign: message.isMe ? TextAlign.right : TextAlign.left,
                  style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                ),
                SizedBox(height: 6.h),
                Text(
                  formatChatListTime(context, message.timestamp),
                  textAlign: message.isMe ? TextAlign.right : TextAlign.left,
                  style: AppTextStyles.caption.copyWith(
                    color: textColor.withValues(alpha: 0.72),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
