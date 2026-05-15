import 'package:shared_preferences/shared_preferences.dart';

class ApiHelper {
  /// Obtiene el token de SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static String? _normalizeAuthToken(String? rawToken) {
    final token = (rawToken ?? '').trim();
    if (token.isEmpty) return null;

    final lower = token.toLowerCase();
    if (lower == 'null' || lower == 'undefined') return null;

    // Si el backend ya devuelve el token con prefijo Bearer, no lo duplicamos.
    if (lower.startsWith('bearer ')) return token;
    return 'Bearer $token';
  }

  /// Construye los headers con el token para enviar en solicitudes protegidas
  static Future<Map<String, String>> getHeadersWithAuth() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final auth = _normalizeAuthToken(token);
    if (auth != null) headers['Authorization'] = auth;
    return headers;
  }
}
