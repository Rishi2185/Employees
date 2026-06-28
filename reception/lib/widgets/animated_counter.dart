import 'package:flutter/material.dart';

/// Animated number that counts from 0 (or [from]) to [value] over [duration].
/// Useful for stat cards and dashboard counters.
class AnimatedCounter extends StatelessWidget {
  final int value;
  final int from;
  final Duration duration;
  final TextStyle? style;
  final String Function(int)? formatter;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.from = 0,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: from, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final display = formatter != null ? formatter!(v) : '$v';
        return Text(display, style: style);
      },
    );
  }
}

/// A version that counts doubles (for averages, ratings, etc.).
class AnimatedDoubleCounter extends StatelessWidget {
  final double value;
  final double from;
  final int decimals;
  final Duration duration;
  final TextStyle? style;

  const AnimatedDoubleCounter({
    super.key,
    required this.value,
    this.from = 0,
    this.decimals = 1,
    this.duration = const Duration(milliseconds: 800),
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: from, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Text(v.toStringAsFixed(decimals), style: style);
      },
    );
  }
}
