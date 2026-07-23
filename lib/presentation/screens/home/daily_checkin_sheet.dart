import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/daily_reward_provider.dart';

class DailyCheckinSheet extends StatelessWidget {
  const DailyCheckinSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final dailyReward = context.watch<DailyRewardProvider>();
    final claimed = dailyReward.reward.claimedToday;
    final currentDay = dailyReward.reward.currentDayInCycle;
    final uid = context.read<AuthProvider>().currentUser?.uid;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 20),
          const Text('Daily Check-in',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Claim coins every day. Streaks earn bigger rewards!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final day = index + 1;
              final isPast = day < currentDay || (day == currentDay && claimed);
              final isToday = day == currentDay && !claimed;
              return Container(
                decoration: BoxDecoration(
                  gradient: isPast || isToday ? AppColors.goldGradient : null,
                  color: isPast || isToday ? null : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: isToday ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPast ? Icons.check_circle_rounded : Icons.monetization_on_rounded,
                      color: isPast || isToday ? Colors.white : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text('Day $day',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPast || isToday ? Colors.white : AppColors.textSecondary,
                        )),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          if (dailyReward.errorMessage != null)
            ErrorBanner(message: dailyReward.errorMessage!, onDismiss: dailyReward.clearError),
          PrimaryButton(
            label: claimed ? 'Already Claimed Today' : 'Claim Reward',
            isLoading: dailyReward.isClaiming,
            gradient: claimed ? null : AppColors.goldGradient,
            onPressed: claimed || uid == null
                ? null
                : () async {
                    final success = await dailyReward.claim(uid);
                    if (success && context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('+${dailyReward.lastClaimedAmount} coins added!')),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }
}
