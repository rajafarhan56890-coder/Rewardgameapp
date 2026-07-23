import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../home/main_shell.dart';

class RegisterScreen extends StatefulWidget {
  final String? prefilledReferralCode;
  const RegisterScreen({super.key, this.prefilledReferralCode});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final TextEditingController _referralController;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _referralController = TextEditingController(text: widget.prefilledReferralCode ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions to continue.')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      referralCode: _referralController.text.trim().isEmpty ? null : _referralController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('Join and start earning',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text('Create an account to earn coins & cash rewards',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 28),
                if (authProvider.errorMessage != null)
                  ErrorBanner(message: authProvider.errorMessage!, onDismiss: authProvider.clearError),
                AppTextField(
                  controller: _usernameController,
                  label: 'Username',
                  validator: Validators.username,
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  validator: Validators.password,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: _obscureConfirm,
                  validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _referralController,
                  label: 'Referral Code (optional)',
                  prefixIcon: const Icon(Icons.card_giftcard_rounded, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                    ),
                    const Expanded(
                      child: Text('I agree to the Terms of Service and Privacy Policy',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Create Account',
                  isLoading: authProvider.isBusy,
                  gradient: AppColors.primaryGradient,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
