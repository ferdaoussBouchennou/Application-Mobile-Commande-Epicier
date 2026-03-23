import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

  static const String health = '/api/health';

  /// Construit une URL absolue pour les fichiers sous [uploads/] (serving Express à la racine, pas sous /api).
  /// Accepte les chemins enregistrés en base : `uploads/...`, éventuellement avec préfixe `backend/` par erreur.
  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'https://via.placeholder.com/500x200';
    }
    var path = url.trim();
    if (path.isEmpty) {
      return 'https://via.placeholder.com/500x200';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    path = path.replaceAll('\\', '/');
    if (path.toLowerCase().startsWith('backend/')) {
      path = path.substring('backend/'.length);
    }
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    var rootUrl = baseUrl.replaceAll('/api', '');
    while (rootUrl.endsWith('/')) {
      rootUrl = rootUrl.substring(0, rootUrl.length - 1);
    }
    return '$rootUrl/$path';
  }
}
