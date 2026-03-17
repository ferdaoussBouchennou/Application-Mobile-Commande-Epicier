import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    final token = await _getToken();
    final data = await _apiService.get('/notifications', token: token);
    return (data as List).map((j) => NotificationModel.fromJson(j)).toList();
  }

  Future<void> markRead(int id) async {
    final token = await _getToken();
    await _apiService.patch('/notifications/$id/read', {}, token: token);
  }

  Future<void> markAllRead() async {
    final token = await _getToken();
    await _apiService.patch('/notifications/read-all', {}, token: token);
  }

  Future<int> unreadCount() async {
    final token = await _getToken();
    final data = await _apiService.get('/notifications/unread-count', token: token);
    return data['count'] ?? 0;
  }
}
