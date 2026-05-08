import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/api_helper.dart';
import 'package:frontend/models/citas.dart';
import 'package:http/http.dart' as http;

class CitasService {
  //! se inicializa dotenv para cargar las variables de entorno
  final String baseUrl = dotenv.env['URL_API']!;

  bool _isSuccessStatus(int statusCode) {
    return statusCode == 200 ||
        statusCode == 201 ||
        statusCode == 202 ||
        statusCode == 204;
  }

  String _estadoDesdeRespuesta(String respuesta) {
    final r = respuesta.trim().toUpperCase();
    if (r == 'ACEPTADA' || r == 'CONFIRMADA' || r == 'COMPLETADA') {
      return 'CONFIRMADA';
    }
    if (r == 'RECHAZADA' || r == 'CANCELADA') {
      return 'CANCELADA';
    }
    return 'PENDIENTE';
  }

  Future<List<Citas>> _parseCitasResponse(http.Response response) async {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((e) => Citas.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Formato inesperado en respuesta de citas');
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  //! getCitas
  /// Obtiene una lista de citas desde la API.
  Future<List<Citas>> getCitas() async {
    final headers = await ApiHelper.getHeadersWithAuth();

    // Algunos backends exponen citas/v1/get, otros cita/v1/get.
    final endpoints = <String>['citas/v1/get', 'cita/v1/get'];
    final errores = <String>[];

    for (final ep in endpoints) {
      try {
        final response =
            await http.get(Uri.parse('${baseUrl}$ep'), headers: headers);
        return await _parseCitasResponse(response);
      } catch (e) {
        errores.add('$ep -> $e');
      }
    }

    throw Exception('Error al cargar citas. Intentos: ${errores.join(' | ')}');
  }

  Future<List<Citas>> getCitasPorUsuarioid(int userId) async {
    final headers = await ApiHelper.getHeadersWithAuth();
    final uri = Uri.parse('${baseUrl}cita/v1/citasporusuario/$userId');
    final response = await http.get(uri, headers: headers);
    try {
      return await _parseCitasResponse(response);
    } catch (_) {
      throw Exception(
          'Error al obtener citas del usuario (code ${response.statusCode})');
    }
  }

  /// Obtiene las citas de un usuario específico por su id.
  /// Endpoint esperado: cita/v1/get/{userId}
  Future<List<Citas>> getCitasPorUsuario(int userId) async {
    final headers = await ApiHelper.getHeadersWithAuth();
    final uri = Uri.parse('${baseUrl}cita/v1/get/$userId');
    final response = await http.get(uri, headers: headers);
    try {
      return await _parseCitasResponse(response);
    } catch (_) {
      throw Exception(
          'Error al obtener citas del usuario (code ${response.statusCode})');
    }
  }

  /// Carga citas visibles para un usuario intentando varios endpoints.
  /// Si los endpoints por usuario fallan (403/404), usa getCitas() y filtra localmente.
  Future<List<Citas>> getCitasParaUsuarioConFallback({
    required int userId,
    required bool comoMedico,
  }) async {
    final errores = <String>[];

    try {
      final lista = await getCitasPorUsuario(userId);
      if (lista.isNotEmpty) return lista;
      errores.add('cita/v1/get/$userId -> respuesta vacia');
    } catch (e) {
      errores.add('cita/v1/get/$userId -> $e');
    }

    try {
      final lista = await getCitasPorUsuarioid(userId);
      if (lista.isNotEmpty) return lista;
      errores.add('cita/v1/citasporusuario/$userId -> respuesta vacia');
    } catch (e) {
      errores.add('cita/v1/citasporusuario/$userId -> $e');
    }

    try {
      final todas = await getCitas();
      return todas.where((cita) {
        if (comoMedico) {
          return cita.medico.usuario.id == userId;
        }
        return cita.usuario.id == userId;
      }).toList();
    } catch (e) {
      errores.add('getCitas() -> $e');
    }

    throw Exception('No se pudieron cargar citas. ${errores.join(' | ')}');
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

      return _isSuccessStatus(response.statusCode);
    } catch (e) {
      throw Exception('Error al actualizar citas: $e');
    }
  }

  /// Marca una cita como completada (equivalente funcional a confirmada para este backend).
  /// Usa payload compacto con IDs para evitar fallos por objetos anidados completos.
  Future<bool> marcarComoCompletada(Citas cita) async {
    if (cita.id == null) return false;

    try {
      final uri = Uri.parse('${baseUrl}cita/v1/update');
      final headers = await ApiHelper.getHeadersWithAuth();

      final basePayload = {
        'id': cita.id,
        'especialidad': {'id': cita.especialidad.id},
        'medico': {'id': cita.medico.id},
        'usuario': {'id': cita.usuario.id},
        'motivo_consulta': cita.motivo_consulta,
        'tipo_consulta': cita.tipo_consulta,
        'fecha_cita': cita.fecha_cita.toUtc().toIso8601String(),
        'latitud': cita.latitud,
        'longitud': cita.longitud,
        'precio': cita.precio,
        'fecha_registro': cita.fecha_registro.toUtc().toIso8601String(),
        if (cita.respuesta_medico.isNotEmpty)
          'respuesta_medico': cita.respuesta_medico,
      };

      // Algunos backends usan CONFIRMADA y otros COMPLETADA para el estado final.
      for (final estado in const ['CONFIRMADA', 'COMPLETADA']) {
        final body = jsonEncode({...basePayload, 'estado': estado});
        final response = await http.put(uri, headers: headers, body: body);
        if (_isSuccessStatus(response.statusCode)) {
          return true;
        }
        debugPrint(
            'marcarComoCompletada intento $estado falló: ${response.statusCode} ${response.body}');
      }

      final citaActualizada = Citas(
        id: cita.id,
        especialidad: cita.especialidad,
        fecha_registro: cita.fecha_registro,
        motivo_consulta: cita.motivo_consulta,
        precio: cita.precio,
        estado: 'CONFIRMADA',
        tipo_consulta: cita.tipo_consulta,
        fecha_cita: cita.fecha_cita,
        latitud: cita.latitud,
        longitud: cita.longitud,
        medico: cita.medico,
        usuario: cita.usuario,
        respuesta_medico: cita.respuesta_medico,
      );

      if (await updateCitas(citaActualizada)) {
        return true;
      }

      // Fallback al endpoint de respuesta del medico, usado ya en notificaciones.
      return await responderCita(citaId: cita.id!, respuesta: 'Aceptada');
    } catch (e) {
      throw Exception('Error al marcar cita como completada: $e');
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
        debugPrint('Error al eliminar: ${response.body}');
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
      final updateUri = Uri.parse('${baseUrl}cita/v1/update');
      final estado = _estadoDesdeRespuesta(respuesta);

      // Prioriza el endpoint actualizado del backend (PUT cita/v1/update)
      final updateBody = jsonEncode({
        'id': citaId,
        'estado': estado,
        'respuesta_medico': respuesta,
      });
      final updateResponse =
          await http.put(updateUri, headers: headers, body: updateBody);
      if (_isSuccessStatus(updateResponse.statusCode)) {
        return true;
      }
      debugPrint(
          'responderCita update falló: ${updateResponse.statusCode} ${updateResponse.body}');

      // Fallback legacy
      final uri = Uri.parse(
          '${baseUrl}cita/v1/citas/$citaId/respuesta?respuesta=${Uri.encodeComponent(respuesta)}');

      final response = await http.put(uri, headers: headers);
      return _isSuccessStatus(response.statusCode);
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
