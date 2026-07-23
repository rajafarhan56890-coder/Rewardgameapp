import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/withdrawal_model.dart';
import '../../providers/withdrawal_provider.dart';

class WithdrawalHistoryScreen extends StatelessWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WithdrawalProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Withdrawal History'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            isScrollable: false,
            tabs: [Tab(text: 'Pending'), Tab(text: 'Approved'), Tab(text: 'Rejected')],
          ),
        ),
        body: SafeArea(
          child: provider.isLoading
              ? const LoadingIndicator()
              : TabBarView(
                  children: [
                    _WithdrawalList(items: provider.pending, emptyLabel: 'No pending requests'),
                    _WithdrawalList(items: provider.approved, emptyLabel: 'No approved requests yet'),
                    _WithdrawalList(items: provider.rejected, emptyLabel: 'No rejected requests'),
                  ],
                ),
        ),
      ),
    );
  }
}

class _WithdrawalList extends StatelessWidget {
  final List<WithdrawalModel> items;
  final String emptyLabel;

  const _WithdrawalList({required this.items, required this.emptyLabel});

  Color _statusColor(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.approved:
        return AppColors.accentGreen;
      case WithdrawalStatus.rejected:
        return AppColors.accentRed;
      case WithdrawalStatus.pending:
        return AppColors.accentGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(icon: Icons.account_balance_wallet_rounded, title: emptyLabel, subtitle: 'Your requests will appear here.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final color = _statusColor(item.status);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.method, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(item.status.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Rs. ${item.amountPkr.toStringAsFixed(0)}  ·  ${item.cashPointsDeducted.toStringAsFixed(0)} cash points',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text('${item.accountName} · ${item.accountNumber}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(DateFormat('MMM d, yyyy · h:mm a').format(item.createdAt),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Note: ${item.adminNote}',
                    style: const TextStyle(color: AppColors.accentRed, fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        );
      },
    );
  }
}
