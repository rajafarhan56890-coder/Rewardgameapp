import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/daily_reward_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../../data/models/transaction_model.dart';
import '../notifications/notifications_screen.dart';
import '../games/games_screen.dart';
import '../cash/cash_screen.dart';
import 'daily_checkin_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final wallet = context.watch<WalletProvider>();
    final unread = context.watch<NotificationsProvider>().unreadCount;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome back 👋',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Text(user?.username ?? 'User',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ],
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, size: 28),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            ),
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration:
                                    const BoxDecoration(color: AppColors.accentRed, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text('$unread',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _BalanceCard(
                          gradient: AppColors.goldGradient,
                          icon: Icons.monetization_on_rounded,
                          label: 'Coins',
                          value: '${user?.coins ?? 0}',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _BalanceCard(
                          gradient: AppColors.cashGradient,
                          icon: Icons.payments_rounded,
                          label: 'Cash Points',
                          value: (user?.cashPoints ?? 0).toStringAsFixed(0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _DailyCheckinBanner(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: SectionHeader(title: 'Quick Actions'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.sports_esports_rounded,
                          label: 'Play & Earn',
                          color: AppColors.primary,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const GamesScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.payments_rounded,
                          label: 'Cash Tasks',
                          color: AppColors.accentGreen,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CashScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: SectionHeader(title: 'Recent Activity'),
                ),
              ),
              if (wallet.isLoading)
                const SliverToBoxAdapter(child: LoadingIndicator())
              else if (wallet.recentFive.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No activity yet',
                      subtitle: 'Complete tasks or claim your daily reward to see history here.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TransactionTile(tx: wallet.recentFive[index]),
                      childCount: wallet.recentFive.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Gradient gradient;
  final IconData icon;
  final String label;
  final String value;

  const _BalanceCard({required this.gradient, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 14),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCheckinBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dailyReward = context.watch<DailyRewardProvider>();
    final claimed = dailyReward.reward.claimedToday;

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const DailyCheckinSheet(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: claimed ? AppColors.accentGreen.withOpacity(0.15) : AppColors.accentGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  claimed ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                  color: claimed ? AppColors.accentGreen : AppColors.accentGold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(claimed ? 'Reward claimed today!' : 'Daily Check-in Available',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      claimed
                          ? 'Come back tomorrow for more coins'
                          : 'Streak: Day ${dailyReward.reward.currentDayInCycle} — tap to claim',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.direction == TxDirection.credit;
    final isCoin = tx.currency == TxCurrency.coins;
    final color = isCredit ? AppColors.accentGreen : AppColors.accentRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(
              isCoin ? Icons.monetization_on_rounded : Icons.payments_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(DateFormat('MMM d, h:mm a').format(tx.timestamp),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${isCoin ? tx.amount.toStringAsFixed(0) : tx.amount.toStringAsFixed(1)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
