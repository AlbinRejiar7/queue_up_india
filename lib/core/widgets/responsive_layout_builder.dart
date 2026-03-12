import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef ResponsiveLayoutWidgetBuilder =
    Widget Function(
      BuildContext context,
      BoxConstraints constraints,
      EdgeInsets contentPadding,
    );

class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({
    required this.builder,
    super.key,
    this.mobileHorizontalPadding = 20,
    this.tabletHorizontalPadding = 28,
    this.tabletMaxWidth = 760,
  });

  final ResponsiveLayoutWidgetBuilder builder;
  final double mobileHorizontalPadding;
  final double tabletHorizontalPadding;
  final double tabletMaxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isTablet = constraints.maxWidth >= 600;
        final double maxWidth = min(
          constraints.maxWidth,
          isTablet ? tabletMaxWidth : constraints.maxWidth,
        );

        final EdgeInsets contentPadding = EdgeInsets.symmetric(
          horizontal:
              (isTablet ? tabletHorizontalPadding : mobileHorizontalPadding).w,
        );

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: builder(context, constraints, contentPadding),
          ),
        );
      },
    );
  }
}
