import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// PopDisposition may not be exported by older SDKs; import internal symbol as
// fallback so the project compiles while you update Flutter. This is a
// temporary shim and can be removed once the SDK provides PopDisposition.
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/services/citas_service.dart';
import 'firebase_options.dart';
import 'dart:async';

// Canal para Android 8+
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel', // debe coincidir con el meta-data opcional
  'Notificaciones importantes',
  description: 'Canal para notificaciones en primer plano',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNoti =
    FlutterLocalNotificationsPlugin();

// Stream to broadcast notification events that should show an in-app popup.
final StreamController<Map<String, dynamic>> notificationActionStream =
    StreamController<Map<String, dynamic>>.broadcast();

// IDs de acciones para notificaciones de Cita
const String _actionAccept = 'cita_accept';
const String _actionReject = 'cita_reject';

bool _esSolicitudNuevaCita(Map<String, dynamic> data) {
  final citaIdRaw =
      (data['citaId'] ?? data['cita_id'] ?? data['idCita'])?.toString();
  if (citaIdRaw == null || citaIdRaw.isEmpty) return false;

  final tipo = (data['tipo_notificacion'] ??
          data['notificationType'] ??
          data['tipo'] ??
          data['evento'])
      ?.toString()
      .trim()
      .toLowerCase();
  if (tipo != null && tipo.isNotEmpty) {
    return tipo.contains('solic') ||
        tipo.contains('create') ||
        tipo.contains('creat') ||
        tipo.contains('nueva');
  }

  final estado = (data['estado'] ?? data['estado_cita'] ?? data['status'])
      ?.toString()
      .trim()
      .toUpperCase();
  if (estado != null && estado.isNotEmpty) {
    return estado == 'PENDIENTE' ||
        estado == 'SOLICITADA' ||
        estado == 'CREADA';
  }

  // Si no hay metadatos de tipo/estado, asumimos que es una solicitud nueva.
  return true;
}

// Handler de mensajes en background (obligatorio si lo usas)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Mostrar notificación local en background si recibes payload de datos (acciones)
  try {
    if (!_esSolicitudNuevaCita(message.data)) {
      debugPrint(
          'BG notification ignorada: no es solicitud nueva de cita -> ${message.data}');
      return;
    }

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
  final pk = dotenv.env['WOMPI_PUBLIC_KEY'] ?? '';
  final red = dotenv.env['WOMPI_REDIRECT_URL'] ?? '';
  final sec = dotenv.env['WOMPI_INTEGRITY_SECRET'] ?? '';
  debugPrint('[ENV] URL_API=$api');
  debugPrint(
      '[ENV] WOMPI_PUBLIC_KEY=${pk.isNotEmpty ? pk.substring(0, 12) + '...' : 'EMPTY'}');
  debugPrint('[ENV] WOMPI_REDIRECT_URL=${red.isNotEmpty ? red : 'EMPTY'}');
  debugPrint(
      '[ENV] WOMPI_INTEGRITY_SECRET len=${sec.length} prefixOk=${sec.startsWith('test_integrity_')}');
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
          // Broadcast event so in-app UI can show a popup (mark apiHandled true)
          notificationActionStream.add({
            'title': 'Cita actualizada',
            'body': 'Has aceptado la cita.',
            'citaId': citaId,
            'actionId': _actionAccept,
            'apiHandled': true,
          });
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
          notificationActionStream.add({
            'title': 'Cita actualizada',
            'body': 'Has rechazado la cita.',
            'citaId': citaId,
            'actionId': _actionReject,
            'apiHandled': true,
          });
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

    if (!_esSolicitudNuevaCita(m.data)) {
      debugPrint(
          'Foreground notification ignored: no es solicitud nueva de cita -> ${m.data}');
      return;
    }

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
    // Broadcast to show in-app popup when a cita notification arrives in foreground
    if (esCita) {
      debugPrint(
          'DEBUG: onMessage preparing to broadcast notificationActionStream for citaId=$citaIdStr');
      notificationActionStream.add({
        'title': title,
        'body': body,
        'citaId': int.tryParse(citaIdStr),
        'actionId': null,
        'apiHandled': false,
      });
    }
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
    // Use WillPopScope for now to remain compatible with older Flutter SDKs.
    // The router-first behavior is preserved: prefer appRouter.pop() when
    // possible so the app's navigation is used instead of exiting the app.
    //
    // The PopScope-based implementation is intentionally left commented
    // below as a reference for when you upgrade the Flutter SDK and want
    // to enable predictive-back gestures. Replace this WillPopScope with
    // the PopScope block after upgrading.
    /*
    // PopScope-based handler (requires Flutter SDK with PopScope/PopDisposition)
    return PopScope(
      onPopInvoked: (invocation) async {
        try {
          if (appRouter.canPop()) {
            appRouter.pop();
            return PopDisposition.pop;
          }
        } catch (_) {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
            return PopDisposition.pop;
          }
        }
        return PopDisposition.none;
      },
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MediHome',
        theme: ThemeData(primarySwatch: Colors.blue),
        routerConfig: appRouter,
      ),
    );
    */

    return WillPopScope(
      onWillPop: () async {
        try {
          if (appRouter.canPop()) {
            appRouter.pop();
            return false; // we handled the pop
          }
        } catch (_) {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
            return false;
          }
        }
        // Nothing to pop: let system handle (exit)
        return true;
      },
      child: NotificationActionHandler(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'MediHome',
          // Use the GoRouter's navigator key so notification callbacks can access
          // the app navigator context when available.
          // Note: MaterialApp.router doesn't accept a top-level navigatorKey when
          // using routerConfig; instead we pull the key from the router below
          theme: ThemeData(primarySwatch: Colors.blue),
          routerConfig: appRouter,
        ),
      ),
    );
  }
}

/// Widget that listens to notificationActionStream and shows an in-app popup
/// with Accept/Reject buttons mirroring the notification actions.
class NotificationActionHandler extends StatefulWidget {
  final Widget child;
  const NotificationActionHandler({required this.child, super.key});

  @override
  State<NotificationActionHandler> createState() =>
      _NotificationActionHandlerState();
}

class _NotificationActionHandlerState extends State<NotificationActionHandler> {
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = notificationActionStream.stream.listen((payload) {
      debugPrint('DEBUG: NotificationActionHandler received payload: $payload');
      final title = payload['title']?.toString() ?? 'Notificación';
      final body = payload['body']?.toString() ?? '';
      final int? citaId = payload['citaId'] is int
          ? payload['citaId'] as int
          : (payload['citaId'] != null
              ? int.tryParse(payload['citaId'].toString())
              : null);
      final apiHandled = payload['apiHandled'] == true;

      final navKey = appRouter.routerDelegate.navigatorKey;
      // Prefer overlay context, fallback to router's currentContext, then to this State's context.
      final ctx = navKey.currentState?.overlay?.context ??
          navKey.currentContext ??
          context;
      debugPrint(
          'DEBUG: Using context $ctx to show in-app dialog (citaId=$citaId, apiHandled=$apiHandled)');

      showDialog<void>(
        context: ctx,
        barrierDismissible: true,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () async => Navigator.of(c).pop(),
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: apiHandled || citaId == null
                  ? null
                  : () async {
                      Navigator.of(c).pop();
                      try {
                        await CitasService().responderCita(
                            citaId: citaId, respuesta: 'Rechazada');
                        notificationActionStream.add({
                          'title': 'Cita actualizada',
                          'body': 'Has rechazado la cita.',
                          'citaId': citaId,
                          'actionId': _actionReject,
                          'apiHandled': true,
                        });
                      } catch (e) {
                        debugPrint('Error rechazando desde diálogo: $e');
                      }
                    },
              child: const Text('Rechazar'),
            ),
            TextButton(
              onPressed: apiHandled || citaId == null
                  ? null
                  : () async {
                      Navigator.of(c).pop();
                      try {
                        await CitasService().responderCita(
                            citaId: citaId, respuesta: 'Aceptada');
                        notificationActionStream.add({
                          'title': 'Cita actualizada',
                          'body': 'Has aceptado la cita.',
                          'citaId': citaId,
                          'actionId': _actionAccept,
                          'apiHandled': true,
                        });
                      } catch (e) {
                        debugPrint('Error aceptando desde diálogo: $e');
                      }
                    },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
