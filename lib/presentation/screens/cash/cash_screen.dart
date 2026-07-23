import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/game_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cash_tasks_provider.dart';

class CashScreen extends StatelessWidget {
  const CashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cash Rewards'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [Tab(text: 'Available Tasks'), Tab(text: 'Pending Review')],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(children: [_AvailableTasksTab(), _PendingTab()]),
        ),
      ),
    );
  }
}

class _AvailableTasksTab extends StatelessWidget {
  const _AvailableTasksTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashTasksProvider>();
    final uid = context.watch<AuthProvider>().currentUser?.uid;

    if (provider.isLoading) return const LoadingIndicator();
    if (provider.tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.payments_rounded,
        title: 'No tasks available',
        subtitle: 'New cash-earning tasks are added frequently. Check back soon.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.tasks.length,
      itemBuilder: (context, index) {
        final task = provider.tasks[index];
        final completed = provider.isCompleted(task.id);
        final isClaiming = provider.claimingTaskId == task.id;
        return _CashTaskCard(
          task: task,
          completed: completed,
          isClaiming: isClaiming,
          onComplete: uid == null
              ? null
              : () async {
                  final success = await provider.completeTask(uid, task);
                  if (!context.mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('+${task.rewardCashPoints.toStringAsFixed(0)} cash points earned!')),
                    );
                  } else if (provider.actionError != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(provider.actionError!)));
                    provider.clearError();
                  }
                },
        );
      },
    );
  }
}

class _PendingTab extends StatelessWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashTasksProvider>();
    if (provider.pendingCompletions.isEmpty) {
      return const EmptyState(
        icon: Icons.hourglass_top_rounded,
        title: 'No pending tasks',
        subtitle: 'Tasks awaiting admin review will appear here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: provider.pendingCompletions.length,
      itemBuilder: (context, index) {
        final item = provider.pendingCompletions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, color: AppColors.accentGold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['taskTitle'] ?? 'Task',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Awaiting review · +${item['rewardCashPoints']} cash points',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CashTaskCard extends StatelessWidget {
  final CashTaskModel task;
  final bool completed;
  final bool isClaiming;
  final VoidCallback? onComplete;

  const _CashTaskCard({
    required this.task,
    required this.completed,
    required this.isClaiming,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(gradient: AppColors.cashGradient, shape: BoxShape.circle),
            child: const Icon(Icons.payments_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Text('+${task.rewardCashPoints.toStringAsFixed(0)} cash points',
                    style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: completed ? null : onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: completed ? AppColors.divider : AppColors.accentGreen,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: isClaiming
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(completed ? 'Done' : 'Complete', style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
