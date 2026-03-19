import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';
import '../data/services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.lue).length;

  Future<void> fetchNotifications(String? token) async {
    if (token == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/notifications', token: token);
      _notifications = (data as List)
          .map((j) => NotificationModel.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> markAsRead(String? token, int id) async {
    try {
      await _api.patch('/notifications/$id/read', {}, token: token);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].lue = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String? token) async {
    try {
      await _api.patch('/notifications/read-all', {}, token: token);
      for (var n in _notifications) {
        n.lue = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
