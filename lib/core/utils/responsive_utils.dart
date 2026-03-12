import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_values.dart';

abstract final class ResponsiveUtils {
  static double contentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < AppValues.maxMobileWidth ? width : AppValues.maxMobileWidth;
  }

  static EdgeInsets horizontalSafePadding(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final content = contentWidth(context);
    final side = (screenWidth - content) / 2 + AppValues.horizontalPadding;
    return EdgeInsets.symmetric(horizontal: side.clamp(16.w, 56.w));
  }
}
