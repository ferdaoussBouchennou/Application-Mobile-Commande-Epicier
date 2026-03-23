import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/services/api_service.dart';
import '../../data/services/fcm_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoggedIn = false;
  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _store;
  bool _isLoading = false;
  bool _initialized = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get store => _store;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;

  String? get storeStatut => _store?['statut_inscription'];
  bool get needsSetup => _user?['role'] == 'EPICIER' && storeStatut == 'ACCEPTE';

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      _isLoggedIn = true;
      try {
        final response = await _apiService.get('/auth/me', token: _token);
        _user = response['user'];
        _store = response['store'];
      } catch (e) {
        debugPrint("Session restoration failed: $e");
        _token = null;
        _isLoggedIn = false;
        await prefs.remove('auth_token');
      }
      
      // Update FCM token silently
      if (_token != null) {
        FCMService().updateFCMToken(_token!);
      }
    }
    _initialized = true;
    notifyListeners();
  }

  /// Recharge profil utilisateur et boutique (ex. après complétion de l’inscription épicier).
  Future<void> refreshSession() async {
    if (_token == null) return;
    final response = await _apiService.get('/auth/me', token: _token);
    _user = response['user'];
    _store = response['store'];
    notifyListeners();
  }

  Future<bool> login(String email, String mdp) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'mdp': mdp,
      });

      _token = response['token'];
      _user = response['user'];
      _store = response['store'];
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);

      // Sync FCM token
      await FCMService().updateFCMToken(_token!);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> loginWithGoogle({
    Map<String, dynamic>? epicierData,
    List<int>? docBytes,
    String? docFilename,
  }) async {
    _setLoading(true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: dotenv.env['GOOGLE_CLIENT_ID'],
        serverClientId: kIsWeb ? null : dotenv.env['GOOGLE_CLIENT_ID'], // null sur le web car non supporté
        scopes: ['email', 'profile', 'openid'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        throw Exception("Erreur lors de la récupération des jetons Google");
      }

      final Map<String, dynamic> payload = {
        'idToken': idToken,
        'accessToken': accessToken,
      };
 
      if (epicierData != null) {
        payload.addAll(epicierData);
      }
 
      // Envoi du token au backend pour vérification et connexion/inscription
      dynamic response;
      if (docBytes != null && docFilename != null && docBytes.isNotEmpty) {
        response = await _apiService.postMultipart(
          '/auth/google',
          payload,
          files: {'document_verification': docBytes},
          filenames: {'document_verification': docFilename},
        );
      } else {
        response = await _apiService.post('/auth/google', payload);
      }

      _token = response['token'];
      _user = response['user'];
      _store = response['store'];
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);

      // Sync FCM token
      await FCMService().updateFCMToken(_token!);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> loginWithFacebook({
    Map<String, dynamic>? epicierData,
    List<int>? docBytes,
    String? docFilename,
  }) async {
    _setLoading(true);
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        _setLoading(false);
        return false;
      }

      final String accessToken = result.accessToken!.tokenString;

      final Map<String, dynamic> payload = {
        'accessToken': accessToken,
      };

      if (epicierData != null) {
        payload.addAll(epicierData);
      }

      dynamic response;
      if (docBytes != null && docFilename != null && docBytes.isNotEmpty) {
        response = await _apiService.postMultipart(
          '/auth/facebook',
          payload,
          files: {'document_verification': docBytes},
          filenames: {'document_verification': docFilename},
        );
      } else {
        response = await _apiService.post('/auth/facebook', payload);
      }

      _token = response['token'];
      _user = response['user'];
      _store = response['store'];
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await FCMService().updateFCMToken(_token!);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> loginWithInstagram({
    Map<String, dynamic>? epicierData,
    List<int>? docBytes,
    String? docFilename,
  }) async {
    _setLoading(true);
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        _setLoading(false);
        return false;
      }

      final String accessToken = result.accessToken!.tokenString;

      final Map<String, dynamic> payload = {
        'accessToken': accessToken,
      };

      if (epicierData != null) {
        payload.addAll(epicierData);
      }

      dynamic response;
      if (docBytes != null && docFilename != null && docBytes.isNotEmpty) {
        response = await _apiService.postMultipart(
          '/auth/instagram',
          payload,
          files: {'document_verification': docBytes},
          filenames: {'document_verification': docFilename},
        );
      } else {
        response = await _apiService.post('/auth/instagram', payload);
      }

      _token = response['token'];
      _user = response['user'];
      _store = response['store'];
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await FCMService().updateFCMToken(_token!);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> registerClient(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.post('/auth/register/client', data);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> registerEpicier(
    Map<String, dynamic> data, {
    List<int>? docBytes,
    String? docFilename,
  }) async {
    _setLoading(true);
    try {
      if (docBytes != null && docFilename != null && docBytes.isNotEmpty) {
        await _apiService.postMultipart(
          '/auth/register/epicier',
          data,
          files: {'document_verification': docBytes},
          filenames: {'document_verification': docFilename},
        );
      } else {
        await _apiService.post('/auth/register/epicier', data);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> verifyEmail(String email, String otp) async {
    _setLoading(true);
    try {
      await _apiService.post('/auth/verify-email', {'email': email, 'otp': otp});
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> resendOTP(String email) async {
    _setLoading(true);
    try {
      await _apiService.post('/auth/resend-otp', {'email': email});
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await _apiService.post('/auth/forgot-password', {'email': email});
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    _setLoading(true);
    try {
      await _apiService.post('/auth/reset-password', {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _apiService.put('/auth/update-profile', data, token: _token);
      _user = response['user'];
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    try {
      await _apiService.put('/auth/update-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }, token: _token);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  void markSetupComplete() {
    _store ??= <String, dynamic>{};
    _store!['statut_inscription'] = 'COMPLETE';
    notifyListeners();
  }

  void logout() async {
    _token = null;
    _user = null;
    _store = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
