import 'package:flutter/widgets.dart';

import '../services/availability_session_manager.dart';

class AvailabilityLifecycleHandler extends StatefulWidget {
  const AvailabilityLifecycleHandler({required this.child, super.key});

  final Widget child;

  @override
  State<AvailabilityLifecycleHandler> createState() =>
      _AvailabilityLifecycleHandlerState();
}

class _AvailabilityLifecycleHandlerState
    extends State<AvailabilityLifecycleHandler> with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.detached) {
      AvailabilitySessionManager.clearAvailabilityOnTerminate();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
