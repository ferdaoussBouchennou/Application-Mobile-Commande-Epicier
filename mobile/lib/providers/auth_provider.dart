import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/services/api_service.dart';
import '../../data/services/fcm_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoggedIn = false;
  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _store;
  bool _isLoading = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get store => _store;
  bool get isLoading => _isLoading;

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
      notifyListeners();
      
      // Update FCM token silently
      FCMService().updateFCMToken(_token!);
    }
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

  Future<bool> loginWithGoogle({Map<String, dynamic>? epicierData}) async {
    _setLoading(true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: dotenv.env['GOOGLE_CLIENT_ID'],
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
      final response = await _apiService.post('/auth/google', payload);

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

  Future<bool> registerEpicier(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _apiService.post('/auth/register/epicier', data);
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

  void markSetupComplete() {
    if (_store != null) {
      _store!['statut_inscription'] = 'COMPLETE';
      notifyListeners();
    }
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
