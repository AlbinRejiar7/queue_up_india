import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SafeBackButton extends StatelessWidget {
  const SafeBackButton({
    required this.fallbackRoute,
    super.key,
    this.tonal = false,
  });

  final String fallbackRoute;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final icon = const Icon(Icons.arrow_back);

    if (tonal) {
      return IconButton.filledTonal(
        onPressed: () => _handlePressed(context),
        icon: icon,
      );
    }

    return IconButton(onPressed: () => _handlePressed(context), icon: icon);
  }

  void _handlePressed(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }
}
