import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/services/api_service.dart';

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

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    // Simplification : si on a un token, on considère être connecté. 
    // Dans une vraie application, on ferait un appel /api/auth/me avec ce token.
    if (_token != null) {
      _isLoggedIn = true;
      notifyListeners();
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

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: dotenv.env['GOOGLE_CLIENT_ID'],
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false; // Annulé par l'utilisateur
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception("Erreur lors de la récupération du token Google");
      }

      // Envoi du token au backend pour vérification et connexion/inscription
      final response = await _apiService.post('/auth/google', {
        'idToken': idToken,
      });

      _token = response['token'];
      _user = response['user'];
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);

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
      return true; // Succès de l'inscription
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
      return true; // Succès de l'inscription
    } catch (e) {
      _setLoading(false);
      rethrow;
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
