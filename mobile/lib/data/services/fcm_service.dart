import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// FCMService — handles Firebase Cloud Messaging token registration.
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final ApiService _apiService = ApiService();

  Future<void> initialize() async {
    try {
      debugPrint('[FCMService] initialize() — notifications are simulated on web.');
    } catch (e) {
      debugPrint('[FCMService] initialize() error: $e');
    }
  }

  Future<void> updateFCMToken(String authToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');

      if (fcmToken == null) {
        debugPrint('[FCMService] No FCM token stored locally.');
        return;
      }

      await _apiService.post(
        '/auth/fcm-token',
        {'fcm_token': fcmToken},
        token: authToken,
      );

      debugPrint('[FCMService] FCM token synced with backend.');
    } catch (e) {
      debugPrint('[FCMService] updateFCMToken error: $e');
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    debugPrint('[FCMService] FCM token saved locally.');
  }
}
