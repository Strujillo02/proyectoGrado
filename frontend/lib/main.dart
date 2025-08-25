import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

// Canal para Android 8+
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'high_importance_channel', // debe coincidir con el meta-data opcional
  'Notificaciones importantes',
  description: 'Canal para notificaciones en primer plano',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNoti = FlutterLocalNotificationsPlugin();

// Handler de mensajes en background (obligatorio si lo usas)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Aquí podrías registrar logs
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // iOS/Android 13+: permiso
  await FirebaseMessaging.instance.requestPermission();

  // Inicializa notificaciones locales
  const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: initAndroid);
  await _localNoti.initialize(initSettings);

  // Crea canal en Android
  await _localNoti
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);

  // Token
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('FCM token actual: $token');

  // Foreground: mostrar notificación local (notification o data-only)
  FirebaseMessaging.onMessage.listen((m) {
    debugPrint('FCM onMessage -> \\n+title: ${m.notification?.title} | body: ${m.notification?.body} | data: ${m.data}');

    final n = m.notification;
    final title = n?.title ?? m.data['title']?.toString() ?? 'Notificación';
    final body = n?.body ?? m.data['body']?.toString() ?? 'Tienes un mensaje';

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
        ),
      ),
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


