import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../constants/app_strings.dart';
import '../network/network_status_cubit.dart';
import 'app_snackbar.dart';

class NetworkStatusSnackListener extends StatelessWidget {
  const NetworkStatusSnackListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkStatusCubit, NetworkStatusState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);

        switch (state.status) {
          case NetworkStatusType.offline:
            AppSnackBar.showError(context, AppStrings.offlineStatusMessage);
          case NetworkStatusType.slow:
            AppSnackBar.showInfo(
              context,
              AppStrings.slowConnectionStatusMessage,
            );
          case NetworkStatusType.online:
            messenger.hideCurrentSnackBar();
          case NetworkStatusType.unknown:
            break;
        }
      },
      child: child,
    );
  }
}
