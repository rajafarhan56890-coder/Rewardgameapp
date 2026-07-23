import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final _userRepository = UserRepository();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _usernameController = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    final result = await _userRepository.updateUsername(uid, _usernameController.text);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorOrNull!)));
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This permanently deletes your account, including your coins, cash points, and history. This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AuthProvider>().deleteAccount();
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        final error = context.read<AuthProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to delete account.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _usernameController,
                  label: 'Username',
                  validator: Validators.username,
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: TextEditingController(text: user?.email ?? ''),
                  label: 'Email',
                  enabled: false,
                  prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('Email cannot be changed here.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Save Changes',
                  isLoading: _isSaving,
                  gradient: AppColors.primaryGradient,
                  onPressed: _save,
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text('Danger Zone', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentRed,
                    side: const BorderSide(color: AppColors.accentRed),
                  ),
                  onPressed: _confirmDeleteAccount,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
