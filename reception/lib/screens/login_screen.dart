import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/fade_in.dart';
import '../widgets/glassmorphic_container.dart';
import '../state/auth_provider.dart';

/// Reception sign-in. A premium split layout:
/// - Left side: animated medical gradient mesh and floating icons.
/// - Right side: centered glassmorphic login card with staggered entrances.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _username = TextEditingController();
  final _password = TextEditingController();
  String? _localError;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _localError = 'Enter your username and password.');
      return;
    }
    await context.read<AuthProvider>().login(_username.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final error = _localError ?? auth.error;

    return Scaffold(
      body: Row(
        children: [
          // 1. LEFT BRAND PANEL (Interactive Desktop Mesh)
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Animated background gradient
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    final angle = _anim.value * 2 * math.pi;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: const [
                            Color(0xFF163E2D),
                            Color(0xFF1F5C42),
                            Color(0xFF2E7D5B),
                            Color(0xFF1F5C42),
                          ],
                          transform: GradientRotation(angle),
                        ),
                      ),
                    );
                  },
                ),

                // Floating clinical background shapes
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (context, _) {
                      final angle = _anim.value * 2 * math.pi;
                      return Stack(
                        children: [
                          _floatingShape(
                            left: 80 + 30 * math.sin(angle),
                            top: 120 + 20 * math.cos(angle),
                            icon: Icons.local_hospital_rounded,
                            size: 60,
                            opacity: 0.12,
                          ),
                          _floatingShape(
                            right: 90 + 20 * math.cos(angle + 1),
                            top: 200 + 40 * math.sin(angle + 1),
                            icon: Icons.health_and_safety_rounded,
                            size: 80,
                            opacity: 0.08,
                          ),
                          _floatingShape(
                            left: 100 + 40 * math.sin(angle + 2),
                            bottom: 180 + 30 * math.cos(angle + 2),
                            icon: Icons.vaccines_rounded,
                            size: 70,
                            opacity: 0.09,
                          ),
                          _floatingShape(
                            right: 120 + 25 * math.cos(angle + 3),
                            bottom: 140 + 35 * math.sin(angle + 3),
                            icon: Icons.favorite_rounded,
                            size: 50,
                            opacity: 0.12,
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Text Content
                Padding(
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeIn(
                        delay: const Duration(milliseconds: 100),
                        offsetX: -30,
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(Icons.local_hospital_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Aarvy',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      FadeIn(
                        delay: const Duration(milliseconds: 200),
                        offsetY: 20,
                        child: const Text(
                          'Reception\nStation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeIn(
                        delay: const Duration(milliseconds: 300),
                        offsetY: 20,
                        child: Text(
                          'Manage appointments, register walk-ins, print slips, and run\nthe secure end-of-day archive — all from the front desk.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. RIGHT FORM PANEL
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.scaffold,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeIn(
                          delay: const Duration(milliseconds: 150),
                          offsetY: -15,
                          child: Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FadeIn(
                          delay: const Duration(milliseconds: 200),
                          offsetY: -10,
                          child: const Text(
                            'Sign in with your reception credentials.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Form card
                        FadeIn(
                          delay: const Duration(milliseconds: 250),
                          scaleFrom: 0.96,
                          child: GlassmorphicContainer(
                            borderRadius: AppTheme.radiusLg,
                            padding: const EdgeInsets.all(24),
                            fillColor: AppColors.white,
                            useFallback: true, // Performs extremely well as a solid card
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppTextField(
                                  label: 'Username',
                                  controller: _username,
                                  hint: 'reception',
                                  prefixIcon: Icons.person_outline_rounded,
                                  autofocus: true,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) {
                                    if (_localError != null) {
                                      setState(() => _localError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  label: 'Password',
                                  controller: _password,
                                  hint: '••••••••',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submit(),
                                ),
                                if (error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      border: Border.all(
                                        color: AppColors.danger.withValues(alpha: 0.15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline_rounded,
                                            size: 18, color: AppColors.danger),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            error,
                                            style: const TextStyle(
                                              color: AppColors.danger,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                PrimaryButton(
                                  label: 'Sign in',
                                  icon: Icons.login_rounded,
                                  loading: auth.busy,
                                  onPressed: auth.busy ? null : _submit,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingShape({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required IconData icon,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Opacity(
        opacity: opacity,
        child: Icon(
          icon,
          size: size,
          color: AppColors.white,
        ),
      ),
    );
  }
}
