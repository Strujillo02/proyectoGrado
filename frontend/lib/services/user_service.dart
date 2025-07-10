import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/api_helper.dart'; // Asegúrate que el import sea correcto
import 'package:frontend/models/user.dart';
import 'package:http/http.dart' as http;

class UserService {
  //! se inicializa dotenv para cargar las variables de entorno
  final String baseUrl = dotenv.env['URL_API']!;
 // final String baseUrlImg = dotenv.env['URL_API_IMG']!;

  //! getUsuarios
  /// Obtiene una lista de usuarios desde la API.
  Future<List<User>> getUsuarios() async {
    final headers = await ApiHelper.getHeadersWithAuth(); // Obtiene los headers con el token

    final response = await http.get(
      Uri.parse('${baseUrl}user/v1/get'),
      headers: headers, // Se incluye el token aquí
    );

    if (response.statusCode == 200) {
      /// Decodifica la respuesta JSON
      /// y convierte cada elemento en un objeto usuarios.
      /// el cual viene [data] de la API
      final data = jsonDecode(response.body)['data'];
      return List<User>.from(
        data.map((item) => User.fromJson(item)),
      );
    } else {
      throw Exception('Error al cargar usuarios');
    }
  }

  //! updateUsuario
  /// Actualiza un usuario en la API.
  /// Recibe un objeto usuario 
  /// Devuelve true si la actualización fue exitosa, false en caso contrario.
  Future<bool> updateUsuario(User est) async {
    try {
      final uri = Uri.parse('${baseUrl}usuario-update/${est.id}');
      final headers = await ApiHelper.getHeadersWithAuth(); // Incluye Content-Type y Authorization
      final body = jsonEncode(est.toJson()); // Convierte el objeto a JSON

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al actualizar usuarios: $e');
    }
  }

  //! createUsuario
  /// Crea un nuevo usuario en la API.
  /// Recibe un objeto usuario
  /// Devuelve true si la creación fue exitosa, false en caso contrario.
  Future<bool> createUsuario(User est) async {
    try {
      final uri = Uri.parse('${baseUrl}user/v1/create');
      final headers = await ApiHelper.getHeadersWithAuth(); // Incluye Content-Type y Authorization
      final body = jsonEncode(est.toJson()); // Convierte el objeto a JSON

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  //! deleteUsuario
  /// Elimina un usuario de la API.
  /// Realiza un borrado lógico de un usuario por ID.
  /// Retorna true si fue exitoso.
  Future<bool> deleteUsuario(int id) async {
    try {
      final headers = await ApiHelper.getHeadersWithAuth(); // Incluye token
      final response = await http.delete(
        Uri.parse('${baseUrl}user/v1/delete/$id'),
        headers: headers, // Autorización
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Error al eliminar el usuario');
      }
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }
}
