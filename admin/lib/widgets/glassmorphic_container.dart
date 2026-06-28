import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A frosted-glass container with a blurred backdrop, translucent fill, and a
/// soft luminous border. Use for login cards, info panels, and hero overlays.
///
/// On mobile / low-end GPUs the blur is disabled and replaced with a simple
/// semi-transparent fill for performance.
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? fillColor;
  final bool useFallback;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.borderRadius = AppTheme.radiusLg,
    this.blur = 16,
    this.fillColor,
    this.useFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = fillColor ?? AppColors.glassWhite;
    final radius = BorderRadius.circular(borderRadius);

    if (useFallback) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: radius,
          border: Border.all(color: AppColors.glassBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassGreen,
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: AppColors.glassBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassGreen,
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
