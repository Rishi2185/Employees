import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'fade_in.dart';

/// Consistent page chrome for the main sections: a padded header with title,
/// subtitle, actions, and a premium gradient accent line, above the body.
class ScreenScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final EdgeInsets padding;

  const ScreenScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(32, 28, 32, 20),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FadeIn(
                          delay: const Duration(milliseconds: 50),
                          offsetY: 10,
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Small glowing gradient line to the right of title
                        Expanded(
                          child: FadeIn(
                            delay: const Duration(milliseconds: 150),
                            offsetX: -20,
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryLight.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      FadeIn(
                        delay: const Duration(milliseconds: 100),
                        offsetY: 8,
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                FadeIn(
                  delay: const Duration(milliseconds: 150),
                  offsetX: 20,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions
                        .map((a) => Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: a,
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
        // Divider line with subtle opacity
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          color: AppColors.border.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 16),
        Expanded(child: child),
      ],
    );
  }
}
