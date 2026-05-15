import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/widgets/common_appbar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  String? _selectedDocumentType;
  final numeroDocumentoController = TextEditingController();
  final contrasenaController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  bool _aceptaTerminos = false;

  static const String _terminosTexto =
      'Términos y Condiciones – Tratamiento de Datos (Medihome)\n\n'
      'Al registrarse en la aplicación Medihome, usted acepta de manera libre, expresa e informada los presentes términos y condiciones relacionados con el tratamiento de sus datos personales, de conformidad con la normativa vigente en Colombia, en especial la Ley 1581 de 2012 y el Decreto 1377 de 2013 .\n\n'
      '1. Autorización del tratamiento de datos\n\n'
      'El usuario (paciente o médico) autoriza a Medihome para recolectar, almacenar, usar, procesar y, en general, tratar sus datos personales con las siguientes finalidades:\n\n'
      'Gestión de registro y autenticación en la plataforma\n'
      'Prestación de servicios de salud y/o intermediación médica\n'
      'Gestión de citas, calificaciones y comunicación entre usuarios\n'
      'Procesamiento de pagos y facturación\n'
      'Envío de notificaciones, envio de ubicación, recordatorios y comunicaciones relacionadas con el servicio\n\n'
      '2. Datos recolectados\n\n'
      'Medihome podrá recolectar datos personales como:\n\n'
      'Nombre, identificación, teléfono, correo electrónico\n'
      'Información profesional (en el caso de médicos)\n'
      'Información relacionada con el motivo de consulta\n\n'
      'Los datos relacionados con la salud son considerados datos sensibles, los cuales requieren autorización especial del titular para su tratamiento .\n\n'
      '3. Derechos del titular\n\n'
      'El usuario tiene derecho a:\n\n'
      'Conocer, actualizar y rectificar sus datos personales\n'
      'Solicitar prueba de la autorización otorgada\n'
      'Ser informado sobre el uso de sus datos\n'
      'Revocar la autorización o solicitar la eliminación de sus datos\n'
      'Presentar quejas ante la autoridad competente (Superintendencia de Industria y Comercio)\n\n'
      'Estos derechos hacen parte del principio de Habeas Data, que protege la información personal de los ciudadanos .\n\n'
      '4. Seguridad de la información\n\n'
      'Medihome implementa medidas de seguridad para proteger los datos personales contra pérdida, acceso no autorizado, uso indebido o alteración, garantizando su confidencialidad.\n\n'
      '5. Uso de la plataforma\n\n'
      'El usuario se compromete a:\n\n'
      'Proporcionar información veraz y actualizada\n'
      'Hacer uso adecuado de la plataforma\n'
      'No utilizar Medihome para actividades ilícitas\n\n'
      '6. Aceptación de los términos\n\n'
      'Al registrarse en Medihome, el usuario declara que ha leído, entendido y aceptado estos términos y condiciones, autorizando el tratamiento de sus datos personales para las finalidades descritas.\n';

  Future<void> _mostrarTerminos() async {
    final acepto = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Términos y Condiciones'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Text(
                _terminosTexto,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Rechazar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _aceptaTerminos = acepto == true;
    });
  }

  void register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceptaTerminos) {
      setState(() {
        errorMessage = 'Debes aceptar los términos y condiciones.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await AuthService().register(
      nombreController.text.trim(),
      emailController.text.trim(),
      _selectedDocumentType.toString(),
      numeroDocumentoController.text.trim(),
      contrasenaController.text.trim(),
    );

    setState(() => isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      context.go('/');
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Error al registrarse';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CommonAppBar(
          backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
          elevation: 0,
          fallbackPath: '/',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo.png', height: 270),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      'Registro Usuario',
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
                    child: TextFormField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre y apellido*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingresa tu nombre' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Ingresa tu correo' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Tipo de documento*',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedDocumentType,
                      items: const [
                        DropdownMenuItem(
                          value: 'Cedula de ciudadania',
                          child: Text('Cédula de ciudadanía'),
                        ),
                        DropdownMenuItem(
                          value: 'Pasaporte',
                          child: Text('Pasaporte'),
                        ),
                        DropdownMenuItem(
                          value: 'Cedula de extranjeria',
                          child: Text('Cédula de extranjería'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDocumentType = value;
                        });
                      },
                      validator: (value) => value == null
                          ? 'Selecciona un tipo de documento'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: numeroDocumentoController,
                      decoration: InputDecoration(
                        labelText: 'Número de documento*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingresa tu número de documento'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: contrasenaController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    child: TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Vuelve a escribir la contraseña*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirma tu contraseña';
                        }
                        if (value != contrasenaController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _aceptaTerminos,
                          onChanged: isLoading
                              ? null
                              : (val) {
                                  setState(() {
                                    _aceptaTerminos = val ?? false;
                                  });
                                },
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Wrap(
                              children: [
                                const Text('Acepto términos y condiciones, '),
                                InkWell(
                                  onTap: isLoading ? null : _mostrarTerminos,
                                  child: const Text(
                                    'haz clic aquí',
                                    style: TextStyle(
                                      color: Color.fromRGBO(21, 99, 161, 1),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const Text(
                                    ' si desea ver los términos y condiciones.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 300,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          (isLoading || !_aceptaTerminos) ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(21, 99, 161, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Crear cuenta',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color.fromRGBO(21, 99, 161, 1),
                    ),
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
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
