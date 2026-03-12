import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class GlowBackground extends StatelessWidget {
  const GlowBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(color: AppColors.background),
        Positioned(
          top: -140,
          right: -120,
          child: _GlowOrb(
            color: AppColors.electricBlue.withValues(alpha: 0.24),
            size: 320,
          ),
        ),
        Positioned(
          bottom: -180,
          left: -120,
          child: _GlowOrb(
            color: AppColors.softPurple.withValues(alpha: 0.16),
            size: 360,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.1),
                  radius: 1.2,
                  colors: <Color>[
                    AppColors.electricBlue.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(color: color, blurRadius: size / 2, spreadRadius: 12),
        ],
      ),
    );
  }
}
