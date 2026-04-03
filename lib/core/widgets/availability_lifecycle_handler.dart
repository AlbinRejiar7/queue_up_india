import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/availability_session_manager.dart';
import '../../features/home/bloc/home_availability_bloc.dart';
import '../../features/home/bloc/home_availability_event.dart';

class AvailabilityLifecycleHandler extends StatefulWidget {
  const AvailabilityLifecycleHandler({required this.child, super.key});

  final Widget child;

  @override
  State<AvailabilityLifecycleHandler> createState() =>
      _AvailabilityLifecycleHandlerState();
}

class _AvailabilityLifecycleHandlerState
    extends State<AvailabilityLifecycleHandler>
    with WidgetsBindingObserver {
  bool _didClearForBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _didClearForBackground = false;
      return;
    }

    if (_didClearForBackground) {
      return;
    }

    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _didClearForBackground = true;
      context.read<HomeAvailabilityBloc>().add(
        const HomeAvailabilityClearedExternally(),
      );
      AvailabilitySessionManager.clearAvailabilityOnTerminate();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
