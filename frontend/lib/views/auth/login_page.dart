import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  ///! key se encarga de identificar el formulario
  ///! y permite validar los campos del form
  final _formKey = GlobalKey<FormState>();
  final identificacionController = TextEditingController();
  final contrasenaController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    // se encarga de autenticar al usuario
    // se le pasa identificacion y contrasena
    final result = await AuthService().login(
      identificacionController.text.trim(),
      contrasenaController.text.trim(),
    );

    // si el servidor devuelve un error, se convierte el objeto a Json
    // y se devuelve el mensaje de error
    setState(() => isLoading = false);

    if (result['success']) {
      final authService = AuthService();
      final tipoUsuario = await authService.getUserType();
      if (tipoUsuario == 'Administrador') {
        context.go('/home/admin');
      } else if (tipoUsuario == 'Paciente') {
        context.go('/home/paciente');
      } else if (tipoUsuario == 'Medico') {
        context.go('/home/medico');
      } else {
        setState(() {
          errorMessage = 'Tipo de usuario no reconocido';
        });
      }
    } else {
      // si hay un error, se muestra un mensaje de error
      setState(() {
        errorMessage = result['message'] ?? 'Error al iniciar sesion';
      });
    }
    //
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        top: true,
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset('assets/images/logo.png', height: 285),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Inicio de sesión',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(21, 99, 161, 1),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '¡Por favor complete todos los campos!',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextFormField(
                        controller: identificacionController,
                        decoration: const InputDecoration(
                          labelText: 'Número de documento*',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Ingresa tu correo' : null,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextFormField(
                        controller: contrasenaController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña*',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Ingresa tu contraseña' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // si hay un error, se muestra un mensaje de error
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  const SizedBox(height: 16),

                  //Botones de inicio de sesión y registro
                  SizedBox(
                    width: 300,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          isLoading
                              ? const CircularProgressIndicator()
                              : const Text(
                                'Iniciar sesión',
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/register');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
