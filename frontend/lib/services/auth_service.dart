import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/api_helper.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final String baseUrl = dotenv.env['URL_API']!;

  //! login se encarga de autenticar al usuario
  Future<Map<String, dynamic>> login(
  String identificacion,
  String contrasena,
) async {
  final response = await http.post(
    Uri.parse('${baseUrl}auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'identificacion': identificacion,
      'contrasena': contrasena,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    User user = User.fromJson(data['user']);

    // Guardar token de sesión inicial y user (lo que venga del backend)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    await prefs.setString('user', jsonEncode(data['user']));

    // Obtener token FCM del dispositivo
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? deviceToken;
    try {
      deviceToken = await messaging.getToken();
    } catch (e) {
      debugPrint('Error obteniendo token FCM: $e');
      deviceToken = null;
    }

    if (deviceToken != null && deviceToken.isNotEmpty) {
      debugPrint('Token del dispositivo: $deviceToken');

      // Solo actualizar si el token nuevo es distinto
      if (user.token_dispositivo != deviceToken) {
        final updatedUser = User(
          id: user.id,
          nombre: user.nombre,
          telefono: user.telefono,
          email: user.email,
          identificacion: user.identificacion,
          genero: user.genero,
          estado: user.estado,
          tipo_identificacion: user.tipo_identificacion,
          contrasena: user.contrasena,
          tipo_usuario: user.tipo_usuario,
          direccion: user.direccion,
          token_dispositivo: deviceToken,
        );

        try {
          final userService = UserService();
          final ok = await userService.updateUsuario(updatedUser);

          if (ok) {
            // Guardar usuario actualizado en SharedPreferences
            await prefs.setString('user', jsonEncode(updatedUser.toJson()));
            user = updatedUser;
            debugPrint('Usuario actualizado con token_dispositivo en backend.');
          } else {
            debugPrint('No se pudo actualizar el usuario en el backend.');
            // opcional: reintentar más tarde o almacenar para sincronizar
          }
        } catch (e) {
          debugPrint('Error al actualizar usuario con token: $e');
        }
      } else {
        // Token ya coincide, aseguramos que SharedPreferences tenga la versión actual
        await prefs.setString('user', jsonEncode(user.toJson()));
      }
    } else {
      // No se obtuvo token FCM; dejamos el usuario como vino del backend
      await prefs.setString('user', jsonEncode(user.toJson()));
    }

    return {'success': true, 'user': user};
  } else {
    if (response.statusCode == 403) {
      return {'success': false, 'message': 'Credenciales incorrectas'};
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Error en login',
      };
    }
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
      Uri.parse('${baseUrl}auth/register'),
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

    if (response.statusCode == 200 || response.statusCode == 201) {
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
          return 'Paciente';
        }
      }
    } catch (e) {
      debugPrint('Error al obtener tipo de usuario: $e');
    }
    return null; // Si no hay usuario o hubo error
  }

  Future<void> enviarNotificacionDePrueba(User user) async {
  final headers = await ApiHelper.getHeadersWithAuth();
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  String? token = await messaging.getToken();

  if (token != null) {
    print("Token del dispositivo: $token");

    final response = await http.post(
      Uri.parse('${baseUrl}notificaciones/enviar'),
      headers: headers,
      body: jsonEncode({
        'token': token,
        'title': '🔥 Notificación de Prueba',
        'body': 'Bro, esto es una prueba desde Flutter 💪🏽',
      }),
    );

    if (response.statusCode == 200) {
      print("🔥 Notificación enviada desde el backend");
    } else {
      print("❌ Error al enviar notificación: ${response.body}");
    }
  }
}

}
