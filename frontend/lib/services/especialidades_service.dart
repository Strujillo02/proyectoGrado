import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/api_helper.dart'; 
import 'package:frontend/models/especialidades.dart';
import 'package:http/http.dart' as http;

class EspecialidadesService {
  //! se inicializa dotenv para cargar las variables de entorno
  final String baseUrl = dotenv.env['URL_API']!;

  //! getEspecialidades
  /// Obtiene una lista de especialidades desde la API.
  Future<List<Especialidades>> getEspecialidades() async {
    final headers = await ApiHelper.getHeadersWithAuth();

    final response = await http.get(
      Uri.parse('${baseUrl}especialidad/v1/get'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(
        response.body,
      ); // Es directamente una lista
      return data.map((item) => Especialidades.fromJson(item)).toList();
    } else {
      throw Exception(
        'Error al cargar Especialidades. Código: ${response.statusCode}',
      );
    }
  }

  //! updateEspecialidades
  /// Actualiza una especialidad en la API.
  /// Recibe un objeto especialidades
  /// Devuelve true si la actualización fue exitosa, false en caso contrario.
  Future<bool> updateEspecialidades(Especialidades est) async {
    try {
      final uri = Uri.parse('${baseUrl}especialidad/v1/update');
      final headers =
          await ApiHelper.getHeadersWithAuth(); // Incluye Content-Type y Authorization
      final body = jsonEncode(est.toJson()); // Convierte el objeto a JSON

      final response = await http.put(uri, headers: headers, body: body);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al actualizar especialidades: $e');
    }
  }

  //! createEspecialidades
  /// Crea un nuevo especialidad en la API.
  /// Recibe un objeto especialidades
  /// Devuelve true si la creación fue exitosa, false en caso contrario.
  Future<bool> createEspecialidades(Especialidades est) async {
    try {
      final uri = Uri.parse('${baseUrl}especialidad/v1/create');
      final headers =
          await ApiHelper.getHeadersWithAuth(); // Incluye Content-Type y Authorization
      final body = jsonEncode(est.toJson()); // Convierte el objeto a JSON

      final response = await http.post(uri, headers: headers, body: body);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al crear especialidad: $e');
    }
  }

  //! deleteEspecialidad
  /// Elimina un especialidad de la API.
  /// Realiza un borrado lógico de una especialidad por ID.
  /// Retorna true si fue exitoso.
  Future<bool> deleteEspecialidad(int id) async {
    try {
      final headers = await ApiHelper.getHeadersWithAuth();
      final response = await http.delete(
        Uri.parse('${baseUrl}especialidad/v1/delete/$id'),
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
      throw Exception('Error al eliminar especialidad: $e');
    }
  }
}
