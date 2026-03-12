import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    required this.hintText,
    required this.emptyMessage,
    required this.onSend,
    super.key,
  });

  final String hintText;
  final String emptyMessage;
  final ValueChanged<String> onSend;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      AppSnackBar.showInfo(context, widget.emptyMessage);
      return;
    }
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: widget.hintText),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _handleSend(),
          ),
        ),
        SizedBox(width: 10.w),
        SizedBox(
          height: 44.h,
          width: 44.h,
          child: ElevatedButton(
            onPressed: _handleSend,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              backgroundColor: AppColors.electricBlue,
            ),
            child: Icon(
              Icons.send_rounded,
              size: 18.sp,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
