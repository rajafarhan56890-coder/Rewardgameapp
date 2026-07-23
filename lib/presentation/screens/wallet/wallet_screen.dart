import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../withdrawal/withdrawal_screen.dart';
import '../withdrawal/withdrawal_history_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final wallet = context.watch<WalletProvider>();
    final config = wallet.appConfig;
    final pkrValue = config.cashPointsToPkr(user?.cashPoints ?? 0);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Wallet')),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Wallet Value',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('Rs. ${pkrValue.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.monetization_on_rounded,
                              label: 'Coins',
                              value: '${user?.coins ?? 0}',
                            ),
                          ),
                          Container(width: 1, height: 32, color: Colors.white24),
                          Expanded(
                            child: _MiniStat(
                              icon: Icons.payments_rounded,
                              label: 'Cash Points',
                              value: (user?.cashPoints ?? 0).toStringAsFixed(0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${config.cashPointsPerUnit.toStringAsFixed(0)} Cash Points = Rs. ${config.cashUnitValuePkr.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Withdraw',
                        icon: Icons.account_balance_rounded,
                        gradient: AppColors.goldGradient,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WithdrawalScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WithdrawalHistoryScreen()),
                        ),
                        icon: const Icon(Icons.history_rounded, size: 18),
                        label: const Text('History'),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: TabBar(
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [Tab(text: 'Coins'), Tab(text: 'Cash Points')],
                ),
              ),
              Expanded(
                child: wallet.isLoading
                    ? const LoadingIndicator()
                    : TabBarView(
                        children: [
                          _TransactionList(transactions: wallet.coinTransactions, isCoin: true),
                          _TransactionList(transactions: wallet.cashTransactions, isCoin: false),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final bool isCoin;

  const _TransactionList({required this.transactions, required this.isCoin});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return EmptyState(
        icon: isCoin ? Icons.monetization_on_rounded : Icons.payments_rounded,
        title: 'No ${isCoin ? 'coin' : 'cash point'} history',
        subtitle: 'Your transaction history will show up here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isCredit = tx.direction == TxDirection.credit;
        final color = isCredit ? AppColors.accentGreen : AppColors.accentRed;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(DateFormat('MMM d, yyyy · h:mm a').format(tx.timestamp),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Text('${isCredit ? '+' : '-'}${tx.amount.toStringAsFixed(isCoin ? 0 : 1)}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        );
      },
    );
  }
}
