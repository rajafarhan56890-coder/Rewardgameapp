import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/config_model.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationsProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationsProvider({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  List<NotificationModel> notifications = [];
  int unreadCount = 0;
  bool isLoading = true;

  StreamSubscription<List<NotificationModel>>? _sub;
  StreamSubscription<int>? _countSub;
  String? _boundUid;

  void bind(String uid) {
    if (_boundUid == uid) return;
    _boundUid = uid;
    _sub?.cancel();
    _sub = _repository.streamNotifications(uid).listen((list) {
      notifications = list;
      isLoading = false;
      notifyListeners();
    });
    _countSub?.cancel();
    _countSub = _repository.streamUnreadCount(uid).listen((count) {
      unreadCount = count;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String uid, String id) => _repository.markAsRead(uid, id);
  Future<void> markAllAsRead(String uid) => _repository.markAllAsRead(uid);

  @override
  void dispose() {
    _sub?.cancel();
    _countSub?.cancel();
    super.dispose();
  }
}
