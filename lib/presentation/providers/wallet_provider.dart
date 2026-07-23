import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/config_model.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/user_repository.dart';

class WalletProvider extends ChangeNotifier {
  final WalletRepository _walletRepository;
  final UserRepository _userRepository;

  WalletProvider({WalletRepository? walletRepository, UserRepository? userRepository})
      : _walletRepository = walletRepository ?? WalletRepository(),
        _userRepository = userRepository ?? UserRepository();

  List<TransactionModel> transactions = [];
  AppConfigModel appConfig = AppConfigModel.fallback();
  bool isLoading = true;

  StreamSubscription<List<TransactionModel>>? _txSub;
  StreamSubscription<AppConfigModel>? _configSub;
  String? _boundUid;

  void bind(String uid) {
    if (_boundUid == uid) return;
    _boundUid = uid;
    isLoading = true;
    notifyListeners();

    _txSub?.cancel();
    _txSub = _walletRepository.streamTransactions(uid).listen((tx) {
      transactions = tx;
      isLoading = false;
      notifyListeners();
    });

    _configSub?.cancel();
    _configSub = _userRepository.streamAppConfig().listen((config) {
      appConfig = config;
      notifyListeners();
    });
  }

  List<TransactionModel> get recentFive => transactions.take(5).toList();

  List<TransactionModel> get coinTransactions =>
      transactions.where((t) => t.currency == TxCurrency.coins).toList();

  List<TransactionModel> get cashTransactions =>
      transactions.where((t) => t.currency == TxCurrency.cashPoints).toList();

  void unbind() {
    _txSub?.cancel();
    _configSub?.cancel();
    _boundUid = null;
    transactions = [];
  }

  @override
  void dispose() {
    _txSub?.cancel();
    _configSub?.cancel();
    super.dispose();
  }
}
