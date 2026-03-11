import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';

  static const String health = '/api/health';

  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return 'https://via.placeholder.com/500x200';
    if (url.startsWith('http')) return url;
    
    // Si c'est un chemin relatif, on enlève le /api du baseUrl pour pointer vers la racine du serveur
    String rootUrl = baseUrl.replaceAll('/api', '');
    return '$rootUrl/$url';
  }
}
