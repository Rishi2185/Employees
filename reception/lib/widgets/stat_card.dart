import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A dashboard metric tile: a big number, a label, and an accent icon.
/// Features a hover/press scale animation, accent glow, and animated counter.
class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.primary,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: AppTheme.fast,
        curve: AppTheme.curve,
        child: AnimatedContainer(
          duration: AppTheme.fast,
          curve: AppTheme.curve,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: _hovered
                  ? widget.accent.withValues(alpha: 0.30)
                  : AppColors.border,
            ),
            boxShadow: _hovered ? AppColors.hoverGlow : AppColors.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.accent.withValues(alpha: 0.18),
                                widget.accent.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child:
                              Icon(widget.icon, color: widget.accent, size: 22),
                        ),
                        const Spacer(),
                        // Accent dot indicator
                        AnimatedContainer(
                          duration: AppTheme.fast,
                          width: _hovered ? 8 : 6,
                          height: _hovered ? 8 : 6,
                          decoration: BoxDecoration(
                            color: widget.accent.withValues(
                                alpha: _hovered ? 0.60 : 0.25),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AnimatedValue(
                          value: widget.value,
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tries to animate the value if it's numeric; otherwise just shows text.
class _AnimatedValue extends StatelessWidget {
  final String value;
  final TextStyle? style;
  const _AnimatedValue({required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    final numeric = int.tryParse(value);
    if (numeric != null) {
      return TweenAnimationBuilder<int>(
        tween: IntTween(begin: 0, end: numeric),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Text('$v', style: style),
      );
    }
    final dbl = double.tryParse(value);
    if (dbl != null) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: dbl),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) {
          final display = value.contains('.')
              ? v.toStringAsFixed(value.split('.').last.length)
              : '${v.toInt()}';
          return Text(display, style: style);
        },
      );
    }
    return Text(value, style: style);
  }
}

/// A small coloured status pill (Upcoming / Completed / Cancelled, etc.).
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
