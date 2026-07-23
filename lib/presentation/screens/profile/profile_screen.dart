import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../referral/referral_screen.dart';
import '../withdrawal/withdrawal_history_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploadingPhoto = false;
  final _userRepository = UserRepository();

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
    if (picked == null) return;

    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;

    setState(() => _uploadingPhoto = true);
    final result = await _userRepository.uploadProfilePicture(uid, File(picked.path));
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);

    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorOrNull!)));
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('You will need to log in again to access your account.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.surfaceElevated,
                        backgroundImage: (user?.photoUrl.isNotEmpty ?? false) ? NetworkImage(user!.photoUrl) : null,
                        child: (user?.photoUrl.isEmpty ?? true)
                            ? Text(
                                (user?.username.isNotEmpty ?? false) ? user!.username[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                            child: _uploadingPhoto
                                ? const SizedBox(
                                    height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(user?.username ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _StatBox(label: 'Coins', value: '${user?.coins ?? 0}', color: AppColors.accentGold)),
                const SizedBox(width: 12),
                Expanded(child: _StatBox(label: 'Cash Points', value: (user?.cashPoints ?? 0).toStringAsFixed(0), color: AppColors.accentGreen)),
              ],
            ),
            const SizedBox(height: 24),
            _ProfileTile(
              icon: Icons.badge_outlined,
              label: 'User ID',
              trailing: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: user?.uid ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User ID copied')));
                },
                child: Row(
                  children: [
                    Text(
                      user != null && user.uid.length > 10 ? '${user.uid.substring(0, 10)}…' : (user?.uid ?? ''),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            _ProfileTile(
              icon: Icons.edit_outlined,
              label: 'Edit Profile',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            ),
            _ProfileTile(
              icon: Icons.card_giftcard_rounded,
              label: 'Refer & Earn',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferralScreen())),
            ),
            _ProfileTile(
              icon: Icons.history_rounded,
              label: 'Withdrawal History',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WithdrawalHistoryScreen())),
            ),
            _ProfileTile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Help & Support', style: TextStyle(color: AppColors.textPrimary)),
                  content: const Text('For assistance, please contact support@coinvaultrewards.app',
                      style: TextStyle(color: AppColors.textSecondary)),
                  actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
                ),
              ),
            ),
            _ProfileTile(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              labelColor: AppColors.accentRed,
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? labelColor;

  const _ProfileTile({required this.icon, required this.label, this.onTap, this.trailing, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: labelColor ?? AppColors.textSecondary),
        title: Text(label, style: TextStyle(color: labelColor ?? AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary) : null),
      ),
    );
  }
}
