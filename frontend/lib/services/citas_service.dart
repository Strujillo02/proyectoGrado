
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/api_helper.dart';
import 'package:frontend/models/citas.dart';
import 'package:http/http.dart' as http;

class CitasService {
  //! se inicializa dotenv para cargar las variables de entorno
  final String baseUrl = dotenv.env['URL_API']!;

  //! getCitas
  /// Obtiene una lista de citas desde la API.
  Future<List<Citas>> getCitas() async {
    final headers = await ApiHelper.getHeadersWithAuth();

    final response = await http.get(
      Uri.parse('${baseUrl}citas/v1/get'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(
        response.body,
      ); // Es directamente una lista
      return data.map((item) => Citas.fromJson(item)).toList();
    } else {
      throw Exception(
        'Error al cargar Citas. Código: ${response.statusCode}',
      );
    }
  }


  //! updateCitas
  /// Actualiza una cita en la API.
  /// Recibe un objeto citas
  /// Devuelve true si la actualización fue exitosa, false en caso contrario.
  Future<bool> updateCitas(Citas est) async {
    try {
      final uri = Uri.parse('${baseUrl}cita/v1/update');
      final headers =
          await ApiHelper.getHeadersWithAuth(); // Incluye Content-Type y Authorization
      final body = jsonEncode(est.toJson()); // Convierte el objeto a JSON

      final response = await http.put(uri, headers: headers, body: body);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al actualizar citas: $e');
    }
  }

  //! createCitas
  /// Crea un nuevo Cita en la API.
  /// Recibe un objeto Citas
  /// Devuelve true si la creación fue exitosa, false en caso contrario.
  Future<bool> createCitas(Citas est) async {
    try {
      final uri = Uri.parse('${baseUrl}cita/v1/create');
      final headers =
          await ApiHelper.getHeadersWithAuth(); // Incluye Content-Type y Authorization
      final body = jsonEncode(est.toJson()); // Convierte el objeto a JSON

      final response = await http.post(uri, headers: headers, body: body);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al crear cita: $e');
    }
  }

  //! deleteCitas
  /// Elimina un Citas de la API.
  /// Realiza un borrado lógico de una Cita por ID.
  /// Retorna true si fue exitoso.
  Future<bool> deleteCita(int id) async {
    try {
      final headers = await ApiHelper.getHeadersWithAuth();
      final response = await http.delete(
        Uri.parse('${baseUrl}cita/v1/delete/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Simplemente verifica el status
        return true;
      } else {
        // Opcional: imprimir body si no fue exitoso
        print('Error al eliminar: ${response.body}');
        return false;
      }
    } catch (e) {
      throw Exception('Error al eliminar cita: $e');
    }
  }
}
