import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/games_provider.dart';
import '../../providers/cash_tasks_provider.dart';
import '../../providers/daily_reward_provider.dart';
import '../../providers/withdrawal_provider.dart';
import '../../providers/referral_provider.dart';
import '../../providers/notifications_provider.dart';
import 'home_screen.dart';
import '../games/games_screen.dart';
import '../cash/cash_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    GamesScreen(),
    CashScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.sports_esports_rounded, label: 'Games'),
    (icon: Icons.payments_rounded, label: 'Cash'),
    (icon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bind all data providers to the current user id once available.
    final authUid = context.watch<AuthProvider>().currentUser?.uid;
    if (authUid != null) {
      context.read<WalletProvider>().bind(authUid);
      context.read<GamesProvider>().bind(authUid);
      context.read<CashTasksProvider>().bind(authUid);
      context.read<DailyRewardProvider>().bind(authUid);
      context.read<WithdrawalProvider>().bind(authUid);
      context.read<ReferralProvider>().bind(authUid);
      context.read<NotificationsProvider>().bind(authUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final item in _navItems)
            BottomNavigationBarItem(icon: Icon(item.icon), label: item.label),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
