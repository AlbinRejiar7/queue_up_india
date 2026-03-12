import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
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
          Text(message.senderName, style: AppTextStyles.caption),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            constraints: BoxConstraints(maxWidth: 260.w),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Text(
              message.message,
              style: AppTextStyles.bodyMedium.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
