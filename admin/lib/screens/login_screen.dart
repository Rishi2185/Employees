import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/fade_in.dart';
import '../widgets/glassmorphic_container.dart';

/// Admin sign-in (mobile). Gated to administrators.
/// Premium visual presentation matching the patient app:
/// Animated gradient background, floating medical shapes, and glassmorphic card.
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

  late final AnimationController _bgAnim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 15),
  )..repeat();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _bgAnim.dispose();
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
      body: Stack(
        children: [
          // 1. Rich animated background gradient
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, _) {
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
                    transform: GradientRotation(_bgAnim.value * 2 * math.pi),
                  ),
                ),
              );
            },
          ),

          // 2. Floating medical icons/shapes for premium aesthetic depth
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (context, _) {
                final angle = _bgAnim.value * 2 * math.pi;
                return Stack(
                  children: [
                    _floatingShape(
                      left: 40 + 15 * math.sin(angle),
                      top: 100 + 20 * math.cos(angle),
                      icon: Icons.local_hospital_rounded,
                      size: 40,
                      opacity: 0.12,
                    ),
                    _floatingShape(
                      right: 50 + 20 * math.cos(angle + 1),
                      top: 180 + 15 * math.sin(angle + 1),
                      icon: Icons.health_and_safety_rounded,
                      size: 64,
                      opacity: 0.08,
                    ),
                    _floatingShape(
                      left: 60 + 25 * math.sin(angle + 2),
                      bottom: 120 + 20 * math.cos(angle + 2),
                      icon: Icons.vaccines_rounded,
                      size: 48,
                      opacity: 0.10,
                    ),
                    _floatingShape(
                      right: 40 + 15 * math.cos(angle + 3),
                      bottom: 100 + 25 * math.sin(angle + 3),
                      icon: Icons.favorite_rounded,
                      size: 32,
                      opacity: 0.14,
                    ),
                  ],
                );
              },
            ),
          ),

          // 3. Center Login Console
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Badge
                      FadeIn(
                        delay: const Duration(milliseconds: 100),
                        offsetY: -30,
                        scaleFrom: 0.85,
                        child: Container(
                          width: 80,
                          height: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title texts
                      FadeIn(
                        delay: const Duration(milliseconds: 200),
                        offsetY: -15,
                        child: const Text(
                          'Aarvy Admin',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FadeIn(
                        delay: const Duration(milliseconds: 250),
                        offsetY: -10,
                        child: Text(
                          'Hospital management console. Admin role only.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Glassmorphic Form Card
                      FadeIn(
                        delay: const Duration(milliseconds: 300),
                        scaleFrom: 0.95,
                        child: GlassmorphicContainer(
                          borderRadius: AppTheme.radiusLg + 4,
                          padding: const EdgeInsets.all(24),
                          fillColor: AppColors.white.withValues(alpha: 0.92),
                          useFallback: true, // Use simpler solid fallback for performance on Android
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(
                                label: 'Username',
                                controller: _username,
                                hint: 'e.g. admin',
                                prefixIcon: Icons.person_outline_rounded,
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
                                            fontWeight: FontWeight.w500,
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
                      const SizedBox(height: 28),

                      // Footer notice
                      FadeIn(
                        delay: const Duration(milliseconds: 400),
                        offsetY: 20,
                        child: Text(
                          'Changes you make here update the patient app instantly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.65),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
