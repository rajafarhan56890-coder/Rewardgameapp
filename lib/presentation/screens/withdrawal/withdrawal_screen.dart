import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/withdrawal_provider.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedMethod = AppConstants.withdrawalMethods.first;

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _isBank => _selectedMethod == 'Bank Transfer';

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final user = context.read<AuthProvider>().currentUser;
    final config = context.read<WalletProvider>().appConfig;
    if (user == null) return;

    if (!_formKey.currentState!.validate()) return;

    final cashPoints = double.parse(_amountController.text.trim());
    if (cashPoints > user.cashPoints) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Insufficient cash points balance.')));
      return;
    }

    final withdrawalProvider = context.read<WithdrawalProvider>();
    final success = await withdrawalProvider.submit(
      uid: user.uid,
      method: _selectedMethod,
      accountName: _accountNameController.text,
      accountNumber: _accountNumberController.text,
      bankName: _isBank ? _bankNameController.text : null,
      cashPoints: cashPoints,
      config: config,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Withdrawal request submitted successfully!')));
      Navigator.of(context).pop();
    } else if (withdrawalProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(withdrawalProvider.errorMessage!)));
      withdrawalProvider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final wallet = context.watch<WalletProvider>();
    final withdrawalProvider = context.watch<WithdrawalProvider>();
    final config = wallet.appConfig;
    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0;
    final pkrPreview = config.cashPointsToPkr(enteredAmount);

    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw Funds')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available Cash Points', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text((user?.cashPoints ?? 0).toStringAsFixed(0),
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Withdrawal Method',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final method in AppConstants.withdrawalMethods)
                      ChoiceChip(
                        label: Text(method),
                        selected: _selectedMethod == method,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: TextStyle(
                          color: _selectedMethod == method ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _selectedMethod = method),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _accountNameController,
                  label: 'Account Holder Name',
                  validator: (v) => Validators.notEmpty(v, field: 'Account holder name'),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _accountNumberController,
                  label: _isBank ? 'Account Number' : 'Mobile Number',
                  keyboardType: TextInputType.text,
                  validator: _isBank ? Validators.bankAccount : Validators.phone,
                  prefixIcon: Icon(_isBank ? Icons.credit_card_rounded : Icons.phone_iphone_rounded,
                      color: AppColors.textSecondary),
                ),
                if (_isBank) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _bankNameController,
                    label: 'Bank Name',
                    validator: (v) => Validators.notEmpty(v, field: 'Bank name'),
                    prefixIcon: const Icon(Icons.account_balance_rounded, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 16),
                AppTextField(
                  controller: _amountController,
                  label: 'Cash Points to Withdraw',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => Validators.amount(v, max: user?.cashPoints),
                  prefixIcon: const Icon(Icons.payments_rounded, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                if (enteredAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('≈ Rs. ${pkrPreview.toStringAsFixed(0)} (min Rs. ${config.minWithdrawalPkr.toStringAsFixed(0)})',
                        style: const TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Submit Request',
                  isLoading: withdrawalProvider.isSubmitting,
                  gradient: AppColors.goldGradient,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
