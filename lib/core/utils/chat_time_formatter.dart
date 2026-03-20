import 'package:flutter/material.dart';

String formatChatListTime(BuildContext context, DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(value.year, value.month, value.day);
  final difference = today.difference(targetDay).inDays;

  if (difference == 0) {
    return TimeOfDay.fromDateTime(value).format(context);
  }
  if (difference == 1) {
    return 'Yesterday';
  }
  if (now.year == value.year) {
    return '${value.day} ${_monthShort(value.month)}';
  }
  return '${value.day} ${_monthShort(value.month)} ${value.year}';
}

String _monthShort(int month) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
