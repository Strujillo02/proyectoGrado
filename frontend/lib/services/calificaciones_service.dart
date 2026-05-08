import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/api_helper.dart';
import 'package:frontend/models/calificaciones.dart';
import 'package:http/http.dart' as http;

class CalificacionesService {
  //! se inicializa dotenv para cargar las variables de entorno
  final String baseUrl = dotenv.env['URL_API']!;

  //! createCalificaciones
  /// Crea un nueva calificación en la API.
  /// Recibe un objeto calificaciones
  /// Devuelve true si la creación fue exitosa, false en caso contrario.
  Future<bool> createCalificaciones(Calificaciones cal) async {
    try {
      final uri = Uri.parse('${baseUrl}calificacion/v1/create');
      final headers = await ApiHelper
          .getHeadersWithAuth(); // Incluye Content-Type y Authorization
      final body = jsonEncode(cal.toJson()); // Convierte el objeto a JSON

      final response = await http.post(uri, headers: headers, body: body);

      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } catch (e) {
      throw Exception('Error al crear calificación: $e');
    }
  }
}
