import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Primary call-to-action button with a green gradient, loading state, shimmer
/// highlight, and a subtle press animation.
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _hovered = false;

  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed
              ? 0.96
              : _hovered
                  ? 1.02
                  : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.55,
            duration: AppTheme.fast,
            child: Container(
              width: widget.expand ? double.infinity : null,
              height: 52,
              padding: widget.expand
                  ? null
                  : const EdgeInsets.symmetric(horizontal: 28),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3DB868),
                    Color(0xFF34A853),
                    Color(0xFF2E7D5B),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2E7D5B)
                              .withValues(alpha: _hovered ? 0.30 : 0.18),
                          blurRadius: _hovered ? 28 : 24,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Shimmer highlight
                  if (enabled)
                    AnimatedBuilder(
                      animation: _shimmer,
                      builder: (context, _) {
                        return Positioned.fill(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            child: ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  begin: Alignment(-1 + 3 * _shimmer.value, 0),
                                  end: Alignment(
                                      -1 + 3 * _shimmer.value + 0.5, 0),
                                  colors: const [
                                    Colors.transparent,
                                    Color(0x15FFFFFF),
                                    Colors.transparent,
                                  ],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcATop,
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                        );
                      },
                    ),
                  // Content
                  widget.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              widget.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
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
    );
  }
}
