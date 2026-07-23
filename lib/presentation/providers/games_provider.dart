import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/game_model.dart';
import '../../data/repositories/games_repository.dart';

class GamesProvider extends ChangeNotifier {
  final GamesRepository _repository;

  GamesProvider({GamesRepository? repository}) : _repository = repository ?? GamesRepository();

  List<GameModel> games = [];
  Set<String> completedToday = {};
  bool isLoading = true;
  String? actionError;
  String? claimingGameId;

  StreamSubscription<List<GameModel>>? _gamesSub;
  StreamSubscription<Set<String>>? _completionSub;
  String? _boundUid;

  void bind(String uid) {
    if (_boundUid == uid) return;
    _boundUid = uid;
    isLoading = true;
    notifyListeners();

    _gamesSub?.cancel();
    _gamesSub = _repository.streamGames().listen((list) {
      games = list;
      isLoading = false;
      notifyListeners();
    });

    _completionSub?.cancel();
    _completionSub = _repository.streamCompletedGameIdsToday(uid).listen((ids) {
      completedToday = ids;
      notifyListeners();
    });
  }

  bool isCompleted(String gameId) => completedToday.contains(gameId);

  Future<bool> playGame(String uid, GameModel game) async {
    if (isCompleted(game.id)) {
      actionError = 'You have already claimed this reward.';
      notifyListeners();
      return false;
    }
    claimingGameId = game.id;
    actionError = null;
    notifyListeners();

    final result = await _repository.completeGame(uid: uid, game: game);

    claimingGameId = null;
    if (result.isFailure) {
      actionError = result.errorOrNull;
    }
    notifyListeners();
    return result.isSuccess;
  }

  void clearError() {
    actionError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _gamesSub?.cancel();
    _completionSub?.cancel();
    super.dispose();
  }
}
