import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_options.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/utils/app_preferences.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../../home/models/available_player_model.dart';
import '../../../home/viewmodel/available_players_view_model.dart';
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
  bool _isBlocked = false;
  bool _isBlocking = false;
  bool _isReporting = false;
  late AvailablePlayerModel _player;
  List<String> _customQuickMessages = <String>[];
  DateTime? _lastQuickMessageAt;
  final Map<String, DateTime> _quickMessageHistory = <String, DateTime>{};

  static const int _maxCustomQuickMessages = 5;
  static const Duration _quickMessageCooldown = Duration(seconds: 3);
  static const Duration _quickMessageDuplicateCooldown = Duration(seconds: 15);

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
  void initState() {
    super.initState();
    _player = widget.player;
    PushNotificationService.instance.setActiveDirectChatId(_player.id);
    _syncAvailability();
    _loadCustomQuickMessages();
    _loadBlockStatus();
  }

  @override
  void dispose() {
    PushNotificationService.instance.setActiveDirectChatId(null);
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
    if (_isBlocked) {
      AppSnackBar.showInfo(context, AppStrings.blockedChatDisabled);
      return;
    }
    final now = DateTime.now();
    if (_lastQuickMessageAt != null &&
        now.difference(_lastQuickMessageAt!) < _quickMessageCooldown) {
      AppSnackBar.showInfo(context, AppStrings.quickMessageCooldown);
      return;
    }
    final lastForMessage = _quickMessageHistory[message];
    if (lastForMessage != null &&
        now.difference(lastForMessage) < _quickMessageDuplicateCooldown) {
      AppSnackBar.showInfo(context, AppStrings.quickMessageDuplicateCooldown);
      return;
    }
    _lastQuickMessageAt = now;
    _quickMessageHistory[message] = now;
    context.read<ChatBloc>().add(ChatMessageSent(message: message));
  }

  Future<void> _loadCustomQuickMessages() async {
    final messages = await AppPreferences.loadCustomQuickMessages();
    if (!mounted) {
      return;
    }
    setState(() {
      _customQuickMessages = messages;
    });
  }

  Future<void> _loadBlockStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('private')
          .doc('blocks')
          .get();
      final data = doc.data();
      if (data == null) {
        return;
      }
      final blocked =
          (data['blockedUserIds'] as List?)?.cast<String>() ?? <String>[];
      if (!mounted) {
        return;
      }
      if (blocked.contains(_player.id)) {
        setState(() {
          _isBlocked = true;
        });
      }
    } catch (_) {
      // Ignore block fetch failures.
    }
  }

  Future<void> _blockPlayer() async {
    if (_isBlocking) {
      return;
    }
    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppStrings.blockPlayerConfirmTitle,
      message: AppStrings.blockPlayerConfirmMessage,
      confirmLabel: AppStrings.blockPlayerConfirmAction,
      cancelLabel: AppStrings.cancelAction,
      confirmIsDestructive: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      AppSnackBar.showError(context, AppStrings.authFailed);
      return;
    }
    setState(() {
      _isBlocking = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('private')
          .doc('blocks')
          .set(
        <String, dynamic>{
          'blockedUserIds': FieldValue.arrayUnion(<String>[_player.id]),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isBlocked = true;
        _isBlocking = false;
      });
      AppSnackBar.showSuccess(context, AppStrings.playerBlockedToast);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBlocking = false;
      });
      AppSnackBar.showError(context, AppStrings.requestActionFailed);
    }
  }

  Future<void> _unblockPlayer() async {
    if (_isBlocking) {
      return;
    }
    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppStrings.unblockPlayerConfirmTitle,
      message: AppStrings.unblockPlayerConfirmMessage,
      confirmLabel: AppStrings.unblockPlayerConfirmAction,
      cancelLabel: AppStrings.cancelAction,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      AppSnackBar.showError(context, AppStrings.authFailed);
      return;
    }
    setState(() {
      _isBlocking = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('private')
          .doc('blocks')
          .set(
        <String, dynamic>{
          'blockedUserIds': FieldValue.arrayRemove(<String>[_player.id]),
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isBlocked = false;
        _isBlocking = false;
      });
      AppSnackBar.showSuccess(context, AppStrings.playerUnblockedToast);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBlocking = false;
      });
      AppSnackBar.showError(context, AppStrings.requestActionFailed);
    }
  }

  Future<void> _reportPlayer(String reason) async {
    if (_isReporting) {
      return;
    }
    if (reason.trim().isEmpty) {
      AppSnackBar.showError(context, AppStrings.reportReasonRequired);
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      AppSnackBar.showError(context, AppStrings.authFailed);
      return;
    }
    setState(() {
      _isReporting = true;
    });
    try {
      final report = <String, dynamic>{
        'reporterId': uid,
        'playerId': _player.id,
        'playerName': _player.name,
        'gameId': _player.gameId,
        'rank': _player.rank,
        'language': _player.language,
        'reason': reason.trim(),
        'status': 'open',
        'reportedAt': DateTime.now().toUtc().toIso8601String(),
      };
      await FirebaseFirestore.instance.collection('reports').add(report);
      if (!mounted) {
        return;
      }
      setState(() {
        _isReporting = false;
      });
      AppSnackBar.showSuccess(context, AppStrings.playerReportedToast);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isReporting = false;
      });
      AppSnackBar.showError(context, AppStrings.requestActionFailed);
    }
  }

  void _handleChatAction(_ChatAction action) {
    switch (action) {
      case _ChatAction.block:
        _blockPlayer();
      case _ChatAction.unblock:
        _unblockPlayer();
      case _ChatAction.report:
        _promptReportReason();
    }
  }

  Future<void> _promptReportReason() async {
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
                    AppStrings.reportReasonTitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: AppStrings.reportReasonHint,
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
                                AppStrings.reportReasonRequired,
                              );
                              return;
                            }
                            Navigator.of(sheetContext).pop(text);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlueBright,
                            foregroundColor: AppColors.textPrimary,
                          ),
                          child: Text(AppStrings.reportPlayerConfirmAction),
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

    if (result == null || result.trim().isEmpty || !mounted) {
      return;
    }
    await _reportPlayer(result);
  }

  Future<void> _addCustomQuickMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      AppSnackBar.showError(context, AppStrings.emptyQuickValue);
      return;
    }
    final existsInCustom = _customQuickMessages.any(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );
    final existsInDefaults = _quickMessages.any(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );
    if (existsInCustom || existsInDefaults) {
      AppSnackBar.showInfo(context, AppStrings.quickMessageExists);
      return;
    }
    if (_customQuickMessages.length >= _maxCustomQuickMessages) {
      AppSnackBar.showInfo(context, AppStrings.quickMessageLimit);
      return;
    }
    final updated = <String>[trimmed, ..._customQuickMessages];
    await AppPreferences.saveCustomQuickMessages(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      _customQuickMessages = updated;
    });
    AppSnackBar.showSuccess(context, AppStrings.quickMessageAdded);
  }

  Future<void> _promptAddQuickMessage() async {
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
                    AppStrings.addQuickMessage,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: controller,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: AppStrings.addQuickMessageHint,
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
                          child: Text(AppStrings.addAction),
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
    await _addCustomQuickMessage(result);
  }

  Future<void> _syncAvailability() async {
    try {
      final updated = await sl<AvailablePlayersViewModel>()
          .fetchAvailablePlayer(_player.id);
      if (!mounted || updated == null) {
        return;
      }
      setState(() {
        _player = _player.copyWith(
          name: updated.name.isNotEmpty ? updated.name : _player.name,
          avatarUrl: updated.avatarUrl.isNotEmpty
              ? updated.avatarUrl
              : _player.avatarUrl,
          gameId: updated.gameId.isNotEmpty ? updated.gameId : _player.gameId,
          rank: updated.rank.isNotEmpty ? updated.rank : _player.rank,
          language:
              updated.language.isNotEmpty ? updated.language : _player.language,
          availableSince: updated.availableSince,
        );
      });
    } catch (_) {
      // Ignore availability refresh failures; keep the initial details.
    }
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
    final player = _player;
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
    final maxBottomSectionHeight =
        min(availableHeight * 0.45, 340.h);
    final allQuickMessages = <String>[
      ..._customQuickMessages,
      ..._quickMessages,
    ];
    final visibleQuickMessages = _showAllQuickMessages
        ? allQuickMessages
        : allQuickMessages.take(5).toList();

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
                                    SizedBox(
                                      width: 48.w,
                                      child: PopupMenuButton<_ChatAction>(
                                        tooltip: '',
                                        onSelected: _handleChatAction,
                                        itemBuilder: (context) =>
                                            <PopupMenuEntry<_ChatAction>>[
                                          PopupMenuItem<_ChatAction>(
                                            value: _isBlocked
                                                ? _ChatAction.unblock
                                                : _ChatAction.block,
                                            child: Row(
                                              children: <Widget>[
                                                Icon(
                                                  _isBlocked
                                                      ? Icons.lock_open_rounded
                                                      : Icons.block,
                                                  size: 18.sp,
                                                  color: _isBlocked
                                                      ? AppColors.success
                                                      : AppColors.danger,
                                                ),
                                                SizedBox(width: 8.w),
                                                Text(
                                                  _isBlocked
                                                      ? AppStrings.unblockPlayer
                                                      : AppStrings.blockPlayer,
                                                  style:
                                                      AppTextStyles.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<_ChatAction>(
                                            value: _ChatAction.report,
                                            child: Row(
                                              children: <Widget>[
                                                Icon(
                                                  Icons.flag_outlined,
                                                  size: 18.sp,
                                                  color: AppColors.textPrimary,
                                                ),
                                                SizedBox(width: 8.w),
                                                Text(
                                                  AppStrings.reportPlayer,
                                                  style:
                                                      AppTextStyles.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        icon: Icon(
                                          Icons.more_vert,
                                          size: 22.sp,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
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
                              if (_isBlocked)
                                Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: Text(
                                    AppStrings.blockedPlayerNotice,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: maxBottomSectionHeight,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              if (_isBlocked) {
                                                AppSnackBar.showInfo(
                                                  context,
                                                  AppStrings.blockedChatDisabled,
                                                );
                                                return;
                                              }
                                              _promptAndSend(
                                                context: context,
                                                title: AppStrings.sharePlayerId,
                                                hint: AppStrings
                                                    .enterPlayerIdHint,
                                                    formatter: (value) =>
                                                        AppStrings
                                                            .playerIdMessage(
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
                                                        BorderRadius.circular(
                                                      14.r,
                                                    ),
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
                                              if (_isBlocked) {
                                                AppSnackBar.showInfo(
                                                  context,
                                                  AppStrings.blockedChatDisabled,
                                                );
                                                return;
                                              }
                                              _promptAndSend(
                                                context: context,
                                                title: AppStrings
                                                    .sharePartyCode,
                                                hint: AppStrings
                                                        .enterPartyCodeHint,
                                                    formatter: (value) =>
                                                        AppStrings
                                                            .partyCodeMessage(
                                                      value,
                                                    ),
                                                  );
                                                },
                                                style:
                                                    ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors
                                                      .electricBlueBright,
                                                  foregroundColor:
                                                      AppColors.textPrimary,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      14.r,
                                                    ),
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
                                                    AppStrings
                                                        .quickMessagesTitle,
                                                    style: AppTextStyles
                                                        .bodyMedium
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  TextButton(
                                                    onPressed:
                                                        _customQuickMessages
                                                                    .length >=
                                                                _maxCustomQuickMessages
                                                            ? null
                                                            : _promptAddQuickMessage,
                                                    child: Text(
                                                      AppStrings.addAction,
                                                    ),
                                                  ),
                                                  if (allQuickMessages.length >
                                                      5)
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
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxHeight: maxQuickHeight,
                                                  ),
                                                  child: SingleChildScrollView(
                                                    child: Wrap(
                                                      spacing: 8.w,
                                                      runSpacing: 8.h,
                                                      children:
                                                          visibleQuickMessages
                                                              .map(
                                                        (message) =>
                                                            ActionChip(
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
                                                            if (_isBlocked) {
                                                              AppSnackBar
                                                                  .showInfo(
                                                                context,
                                                                AppStrings
                                                                    .blockedChatDisabled,
                                                              );
                                                              return;
                                                            }
                                                            _stickToBottom =
                                                                true;
                                                            _sendQuickMessage(
                                                              context,
                                                              message,
                                                            );
                                                          },
                                                        ),
                                                      ).toList(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

enum _ChatAction { block, unblock, report }

ImageProvider _avatarProvider(String url) {
  if (url.trim().isEmpty) {
    return const NetworkImage(AppImages.avatarHost);
  }
  if (url.startsWith('http')) {
    return NetworkImage(url);
  }
  return AssetImage(url);
}
