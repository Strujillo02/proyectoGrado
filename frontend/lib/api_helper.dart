import 'package:shared_preferences/shared_preferences.dart';

class ApiHelper {
  /// Obtiene el token de SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Construye los headers con el token para enviar en solicitudes protegidas
  static Future<Map<String, String>> getHeadersWithAuth() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty && token.toLowerCase() != 'null') {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
