import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/services/citas_service.dart';
import 'firebase_options.dart';

// Canal para Android 8+
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel', // debe coincidir con el meta-data opcional
  'Notificaciones importantes',
  description: 'Canal para notificaciones en primer plano',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNoti =
    FlutterLocalNotificationsPlugin();

// IDs de acciones para notificaciones de Cita
const String _actionAccept = 'cita_accept';
const String _actionReject = 'cita_reject';

// Handler de mensajes en background (obligatorio si lo usas)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Mostrar notificación local en background si recibes payload de datos (acciones)
  try {
    // Preferir datos personalizados si están presentes
    String title = message.data['title']?.toString() ??
        message.notification?.title ??
        'Notificación';
    String body = message.data['body']?.toString() ??
        message.notification?.body ??
        'Tienes un mensaje';
    final rawPaciente = (message.data['pacienteNombre'] ??
            message.data['paciente_nombre'] ??
            message.data['nombrePaciente'] ??
            message.data['usuarioNombre'] ??
            message.data['usuario_nombre'])
        ?.toString();
    final pacienteNombre =
        (rawPaciente == null || rawPaciente.toLowerCase() == 'null')
            ? null
            : rawPaciente;
    if (pacienteNombre != null && pacienteNombre.isNotEmpty) {
      title = 'Solicitud de cita';
      body =
          'Tienes una solicitud de cita del paciente: $pacienteNombre. ¿Deseas aceptarla?';
    }
    final String? citaIdStr = (message.data['citaId'] ??
            message.data['cita_id'] ??
            message.data['idCita'])
        ?.toString();
    final bool esCita = citaIdStr != null && citaIdStr.isNotEmpty;
    final String? payload = esCita ? jsonEncode({'citaId': citaIdStr}) : null;

    // Asegurar canal creado
    await _localNoti
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNoti.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          actions: esCita
              ? <AndroidNotificationAction>[
                  AndroidNotificationAction(_actionAccept, 'Aceptar',
                      showsUserInterface: true, cancelNotification: true),
                  AndroidNotificationAction(_actionReject, 'Rechazar',
                      showsUserInterface: true, cancelNotification: true),
                ]
              : const <AndroidNotificationAction>[],
        ),
      ),
      payload: payload,
    );
  } catch (e) {
    debugPrint('Error mostrando notificación en background: $e');
  }
}

// Handler de acciones de notificación en background (opcional)
@pragma('vm:entry-point')
Future<void> _onBackgroundNotificationResponse(
    NotificationResponse response) async {
  // Solo log en background; manejamos la acción en primer plano para evitar issues de inicialización/env
  debugPrint(
      'BG Notification action: id=${response.actionId}, payload=${response.payload}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // === Logs de verificación del .env ===
  final api = dotenv.env['URL_API'] ?? '';
  final pk  = dotenv.env['WOMPI_PUBLIC_KEY'] ?? '';
  final red = dotenv.env['WOMPI_REDIRECT_URL'] ?? '';
  final sec = dotenv.env['WOMPI_INTEGRITY_SECRET'] ?? '';
  debugPrint('[ENV] URL_API=$api');
  debugPrint('[ENV] WOMPI_PUBLIC_KEY=${pk.isNotEmpty ? pk.substring(0, 12) + '...' : 'EMPTY'}');
  debugPrint('[ENV] WOMPI_REDIRECT_URL=${red.isNotEmpty ? red : 'EMPTY'}');
  debugPrint('[ENV] WOMPI_INTEGRITY_SECRET len=${sec.length} prefixOk=${sec.startsWith('test_integrity_')}');
  // =====================================

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // iOS/Android 13+: permiso
  await FirebaseMessaging.instance.requestPermission();

  // Inicializa notificaciones locales
  const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: initAndroid);
  await _localNoti.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // Manejar acciones de Aceptar/Rechazar desde la notificación
      final actionId = response.actionId;
      final payload = response.payload;
      if (payload == null) return;
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final int? citaId = int.tryParse(data['citaId'].toString());
        if (citaId == null) return;
        if (actionId == _actionAccept) {
          await CitasService()
              .responderCita(citaId: citaId, respuesta: 'Aceptada');
          // Confirmación local
          await _localNoti.show(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'Cita actualizada',
            'Has aceptado la cita.',
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        } else if (actionId == _actionReject) {
          await CitasService()
              .responderCita(citaId: citaId, respuesta: 'Rechazada');
          await _localNoti.show(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'Cita actualizada',
            'Has rechazado la cita.',
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error manejando acción de notificación: $e');
      }
    },
    onDidReceiveBackgroundNotificationResponse:
        _onBackgroundNotificationResponse,
  );

  // Crea canal en Android
  await _localNoti
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);

  // Token
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('FCM token actual: $token');

  // Foreground: mostrar notificación local (notification o data-only)
  FirebaseMessaging.onMessage.listen((m) {
    debugPrint(
        'FCM onMessage -> \\n+title: ${m.notification?.title} | body: ${m.notification?.body} | data: ${m.data}');

    final n = m.notification;
    String title = m.data['title']?.toString() ?? n?.title ?? 'Notificación';
    String body = m.data['body']?.toString() ?? n?.body ?? 'Tienes un mensaje';
    final rawPaciente = (m.data['pacienteNombre'] ??
            m.data['paciente_nombre'] ??
            m.data['nombrePaciente'] ??
            m.data['usuarioNombre'] ??
            m.data['usuario_nombre'])
        ?.toString();
    final pacienteNombre =
        (rawPaciente == null || rawPaciente.toLowerCase() == 'null')
            ? null
            : rawPaciente;
    if (pacienteNombre != null && pacienteNombre.isNotEmpty) {
      title = 'Solicitud de cita';
      body =
          'Tienes una solicitud de cita del paciente: $pacienteNombre. ¿Deseas aceptarla?';
    }

    // Si viene una cita en data, incluimos acciones y payload con citaId
    final String? citaIdStr =
        (m.data['citaId'] ?? m.data['cita_id'] ?? m.data['idCita'])?.toString();
    final bool esCita = citaIdStr != null && citaIdStr.isNotEmpty;
    final String? payload = esCita ? jsonEncode({'citaId': citaIdStr}) : null;

    _localNoti.show(
      m.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          actions: esCita
              ? <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    _actionAccept,
                    'Aceptar',
                    showsUserInterface: true,
                    cancelNotification: true,
                  ),
                  AndroidNotificationAction(
                    _actionReject,
                    'Rechazar',
                    showsUserInterface: true,
                    cancelNotification: true,
                  ),
                ]
              : const <AndroidNotificationAction>[],
        ),
      ),
      payload: payload,
    );
  });

  // Tocado desde bandeja
  FirebaseMessaging.onMessageOpenedApp.listen((m) {
    debugPrint('onMessageOpenedApp -> ${m.data}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MediHome',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: appRouter,
    );
  }
}
