import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.imageUrl,
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderIconSize,
    this.iconColor,
    this.backgroundColor,
    this.showLoadingIndicator = true,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final IconData placeholderIcon;
  final double? placeholderIconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showLoadingIndicator;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return _placeholder(showSpinner: showLoadingIndicator);
      },
      errorBuilder: (context, error, stackTrace) {
        return _placeholder(showSpinner: false);
      },
    );
  }

  Widget _placeholder({required bool showSpinner}) {
    final resolvedIconSize =
        placeholderIconSize ??
        ((width ?? height ?? 28).clamp(14.0, 30.0).toDouble());

    final content = DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor ?? AppColors.navSurface),
      child: Center(
        child: showSpinner
            ? SizedBox(
                width: (resolvedIconSize * 0.85).clamp(12.0, 22.0),
                height: (resolvedIconSize * 0.85).clamp(12.0, 22.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textSecondary,
                ),
              )
            : Icon(
                placeholderIcon,
                size: resolvedIconSize,
                color: iconColor ?? AppColors.textSecondary,
              ),
      ),
    );

    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: content);
    }

    return SizedBox.expand(child: content);
  }
}
