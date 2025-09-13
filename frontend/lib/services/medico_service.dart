import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/api_helper.dart';
import 'package:frontend/models/medico.dart';
import 'package:http/http.dart' as http;

class MedicoService {
  //! se inicializa dotenv para cargar las variables de entorno
  final String baseUrl = dotenv.env['URL_API']!;

  //! getMedicos
  /// Obtiene una lista de medicos desde la API.
  Future<List<Medico>> getMedicos() async {
    final headers = await ApiHelper.getHeadersWithAuth();

    final response = await http.get(
      Uri.parse('${baseUrl}medico/v1/get'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      // Decodifica la respuesta JSON directamente como una lista
      final List<dynamic> data = jsonDecode(response.body);

      // Convierte cada elemento de la lista en un objeto Medico
      return data.map((item) => Medico.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar medicos: ${response.statusCode}');
    }
  }

  /// Obtiene el valor de la consulta (COP) para un médico específico.
  /// Intenta parsear diferentes formatos de respuesta:
  /// - JSON con número directo
  /// - JSON con campo 'valor'
  /// - Texto como "38.000" o "38000"
  Future<int> getValorConsultaCOP(int medicoId) async {
    final headers = await ApiHelper.getHeadersWithAuth();
    final uri = Uri.parse('${baseUrl}medico/v1/getValorConsulta/$medicoId');
    final hasAuth = headers['Authorization'] != null &&
        headers['Authorization']!.isNotEmpty;
    // ignore: avoid_print
    print('GET ${uri.path} -> Authorization presente: $hasAuth');
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      if (resp.statusCode == 401) {
        throw Exception('No autorizado (401). Inicia sesión nuevamente.');
      }
      if (resp.statusCode == 403) {
        throw Exception(
            'Permiso denegado (403). Verifica que tu rol tenga acceso al endpoint GET /medico/v1/getValorConsulta/{id} en el backend.');
      }
      throw Exception(
          'Error al obtener valor de consulta (${resp.statusCode}): ${resp.body}');
    }

    final body = resp.body.trim();
    // 1) Intento JSON directo
    try {
      final decoded = jsonDecode(body);
      if (decoded is num) {
        return decoded.round();
      }
      if (decoded is String) {
        final digits = decoded.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) return int.parse(digits);
      }
      if (decoded is Map<String, dynamic>) {
        final v = decoded['valor'] ?? decoded['precio'] ?? decoded['amount'];
        if (v is num) return v.round();
        if (v is String) {
          final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.isNotEmpty) return int.parse(digits);
        }
      }
    } catch (_) {
      // no-op, seguimos con parseo de texto
    }

    // 2) Texto plano tipo "38.000" -> 38000
    final digits = body.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) return int.parse(digits);

    throw Exception('Formato de valor de consulta no reconocido: $body');
  }

  /// Versión que usa el usuario_id (FK en tabla medicos) para consultar el valor.
  Future<int> getValorConsultaPorUsuario(int usuarioId) async {
    final headers = await ApiHelper.getHeadersWithAuth();
    final uri = Uri.parse('${baseUrl}medico/v1/getValorConsulta/$usuarioId');
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception(
          'Error al obtener valor de consulta (${resp.statusCode}): ${resp.body}');
    }

    final body = resp.body.trim();
    try {
      final decoded = jsonDecode(body);
      if (decoded is num) return decoded.round();
      if (decoded is String) {
        final digits = decoded.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) return int.parse(digits);
      }
      if (decoded is Map<String, dynamic>) {
        final v = decoded['valor'] ?? decoded['precio'] ?? decoded['amount'];
        if (v is num) return v.round();
        if (v is String) {
          final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.isNotEmpty) return int.parse(digits);
        }
      }
    } catch (_) {}

    final digits = body.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) return int.parse(digits);
    throw Exception('Formato de valor de consulta no reconocido: $body');
  }

  //Obtener medicos por id
  Future<Medico> getMedico(int id) async {
    final headers = await ApiHelper.getHeadersWithAuth();

    final response = await http.get(
      Uri.parse('${baseUrl}medico/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      // Decodifica la respuesta JSON
      final json = jsonDecode(response.body);

      // Convierte el JSON en un objeto medico
      return Medico.fromJson(json);
    } else {
      // Lanza una excepción si el código de estado no es 200
      throw Exception('Error al obtener el medico: ${response.statusCode}');
    }
  }

  //! updateMedicos
  /// Actualiza un medico en la API.
  /// Recibe un objeto medicos
  /// Devuelve true si la actualización fue exitosa, false en caso contrario.
  Future<bool> updateMedicos(Medico est) async {
    try {
      final uri = Uri.parse('${baseUrl}medico/v1/update');
      final headers = await ApiHelper.getHeadersWithAuth();

      final body = jsonEncode(est.toJson());

      final response = await http.put(uri, headers: headers, body: body);

      if (response.statusCode != 200) {}

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al actualizar médicos: $e');
    }
  }

  //! createMedicos
  /// Crea un nuevo medico en la API.
  /// Recibe un objeto medico
  /// Devuelve true si la creación fue exitosa, false en caso contrario.
  Future<bool> createMedicos(Medico est) async {
    try {
      final uri = Uri.parse('${baseUrl}medico/v1/create');
      final headers = await ApiHelper
          .getHeadersWithAuth(); // Incluye Content-Type y Authorization
      final body = jsonEncode({
        'especialidad': {'id': est.especialidad.id},
        'usuario': {'id': est.usuario.id},
        'estado': est.estado,
        'tarjetaProfe': est.tarjetaProfe,
      });

      final response = await http.post(uri, headers: headers, body: body);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al crear medico: $e');
    }
  }

  //! deleteMEedico
  /// Elimina un especialidad de la API.
  /// Realiza un borrado lógico de una especialidad por ID.
  /// Retorna true si fue exitoso.
  Future<bool> deleteMedico(int id) async {
    try {
      final headers = await ApiHelper.getHeadersWithAuth();
      final response = await http.delete(
        Uri.parse('${baseUrl}medico/v1/delete/$id'),
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
