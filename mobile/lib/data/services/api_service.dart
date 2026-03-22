import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';

class ApiService {
  final String _baseUrl = ApiConstants.baseUrl;

  Map<String, String> _headers({String? token, bool omitContentType = false}) {
    final map = <String, String>{};
    if (token != null) map['Authorization'] = 'Bearer $token';
    if (!omitContentType) map['Content-Type'] = 'application/json';
    return map;
  }

  Future<dynamic> get(String endpoint, {String? token}) async {
    try {
      final headers = _headers(token: token);
      print('ApiService DEBUG: GET $_baseUrl$endpoint headers=$headers');
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      Logger.error('GET $endpoint → $e');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers(token: token),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      Logger.error('POST $endpoint → $e');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body, {String? token}) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers(token: token),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      Logger.error('PUT $endpoint → $e');
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body, {String? token}) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers(token: token),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      Logger.error('PATCH $endpoint → $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {String? token}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers(token: token),
      );
      return _handleResponse(response);
    } catch (e) {
      Logger.error('DELETE $endpoint → $e');
      rethrow;
    }
  }

  Future<String> uploadStoreImage({
    required String token,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/epicier/upload-store-image');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body;
        String msg = 'Erreur ${response.statusCode}';
        try {
          final j = jsonDecode(body) as Map<String, dynamic>;
          if (j['message'] != null) msg = j['message'] as String;
        } catch (_) {}
        throw Exception(msg);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final path = data['image_url'] as String?;
      if (path == null || path.isEmpty) throw Exception('Réponse invalide');
      return path;
    } catch (e) {
      Logger.error('uploadStoreImage → $e');
      rethrow;
    }
  }

  /// Upload icône catégorie pour l'admin.
  Future<String> uploadCategoryIconAdmin({
    required String token,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/categories/upload-icon');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body;
        String msg = 'Erreur ${response.statusCode}';
        try {
          final j = jsonDecode(body) as Map<String, dynamic>;
          if (j['message'] != null) msg = j['message'] as String;
        } catch (_) {}
        throw Exception(msg);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final path = data['image_url'] as String?;
      if (path == null || path.isEmpty) throw Exception('Réponse invalide');
      return path;
    } catch (e) {
      Logger.error('uploadCategoryIconAdmin → $e');
      rethrow;
    }
  }

  Future<String> uploadProductImage({
    required String token,
    required int categorieId,
    required List<int> bytes,
    required String filename,
    String? productName,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/epicier/products/upload-image');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['categorie_id'] = categorieId.toString();
      if (productName != null && productName.trim().isNotEmpty) {
        request.fields['nom'] = productName.trim();
      }
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body;
        String msg = 'Erreur ${response.statusCode}';
        try {
          final j = jsonDecode(body) as Map<String, dynamic>;
          if (j['message'] != null) msg = j['message'] as String;
        } catch (_) {}
        throw Exception(msg);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final path = data['image_principale'] as String?;
      if (path == null || path.isEmpty) throw Exception('Réponse invalide');
      return path;
    } catch (e) {
      Logger.error('uploadProductImage → $e');
      rethrow;
    }
  }

  /// Upload image produit pour l'admin (même logique, route admin).
  Future<String> uploadProductImageAdmin({
    required String token,
    required int categorieId,
    required List<int> bytes,
    required String filename,
    String? productName,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/admin/products/upload-image');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['categorie_id'] = categorieId.toString();
      if (productName != null && productName.trim().isNotEmpty) {
        request.fields['nom'] = productName.trim();
      }
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body;
        String msg = 'Erreur ${response.statusCode}';
        try {
          final j = jsonDecode(body) as Map<String, dynamic>;
          if (j['message'] != null) msg = j['message'] as String;
        } catch (_) {}
        throw Exception(msg);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final path = data['image_principale'] as String?;
      if (path == null || path.isEmpty) throw Exception('Réponse invalide');
      return path;
    } catch (e) {
      Logger.error('uploadProductImageAdmin → $e');
      rethrow;
    }
  }

  Future<dynamic> postMultipart(
    String endpoint,
    Map<String, dynamic> fields, {
    String? token,
    Map<String, List<int>>? files, // Map of fieldName -> bytes
    Map<String, String>? filenames, // Map of fieldName -> filename
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      fields.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      if (files != null) {
        files.forEach((field, bytes) {
          final name = filenames?[field] ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
          request.files.add(http.MultipartFile.fromBytes(field, bytes, filename: name));
        });
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } catch (e) {
      Logger.error('POST MULTIPART $endpoint → $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDashboardStats(String token) async {
    final response = await get('/admin/dashboard/stats', token: token);
    return response as Map<String, dynamic>;
  }

  Future<dynamic> putMultipart(
    String endpoint,
    Map<String, dynamic> fields, {
    String? token,
    Map<String, List<int>>? files,
    Map<String, String>? filenames,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('PUT', uri);
      
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      fields.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      if (files != null) {
        files.forEach((field, bytes) {
          final name = filenames?[field] ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
          request.files.add(http.MultipartFile.fromBytes(field, bytes, filename: name));
        });
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } catch (e) {
      Logger.error('PUT MULTIPART $endpoint → $e');
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }
}
