import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/game_model.dart';
import '../../data/repositories/cash_tasks_repository.dart';

class CashTasksProvider extends ChangeNotifier {
  final CashTasksRepository _repository;

  CashTasksProvider({CashTasksRepository? repository})
      : _repository = repository ?? CashTasksRepository();

  List<CashTaskModel> tasks = [];
  Set<String> completedIds = {};
  List<Map<String, dynamic>> pendingCompletions = [];
  bool isLoading = true;
  String? actionError;
  String? claimingTaskId;

  StreamSubscription<List<CashTaskModel>>? _tasksSub;
  StreamSubscription<Set<String>>? _completionSub;
  StreamSubscription<List<Map<String, dynamic>>>? _pendingSub;
  String? _boundUid;

  void bind(String uid) {
    if (_boundUid == uid) return;
    _boundUid = uid;
    isLoading = true;
    notifyListeners();

    _tasksSub?.cancel();
    _tasksSub = _repository.streamCashTasks().listen((list) {
      tasks = list;
      isLoading = false;
      notifyListeners();
    });

    _completionSub?.cancel();
    _completionSub = _repository.streamCompletedTaskIds(uid).listen((ids) {
      completedIds = ids;
      notifyListeners();
    });

    _pendingSub?.cancel();
    _pendingSub = _repository.streamPendingCompletions(uid).listen((list) {
      pendingCompletions = list;
      notifyListeners();
    });
  }

  bool isCompleted(String taskId) => completedIds.contains(taskId);

  Future<bool> completeTask(String uid, CashTaskModel task) async {
    if (isCompleted(task.id)) {
      actionError = 'You have already claimed this reward.';
      notifyListeners();
      return false;
    }
    claimingTaskId = task.id;
    actionError = null;
    notifyListeners();

    final result = await _repository.completeTask(uid: uid, task: task);

    claimingTaskId = null;
    if (result.isFailure) actionError = result.errorOrNull;
    notifyListeners();
    return result.isSuccess;
  }

  void clearError() {
    actionError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    _completionSub?.cancel();
    _pendingSub?.cancel();
    super.dispose();
  }
}
