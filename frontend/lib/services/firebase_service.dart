import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/api_helper.dart';
import 'package:frontend/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final String baseUrl = dotenv.env['URL_API']!;

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

  //! isLoggedIn se encarga de verificar si el usuario está loguea


}
