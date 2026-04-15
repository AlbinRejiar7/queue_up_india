import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_options.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/activity_pulse_panel.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/rank_tag_chip.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../../../core/widgets/tag_chip.dart';
import '../../bloc/matchmaking_bloc.dart';
import '../../bloc/matchmaking_event.dart';
import '../../bloc/matchmaking_state.dart';
import '../../models/solo_squad_model.dart';
import '../../../../core/ads/interstitial_ad_manager.dart';

class SoloMatchmakingScreen extends StatefulWidget {
  const SoloMatchmakingScreen({
    required this.gameId,
    super.key,
    this.initialRank,
    this.initialLanguage,
    this.autoStart = false,
  });

  final String gameId;
  final String? initialRank;
  final String? initialLanguage;
  final bool autoStart;

  @override
  State<SoloMatchmakingScreen> createState() => _SoloMatchmakingScreenState();
}

class _SoloMatchmakingScreenState extends State<SoloMatchmakingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MatchmakingBloc>().add(
      MatchmakingInitialized(
        gameId: widget.gameId,
        initialRank: widget.initialRank,
        initialLanguage: widget.initialLanguage,
        autoStart: widget.autoStart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: ResponsiveLayoutBuilder(
            tabletMaxWidth: 840,
            tabletHorizontalPadding: 32,
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsets contentPadding,
                ) {
                  return BlocConsumer<MatchmakingBloc, MatchmakingState>(
                    listener: (context, state) {
                      final message = state.feedbackMessage;
                      if (message == null || message.isEmpty) {
                        return;
                      }
                      if (state.feedbackIsError) {
                        AppSnackBar.showError(context, message);
                      } else {
                        AppSnackBar.showInfo(context, message);
                        if (message == AppStrings.matchmakingCancelled) {
                          InterstitialAdManager.instance.showAd(
                            onAdDismissed: () {
                              if (!context.mounted) {
                                return;
                              }
                              context.go(AppRoutes.home);
                            },
                          );
                          context.read<MatchmakingBloc>().add(
                            const MatchmakingFeedbackConsumed(),
                          );
                          return;
                        }
                      }
                      context.read<MatchmakingBloc>().add(
                        const MatchmakingFeedbackConsumed(),
                      );
                    },
                    builder: (context, state) {
                      return Column(
                        children: <Widget>[
                          Padding(
                            padding: contentPadding,
                            child: Column(
                              children: <Widget>[
                                SizedBox(height: 6.h),
                                Row(
                                  children: <Widget>[
                                    SafeBackButton(
                                      fallbackRoute: AppRoutes.partyListPath(
                                        widget.gameId,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        AppStrings.findSquadTitle,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.pageTitle,
                                      ),
                                    ),
                                    SizedBox(width: 48.w),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  _subtitleForPhase(state.phase),
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                contentPadding.left,
                                12.h,
                                contentPadding.right,
                                28.h,
                              ),
                              children: <Widget>[
                                _buildPhaseContent(context, state),
                              ],
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
    );
  }

  Widget _buildPhaseContent(BuildContext context, MatchmakingState state) {
    switch (state.phase) {
      case MatchmakingUiPhase.searching:
        return _SearchingSection(
          state: state,
          onCancel: () {
            context.read<MatchmakingBloc>().add(
              const MatchmakingCancelRequested(),
            );
          },
          onSeeAvailable: () {
            context.push(
              '${AppRoutes.availablePlayers}?gameId=${state.selectedGameId}',
            );
          },
          onBrowseParties: () {
            context.push(AppRoutes.partyListPath(state.selectedGameId));
          },
          onKeepWaiting: () {
            context.read<MatchmakingBloc>().add(
              const MatchmakingKeepWaitingRequested(),
            );
          },
        );
      case MatchmakingUiPhase.squadFound:
        return _SquadFoundSection(
          state: state,
          onAccept: () {
            context.read<MatchmakingBloc>().add(
              const MatchmakingAcceptRequested(),
            );
          },
          onReject: () {
            context.read<MatchmakingBloc>().add(
              const MatchmakingRejectRequested(),
            );
          },
        );
      case MatchmakingUiPhase.confirmed:
        return _ConfirmedSection(
          state: state,
          onDone: () {
            context.go(AppRoutes.partyListPath(widget.gameId));
          },
        );
      case MatchmakingUiPhase.setup:
        return _SetupSection(
          state: state,
          onGameChanged: (String? value) {
            if (value == null) {
              return;
            }
            context.read<MatchmakingBloc>().add(MatchmakingGameChanged(value));
          },
          onRankChanged: (String? value) {
            if (value == null) {
              return;
            }
            context.read<MatchmakingBloc>().add(MatchmakingRankChanged(value));
          },
          onLanguageChanged: (String? value) {
            if (value == null) {
              return;
            }
            context.read<MatchmakingBloc>().add(
              MatchmakingLanguageChanged(value),
            );
          },
          onStart: () {
            context.read<MatchmakingBloc>().add(
              const MatchmakingStartRequested(),
            );
          },
        );
    }
  }

  String _subtitleForPhase(MatchmakingUiPhase phase) {
    switch (phase) {
      case MatchmakingUiPhase.searching:
        return AppStrings.matchmakingSearchingSubtitle;
      case MatchmakingUiPhase.squadFound:
        return AppStrings.matchmakingSquadFoundSubtitle;
      case MatchmakingUiPhase.confirmed:
        return AppStrings.matchmakingLobbySubtitle;
      case MatchmakingUiPhase.setup:
        return AppStrings.matchmakingSetupSubtitle;
    }
  }
}

class _SetupSection extends StatelessWidget {
  const _SetupSection({
    required this.state,
    required this.onGameChanged,
    required this.onRankChanged,
    required this.onLanguageChanged,
    required this.onStart,
  });

  final MatchmakingState state;
  final ValueChanged<String?> onGameChanged;
  final ValueChanged<String?> onRankChanged;
  final ValueChanged<String?> onLanguageChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final rankOptions = AppOptions.rankOptionsByGame(state.selectedGameId);
    return GlassContainer(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppStrings.findSquadSetupTitle,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(AppStrings.findSquadSetupBody, style: AppTextStyles.bodyMedium),
          SizedBox(height: 18.h),
          _Label(text: AppStrings.game),
          SizedBox(height: 8.h),
          _DropdownField<String>(
            value: state.selectedGameId,
            items: AppOptions.gameOptions.map((game) => game.id).toList(),
            itemBuilder: (gameId) {
              final game = AppOptions.gameOptions.firstWhere(
                (option) => option.id == gameId,
                orElse: () => AppOptions.gameOptions.first,
              );
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.asset(
                      game.imageUrl,
                      width: 24.w,
                      height: 24.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    game.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.buttonText.copyWith(fontSize: 18.sp),
                  ),
                ],
              );
            },
            onChanged: onGameChanged,
          ),
          SizedBox(height: 16.h),
          _Label(text: AppStrings.filterRank),
          SizedBox(height: 8.h),
          _DropdownField<String>(
            value: state.selectedRankId,
            items: rankOptions.map((rank) => rank.name).toList(),
            itemBuilder: (rankName) {
              final rank = rankOptions.firstWhere(
                (option) => option.name == rankName,
                orElse: () =>
                    AppOptions.defaultRankForGame(state.selectedGameId),
              );
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset(
                    rank.imageUrl,
                    width: 24.w,
                    height: 24.w,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.workspace_premium,
                      size: 20.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    rank.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.buttonText.copyWith(fontSize: 18.sp),
                  ),
                ],
              );
            },
            onChanged: onRankChanged,
          ),
          SizedBox(height: 16.h),
          _Label(text: AppStrings.filterLanguage),
          SizedBox(height: 8.h),
          _DropdownField<String>(
            value: state.selectedLanguageId,
            items: AppOptions.languageOptions,
            onChanged: onLanguageChanged,
          ),
          SizedBox(height: 18.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: <Widget>[
              TagChip(
                label: AppOptions.gameNameById(state.selectedGameId),
                icon: Icons.videogame_asset_rounded,
              ),
              RankTagChip(
                rankName: state.selectedRankId,
                gameId: state.selectedGameId,
              ),
              TagChip(
                label: state.selectedLanguageId,
                icon: Icons.record_voice_over_rounded,
              ),
            ],
          ),
          SizedBox(height: 22.h),
          PrimaryButton(
            label: AppStrings.findSquadAction,
            icon: Icons.bolt_rounded,
            isLoading: state.isSubmitting,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _SearchingSection extends StatelessWidget {
  const _SearchingSection({
    required this.state,
    required this.onCancel,
    required this.onSeeAvailable,
    required this.onBrowseParties,
    required this.onKeepWaiting,
  });

  final MatchmakingState state;
  final VoidCallback onCancel;
  final VoidCallback onSeeAvailable;
  final VoidCallback onBrowseParties;
  final VoidCallback onKeepWaiting;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: <Widget>[
          Container(
            width: 96.w,
            height: 96.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.electricBlue.withValues(alpha: 0.18),
              border: Border.all(
                color: AppColors.electricBlue.withValues(alpha: 0.5),
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
          SizedBox(height: 18.h),
          Text(
            AppStrings.findSquadSearchingTitle,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 24.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.findSquadSearchingBody,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 18.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: <Widget>[
              TagChip(
                label: AppOptions.gameNameById(state.selectedGameId),
                icon: Icons.videogame_asset_rounded,
              ),
              RankTagChip(
                rankName: state.selectedRankId,
                gameId: state.selectedGameId,
              ),
              TagChip(
                label: state.selectedLanguageId,
                icon: Icons.record_voice_over_rounded,
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  label: AppStrings.playersFoundLabel,
                  value: '${state.playersFound}/4',
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _StatTile(
                  label: AppStrings.estimatedTimeLabel,
                  value: _formatEta(state.estimatedSeconds),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          ActivityPulsePanel(
            gameId: state.selectedGameId,
            onSoloPlayersTap: () {
              context.push(
                '${AppRoutes.availablePlayers}?gameId=${state.selectedGameId}',
              );
            },
            onOpenPartiesTap: () {
              context.push(AppRoutes.partyListPath(state.selectedGameId));
            },
          ),
          if (state.showLowQueueFallback) ...<Widget>[
            SizedBox(height: 18.h),
            GlassContainer(
              padding: EdgeInsets.all(16.w),
              backgroundColor: Colors.white.withValues(alpha: 0.028),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppStrings.lowQueueFallbackTitle,
                    style: AppTextStyles.buttonText.copyWith(fontSize: 18.sp),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    AppStrings.lowQueueFallbackBody,
                    style: AppTextStyles.bodyMedium,
                  ),
                  SizedBox(height: 14.h),
                  PrimaryButton(
                    label: AppStrings.seeAvailableSoloPlayers,
                    icon: Icons.groups_rounded,
                    onPressed: onSeeAvailable,
                  ),
                  SizedBox(height: 10.h),
                  PrimaryButton(
                    label: AppStrings.browsePartiesAction,
                    icon: Icons.sports_esports_rounded,
                    onPressed: onBrowseParties,
                  ),
                  SizedBox(height: 10.h),
                  PrimaryButton(
                    label: AppStrings.keepWaitingAction,
                    onPressed: onKeepWaiting,
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 18.h),
          PrimaryButton(
            label: AppStrings.cancelSearchAction,
            isDanger: true,
            isLoading: state.isSubmitting,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _SquadFoundSection extends StatelessWidget {
  const _SquadFoundSection({
    required this.state,
    required this.onAccept,
    required this.onReject,
  });

  final MatchmakingState state;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final squad = state.squad;
    return GlassContainer(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  AppStrings.squadFoundTitle,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 24.sp),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  '${state.acceptSecondsRemaining}s',
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.success,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(AppStrings.squadFoundBody, style: AppTextStyles.bodyMedium),
          SizedBox(height: 18.h),
          if (squad != null)
            ...squad.participants.map(
              (player) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _ParticipantTile(
                  player: player,
                  accepted: squad.isAcceptedBy(player.uid),
                  isCurrentUser: player.uid == state.currentUserId,
                ),
              ),
            ),
          SizedBox(height: 8.h),
          PrimaryButton(
            label: state.currentUserAccepted
                ? AppStrings.waitingForOthersAction
                : AppStrings.acceptMatchAction,
            icon: state.currentUserAccepted ? Icons.hourglass_top : Icons.check,
            isLoading: state.isSubmitting,
            enabled: !state.currentUserAccepted,
            onPressed: onAccept,
          ),
          SizedBox(height: 10.h),
          PrimaryButton(
            label: AppStrings.declineMatchAction,
            isDanger: true,
            isLoading: state.isSubmitting && !state.currentUserAccepted,
            onPressed: onReject,
          ),
        ],
      ),
    );
  }
}

class _ConfirmedSection extends StatelessWidget {
  const _ConfirmedSection({required this.state, required this.onDone});

  final MatchmakingState state;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final squad = state.squad;
    return GlassContainer(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.verified_rounded,
                color: AppColors.success,
                size: 22.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  AppStrings.squadReadyTitle,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 24.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(AppStrings.squadReadyBody, style: AppTextStyles.bodyMedium),
          SizedBox(height: 18.h),
          if (squad != null)
            ...squad.participants.map(
              (player) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _ParticipantTile(
                  player: player,
                  accepted: true,
                  isCurrentUser: player.uid == state.currentUserId,
                ),
              ),
            ),
          SizedBox(height: 18.h),
          PrimaryButton(
            label: AppStrings.doneAction,
            icon: Icons.arrow_forward_rounded,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.player,
    required this.accepted,
    required this.isCurrentUser,
  });

  final SoloSquadParticipantModel player;
  final bool accepted;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final avatarProvider = _avatarProvider(player.avatarUrl);
    return GlassContainer(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      backgroundColor: Colors.white.withValues(alpha: 0.028),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.navSurface,
            backgroundImage: avatarProvider,
            child: avatarProvider == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isCurrentUser
                      ? '${player.displayName} (${AppStrings.chatYou})'
                      : player.displayName,
                  style: AppTextStyles.buttonText.copyWith(fontSize: 16.sp),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: <Widget>[
                    RankTagChip(
                      rankName: player.rankId,
                      gameId: player.gameId,
                      compact: true,
                    ),
                    TagChip(
                      label: player.languageId,
                      compact: true,
                      icon: Icons.record_voice_over_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: (accepted ? AppColors.success : AppColors.textSecondary)
                  .withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Text(
              accepted
                  ? AppStrings.acceptedShortLabel
                  : AppStrings.pendingLabel,
              style: AppTextStyles.caption.copyWith(
                color: accepted ? AppColors.success : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 22.sp),
          ),
          SizedBox(height: 4.h),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemBuilder,
  });

  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final Widget Function(T item)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child:
                  itemBuilder?.call(item) ??
                  Text(
                    '$item',
                    style: AppTextStyles.buttonText.copyWith(fontSize: 18.sp),
                  ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.navSurface,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      iconEnabledColor: AppColors.textSecondary,
      style: AppTextStyles.buttonText.copyWith(fontSize: 18.sp),
    );
  }
}

String _formatEta(int seconds) {
  if (seconds <= 5) {
    return '~5 sec';
  }
  if (seconds < 60) {
    return '~$seconds sec';
  }
  final minutes = (seconds / 60).ceil();
  return '~$minutes min';
}

ImageProvider? _avatarProvider(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.trim().isEmpty) {
    return null;
  }
  if (avatarUrl.startsWith('http')) {
    return NetworkImage(avatarUrl);
  }
  return AssetImage(avatarUrl);
}
