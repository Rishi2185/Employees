import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A circular avatar that loads a network image and gracefully falls back to
/// the person's initials on a tinted background — so it always renders, even
/// fully offline.
class Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? background;

  const Avatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 56,
    this.background,
  });

  String get _initials {
    final cleaned =
        name.replaceAll(RegExp(r'(Dr\.?\s*)', caseSensitive: false), '');
    final parts = cleaned.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = _InitialsCircle(
      initials: _initials,
      size: size,
      background: background,
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _InitialsCircle(
            initials: _initials,
            size: size,
            background: background,
            shimmer: true,
          );
        },
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  final String initials;
  final double size;
  final Color? background;
  final bool shimmer;

  const _InitialsCircle({
    required this.initials,
    required this.size,
    this.background,
    this.shimmer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background ?? AppColors.mint,
      ),
      child: shimmer
          ? SizedBox(
              width: size * 0.36,
              height: size * 0.36,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryLight,
              ),
            )
          : Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
    );
  }
}
