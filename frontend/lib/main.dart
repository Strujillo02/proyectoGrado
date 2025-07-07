import 'package:flutter/material.dart';
import 'package:frontend/routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); //! Importante para que funcione el dotenv, inicializa el widget
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MediHome',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: appRouter,
    );
  }
}

 
