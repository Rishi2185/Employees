import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// Admin sign-in (mobile). Gated to administrators — reception credentials are
/// rejected by the provider.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Brand header
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: AppColors.elevatedShadow,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 28),
              Text('Aarvy Admin',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 30)),
              const SizedBox(height: 6),
              const Text(
                'Hospital management dashboard. Administrators only.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14.5),
              ),
              const SizedBox(height: 40),
              AppTextField(
                label: 'Username',
                controller: _username,
                hint: 'admin',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_localError != null) setState(() => _localError = null);
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
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(error,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Sign in',
                icon: Icons.login_rounded,
                loading: auth.busy,
                onPressed: auth.busy ? null : _submit,
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Changes you make here update the patient app instantly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
