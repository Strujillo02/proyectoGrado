import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = dotenv.env['URL_API']!;

  //! login se encarga de autenticar al usuario
  Future<Map<String, dynamic>> login(
    String identificacion,
    String contrasena,
  ) async {
    final response = await http.post(
      Uri.parse('${baseUrl}login'),
      //* especifica el tipo de contenido que se va a enviar
      //* el servidor espera recibir un JSON
      headers: {'Content-Type': 'application/json'},
      //* convierte el objeto a JSON
      //* se envia la identificacion y la contrasena al servidor
      //* el servidor devuelve un token y el usuario
      body: jsonEncode({
        'identificacion': identificacion,
        'contrasena': contrasena,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      try {
        //! shared_preferences se encarga de guardar el token y el usuario
        //! en el dispositivo del usuario
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));
      } catch (e) {
        debugPrint('Error al guardar token en SharedPreferences: $e');
      }

      return {'success': true, 'user': User.fromJson(data['user'])};
    } else {
      //* si el servidor devuelve un error, se convierte el objeto a JSON
      //* y se devuelve el mensaje de error
      final data = jsonDecode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Error en login'};
    }
  }

  //! register se encarga de registrar al usuario
  //* se le pasa el nombre, email, tipo de identificacioncontraseña al servidor
  Future<Map<String, dynamic>> register(
    String nombre,
    String email,
    String tipo_identificacion,
    String identificacion,
    String contrasena,
  ) async {
    final response = await http.post(
      Uri.parse('${baseUrl}users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'identificacion': identificacion,
        'tipo_identificacion': tipo_identificacion,
        'contrasena': contrasena,
        'tipo_usuario': 'Paciente',
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true};
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Error en registro',
        'errors': data['errors'],
      };
    }
  }

  //! getUser se encarga de obtener el usuario
  //* se obtiene el usuario de SharedPreferences
  Future<User?> getUser() async {
    try {
      //* se obtiene el usuario de SharedPreferences
      //* se convierte el objeto a JSON
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr != null) {
        return User.fromJson(jsonDecode(userStr));
      }
    } catch (e) {
      debugPrint('Error al obtener SharedPreferences: $e');
    }
    return null;
  }

  //! getToken se encarga de obtener el token
  //* se obtiene el token de SharedPreferences
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      debugPrint('Error al obtener token: $e');
      return null;
    }
  }

  //! isLoggedIn se encarga de verificar si el usuario está logueado
  //* se verifica si el token existe en SharedPreferences
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  //Metodo que retorne tipo de usuario
  Future<String?> getUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');

      if (userStr != null) {
        final user = User.fromJson(jsonDecode(userStr));
        if (user.tipo_usuario.toString() == ('Administrador')) {
          return 'Administrador';
        } else if (user.tipo_usuario.toString() == ('Medico')) {
          return 'Medico';
        } else if (user.tipo_usuario.toString() == ('Paciente')) {
          return 'paciente';
        }
      }
    } catch (e) {
      debugPrint('Error al obtener tipo de usuario: $e');
    }
    return null; // Si no hay usuario o hubo error
  }
}
