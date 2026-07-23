import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/referral_provider.dart';
import '../../../data/repositories/referral_repository.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final referralProvider = context.watch<ReferralProvider>();
    final code = user?.referralCode ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  const Text('Invite friends & earn coins',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('You both get rewarded when your friend joins using your code.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(code, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: code));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Referral code copied!')));
                          },
                          child: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: 'Join me on CoinVault Rewards and earn coins & cash! Use my referral code: $code',
                        ));
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Invite message copied — paste it anywhere to share!')));
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share Invite'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: 'Your Referrals (${referralProvider.referrals.length})'),
            if (referralProvider.referrals.isEmpty)
              const EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No referrals yet',
                subtitle: 'Share your code with friends to start earning bonus coins.',
              )
            else
              ...referralProvider.referrals.map((r) => _ReferralTile(referral: r)),
          ],
        ),
      ),
    );
  }
}

class _ReferralTile extends StatelessWidget {
  final ReferralModel referral;
  const _ReferralTile({required this.referral});

  @override
  Widget build(BuildContext context) {
    final rewarded = referral.status == 'rewarded';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(referral.referredUsername.isNotEmpty ? referral.referredUsername[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primaryVariant, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(referral.referredUsername, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                Text(DateFormat('MMM d, yyyy').format(referral.createdAt),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (rewarded ? AppColors.accentGreen : AppColors.accentGold).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(rewarded ? 'Rewarded' : 'Pending',
                style: TextStyle(color: rewarded ? AppColors.accentGreen : AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
