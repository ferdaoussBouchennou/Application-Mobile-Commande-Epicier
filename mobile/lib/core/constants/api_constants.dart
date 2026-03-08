import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';

  static const String health = '/health';
  // Ajoute tes endpoints ici
}
