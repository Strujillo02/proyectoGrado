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
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}