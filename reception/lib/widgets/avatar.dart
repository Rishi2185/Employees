import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A circular avatar that loads a network image and gracefully falls back to
/// the person's initials on a tinted background — so it always renders, even
/// fully offline. Features a gradient ring for depth.
class Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? background;
  final bool showRing;

  const Avatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 56,
    this.background,
    this.showRing = true,
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
    final inner = _buildInner();
    if (!showRing) return inner;

    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBright.withValues(alpha: 0.40),
            AppColors.primary.withValues(alpha: 0.15),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: inner,
    );
  }

  Widget _buildInner() {
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background ?? AppColors.mint,
            (background ?? AppColors.mint).withValues(alpha: 0.7),
          ],
        ),
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
