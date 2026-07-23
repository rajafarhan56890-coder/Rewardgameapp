import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/config_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'reward':
        return Icons.card_giftcard_rounded;
      case 'withdrawal':
        return Icons.account_balance_wallet_rounded;
      case 'referral':
        return Icons.people_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();
    final uid = context.read<AuthProvider>().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0 && uid != null)
            TextButton(
              onPressed: () => provider.markAllAsRead(uid),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: provider.isLoading
            ? const LoadingIndicator()
            : provider.notifications.isEmpty
                ? const EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications',
                    subtitle: 'Reward alerts and announcements will appear here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: provider.notifications.length,
                    itemBuilder: (context, index) {
                      final n = provider.notifications[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: n.isRead ? AppColors.surface : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: n.isRead ? null : Border.all(color: AppColors.primary.withOpacity(0.4)),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (!n.isRead && uid != null) provider.markAsRead(uid, n.id);
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle),
                                child: Icon(_iconFor(n.type), color: AppColors.primaryVariant, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                                    const SizedBox(height: 3),
                                    Text(n.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('MMM d, h:mm a').format(n.createdAt),
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
