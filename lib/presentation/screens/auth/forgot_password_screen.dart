import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendPasswordReset(_emailController.text);
    if (!mounted) return;
    if (success) setState(() => _emailSent = true);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _emailSent ? _buildSuccessView() : _buildFormView(authProvider),
        ),
      ),
    );
  }

  Widget _buildFormView(AuthProvider authProvider) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Forgot your password?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Enter your registered email and we will send you a reset link.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 28),
            if (authProvider.errorMessage != null)
              ErrorBanner(message: authProvider.errorMessage!, onDismiss: authProvider.clearError),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Send Reset Link',
              isLoading: authProvider.isBusy,
              gradient: AppColors.primaryGradient,
              onPressed: _handleReset,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.accentGreen.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_rounded, color: AppColors.accentGreen, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('Check your inbox',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('We sent a password reset link to\n${_emailController.text}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Back to Login',
            gradient: AppColors.primaryGradient,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
