import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/api_helper.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final String baseUrl = dotenv.env['URL_API']!;

  Future<bool> sendTestToToken({
    required String token,
    String title = 'Prueba',
    String body = 'Mensaje de prueba desde la app',
  }) async {
    final headers = await ApiHelper.getHeadersWithAuth();
    final uri = Uri.parse('${baseUrl}notification/v1/test'); // Ajusta si tu endpoint es otro

    final res = await http.post(
      uri,
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'title': title, 'body': body}),
    );

    return res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
  }
}