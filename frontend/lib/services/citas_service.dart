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
      final headers = await ApiHelper
          .getHeadersWithAuth(); // Incluye Content-Type y Authorization
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
      final headers = await ApiHelper
          .getHeadersWithAuth(); // Incluye Content-Type y Authorization
      // Construye el payload que espera la API (IDs para relaciones y campos primitivos)
      final body = jsonEncode({
        'especialidad': {'id': est.especialidad.id},
        'medico': {'id': est.medico.id},
        'usuario': {'id': est.usuario.id},
        'motivo_consulta': est.motivo_consulta,
        'tipo_consulta': est.tipo_consulta,
        'fecha_cita': est.fecha_cita.toIso8601String(),
        'latitud': est.latitud,
        'longitud': est.longitud,
        'precio': est.precio,
        'estado': est.estado,
        'fecha_registro': est.fecha_registro.toIso8601String(),
        if (est.respuesta_medico.isNotEmpty)
          'respuesta_medico': est.respuesta_medico,
      });

      final response = await http.post(uri, headers: headers, body: body);

      return response.statusCode == 200 || response.statusCode == 201;
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

  /// Responder una cita (Aceptada/Rechazada) usando el endpoint del backend
  Future<bool> responderCita({
    required int citaId,
    required String respuesta, // 'Aceptada' o 'Rechazada'
  }) async {
    try {
      final headers = await ApiHelper.getHeadersWithAuth();
      final uri = Uri.parse(
          '${baseUrl}cita/v1/citas/$citaId/respuesta?respuesta=${Uri.encodeComponent(respuesta)}');

      final response = await http.put(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al responder cita: $e');
    }
  }

  /// Crear cita enviando solo IDs y campos simples (más sencillo desde la UI)
  Future<bool> crearCitaSimple({
    required int especialidadId,
    required int medicoId,
    required int usuarioId,
    required String motivoConsulta,
    required String tipoConsulta,
    required DateTime fechaCita,
    required String direccion,
    required String medioPago,
    double latitud = 0.0,
    double longitud = 0.0,
    double precio = 0.0,
    String estado = 'PENDIENTE',
  }) async {
    try {
      final uri = Uri.parse('${baseUrl}cita/v1/create');
      final headers = await ApiHelper.getHeadersWithAuth();
      final now = DateTime.now().toUtc();
      // Normalizar posibles enums a formato esperado por el backend
      final tipoNormalizado = (tipoConsulta).toUpperCase();
      final estadoNormalizado = (estado).toUpperCase();
      final medioPagoNormalizado = (medioPago).toUpperCase();
      final body = jsonEncode({
        'especialidad': {'id': especialidadId},
        'medico': {'id': medicoId},
        'usuario': {'id': usuarioId},
        'motivo_consulta': motivoConsulta,
        'tipo_consulta': tipoNormalizado,
        'fecha_cita': fechaCita.toUtc().toIso8601String(),
        'latitud': latitud,
        'longitud': longitud,
        'direccion': direccion,
        'medio_pago': medioPagoNormalizado,
        'precio': precio,
        'estado': estadoNormalizado,
        'fecha_registro': now.toIso8601String(),
      });

      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 200 || response.statusCode == 201) return true;
      final details = response.body.isNotEmpty ? response.body : 'sin cuerpo';
      if (response.statusCode == 401) {
        throw Exception(
            'No autorizado (401). Inicia sesión nuevamente. Detalle: $details');
      }
      if (response.statusCode == 403) {
        throw Exception(
            'Permisos insuficientes (403). Verifica tu rol o el token. Detalle: $details');
      }
      throw Exception('Error al crear cita (${response.statusCode}): $details');
    } catch (e) {
      throw Exception('Error al crear cita simple: $e');
    }
  }
}
