import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// FCMService — handles Firebase Cloud Messaging token registration and message reception.
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final ApiService _apiService = ApiService();
  
  FirebaseMessaging? get _fcm {
    try {
      return FirebaseMessaging.instance;
    } catch (e) {
      debugPrint('[FCMService] FirebaseMessaging.instance not available: $e');
      return null;
    }
  }

  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        debugPrint('[FCMService] Standby on web (configuration missing).');
        return;
      }

      final fcmInstance = _fcm;
      if (fcmInstance == null) return;

      // Request permissions
      NotificationSettings settings = await fcmInstance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[FCMService] User granted permission');
        
        // Get token
        String? token = await fcmInstance.getToken();
        if (token != null) {
          await saveToken(token);
        }
      }

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCMService] Got a message whilst in the foreground!');
        if (message.notification != null) {
          debugPrint('[FCMService] Title: ${message.notification?.title}');
        }
      });
      
    } catch (e) {
      debugPrint('[FCMService] initialize() error: $e');
    }
  }

  /// Syncs the local FCM token with the backend.
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

  /// Saves the token locally for later syncing.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    debugPrint('[FCMService] FCM token saved locally: $token');
  }
}
