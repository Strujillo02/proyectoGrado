import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/routes/app_router.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); //! Importante para que funcione el dotenv, inicializa el widget
   await dotenv.load(fileName: ".env"); //! Carga el archivo .env
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

 
