import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/constants/app_options.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/block_list_helper.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_container.dart';
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

  Future<void> _handleRefresh() async {
    final bloc = context.read<ChatHistoryBloc>();
    bloc.add(const ChatHistoryRefreshRequested());
    await bloc.stream.firstWhere((state) => state.isLoading);
    await bloc.stream.firstWhere((state) => !state.isLoading);
  }

  Future<void> _showBlockedPlayersDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const _BlockedPlayersDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatHistoryBloc>(
      create: (_) => ChatHistoryBloc(chatViewModel: sl<ChatViewModel>()),
      child: Scaffold(
        body: GlowBackground(
          child: SafeArea(
            child: ResponsiveLayoutBuilder(
              tabletMaxWidth: 960,
              tabletHorizontalPadding: 32,
              builder:
                  (
                    BuildContext context,
                    BoxConstraints constraints,
                    EdgeInsets contentPadding,
                  ) {
                    return BlocBuilder<ChatHistoryBloc, ChatHistoryState>(
                      builder: (BuildContext context, ChatHistoryState state) {
                        final threads = state.threads;
                        final bool isTablet = constraints.maxWidth >= 600;

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
                                      PopupMenuButton<_ChatHistoryMenuAction>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: AppColors.textPrimary,
                                          size: 22.r,
                                        ),
                                        onSelected: (action) {
                                          switch (action) {
                                            case _ChatHistoryMenuAction
                                                .blockedPlayers:
                                              _showBlockedPlayersDialog(
                                                context,
                                              );
                                          }
                                        },
                                        itemBuilder: (context) =>
                                            <
                                              PopupMenuEntry<
                                                _ChatHistoryMenuAction
                                              >
                                            >[
                                              PopupMenuItem<
                                                _ChatHistoryMenuAction
                                              >(
                                                value: _ChatHistoryMenuAction
                                                    .blockedPlayers,
                                                child: Row(
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons.block,
                                                      color: AppColors.danger,
                                                      size: 18.r,
                                                    ),
                                                    SizedBox(width: 10.w),
                                                    Text(
                                                      AppStrings
                                                          .blockedPlayersTitle,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                      ),
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
                              child: RefreshIndicator(
                                onRefresh: _handleRefresh,
                                child: state.isLoading && threads.isEmpty
                                    ? ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: EdgeInsets.fromLTRB(
                                          contentPadding.left,
                                          120.h,
                                          contentPadding.right,
                                          20.h,
                                        ),
                                        children: const <Widget>[
                                          Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ],
                                      )
                                    : threads.isEmpty
                                    ? ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: EdgeInsets.fromLTRB(
                                          contentPadding.left,
                                          120.h,
                                          contentPadding.right,
                                          20.h,
                                        ),
                                        children: <Widget>[
                                          Center(
                                            child: Text(
                                              AppStrings.noChatsYet,
                                              style: AppTextStyles.bodyMedium,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      )
                                    : (isTablet
                                          ? GridView.builder(
                                              controller: _scrollController,
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              padding: EdgeInsets.fromLTRB(
                                                contentPadding.left,
                                                16.h,
                                                contentPadding.right,
                                                20.h,
                                              ),
                                              itemCount:
                                                  threads.length +
                                                  (state.isLoadingMore ? 1 : 0),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2,
                                                    mainAxisExtent: 96.h,
                                                    mainAxisSpacing: 10.h,
                                                    crossAxisSpacing: 12.w,
                                                  ),
                                              itemBuilder:
                                                  (
                                                    BuildContext context,
                                                    int index,
                                                  ) {
                                                    if (index >=
                                                        threads.length) {
                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      );
                                                    }
                                                    final thread =
                                                        threads[index];
                                                    final subtitle =
                                                        thread.lastMessage
                                                            .trim()
                                                            .isEmpty
                                                        ? AppStrings
                                                              .chatTapToOpen
                                                        : thread.lastMessage;
                                                    return ChatHistoryTile(
                                                      thread: thread,
                                                      subtitle: subtitle,
                                                      onTap: () {
                                                        context.push(
                                                          AppRoutes.playerChatPath(
                                                            thread.peerId,
                                                          ),
                                                          extra: _toPlayer(
                                                            thread,
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                            )
                                          : ListView.separated(
                                              controller: _scrollController,
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(),
                                              padding: EdgeInsets.fromLTRB(
                                                contentPadding.left,
                                                16.h,
                                                contentPadding.right,
                                                20.h,
                                              ),
                                              itemCount:
                                                  threads.length +
                                                  (state.isLoadingMore ? 1 : 0),
                                              separatorBuilder: (_, _) =>
                                                  SizedBox(height: 10.h),
                                              itemBuilder:
                                                  (
                                                    BuildContext context,
                                                    int index,
                                                  ) {
                                                    if (index >=
                                                        threads.length) {
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              vertical: 8.h,
                                                            ),
                                                        child: const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    }
                                                    final thread =
                                                        threads[index];
                                                    final subtitle =
                                                        thread.lastMessage
                                                            .trim()
                                                            .isEmpty
                                                        ? AppStrings
                                                              .chatTapToOpen
                                                        : thread.lastMessage;
                                                    return ChatHistoryTile(
                                                      thread: thread,
                                                      subtitle: subtitle,
                                                      onTap: () {
                                                        context.push(
                                                          AppRoutes.playerChatPath(
                                                            thread.peerId,
                                                          ),
                                                          extra: _toPlayer(
                                                            thread,
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                            )),
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
    updatedAt: DateTime.now(),
  );
}

enum _ChatHistoryMenuAction { blockedPlayers }

class _BlockedPlayersDialog extends StatefulWidget {
  const _BlockedPlayersDialog();

  @override
  State<_BlockedPlayersDialog> createState() => _BlockedPlayersDialogState();
}

class _BlockedPlayersDialogState extends State<_BlockedPlayersDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _pendingUnblockIds = <String>{};

  Future<List<_BlockedPlayerProfile>> _loadProfiles(List<String> ids) async {
    final snapshots = await Future.wait(
      ids.map((id) => _firestore.collection('users').doc(id).get()),
    );

    final profiles = snapshots.map(_BlockedPlayerProfile.fromSnapshot).toList()
      ..sort(
        (first, second) =>
            first.name.toLowerCase().compareTo(second.name.toLowerCase()),
      );
    return profiles;
  }

  Future<void> _unblockPlayer(_BlockedPlayerProfile profile) async {
    if (_pendingUnblockIds.contains(profile.id)) {
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

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      AppSnackBar.showError(context, AppStrings.authFailed);
      return;
    }

    setState(() {
      _pendingUnblockIds.add(profile.id);
    });

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('private')
          .doc('blocks')
          .set(<String, dynamic>{
            'blockedUserIds': FieldValue.arrayRemove(<String>[profile.id]),
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          }, SetOptions(merge: true));
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(context, AppStrings.playerUnblockedToast);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, AppStrings.requestActionFailed);
    } finally {
      if (mounted) {
        setState(() {
          _pendingUnblockIds.remove(profile.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    final blockedUsersStream = uid == null
        ? Stream<Set<String>>.value(<String>{})
        : BlockListHelper.watchBlockedUserIds(firestore: _firestore, uid: uid);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GlassContainer(
        borderRadius: 28.r,
        padding: EdgeInsets.all(20.r),
        backgroundColor: AppColors.navSurface.withValues(alpha: 0.96),
        child: StreamBuilder<Set<String>>(
          stream: blockedUsersStream,
          builder: (context, blockedSnapshot) {
            final blockedIds = (blockedSnapshot.data ?? <String>{}).toList()
              ..sort();
            _pendingUnblockIds.removeWhere((id) => !blockedIds.contains(id));

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.block, color: AppColors.danger, size: 18.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        AppStrings.blockedPlayersTitle,
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 22.sp,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  AppStrings.blockedPlayersSubtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 16.h),
                if (blockedSnapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (blockedIds.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Center(
                      child: Text(
                        AppStrings.noBlockedPlayers,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  )
                else
                  FutureBuilder<List<_BlockedPlayerProfile>>(
                    future: _loadProfiles(blockedIds),
                    builder: (context, profileSnapshot) {
                      if (profileSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final profiles =
                          profileSnapshot.data ??
                          const <_BlockedPlayerProfile>[];

                      return ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 320.h),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: profiles.length,
                          separatorBuilder: (_, _) => SizedBox(height: 10.h),
                          itemBuilder: (context, index) =>
                              _buildBlockedPlayerRow(profiles[index]),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBlockedPlayerRow(_BlockedPlayerProfile profile) {
    final isPending = _pendingUnblockIds.contains(profile.id);

    return GlassContainer(
      borderRadius: 20.r,
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22.r,
            backgroundColor: AppColors.navSurface,
            backgroundImage: _avatarProvider(profile.avatarUrl),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  profile.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  profile.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          OutlinedButton(
            onPressed: isPending ? null : () => _unblockPlayer(profile),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(
                color: isPending
                    ? AppColors.textSecondary.withValues(alpha: 0.24)
                    : AppColors.electricBlueBright,
              ),
              minimumSize: Size(0, 40.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 0),
            ),
            child: isPending
                ? SizedBox(
                    width: 16.r,
                    height: 16.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.electricBlueBright,
                      ),
                    ),
                  )
                : Text(AppStrings.unblockPlayer),
          ),
        ],
      ),
    );
  }
}

class _BlockedPlayerProfile {
  const _BlockedPlayerProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String avatarUrl;

  factory _BlockedPlayerProfile.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    final name = ((data['displayName'] as String?) ?? '').trim();
    final avatarUrl = ((data['avatarUrl'] as String?) ?? '').trim();
    return _BlockedPlayerProfile(
      id: snapshot.id,
      name: name.isEmpty ? 'Player' : name,
      avatarUrl: avatarUrl.isEmpty ? AppImages.avatarHost : avatarUrl,
    );
  }
}

ImageProvider _avatarProvider(String url) {
  if (url.trim().isEmpty) {
    return const AssetImage(AppImages.avatarHost);
  }
  if (url.startsWith('http')) {
    return NetworkImage(url);
  }
  return AssetImage(url);
}
