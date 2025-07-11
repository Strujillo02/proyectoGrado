import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/user_service.dart';
import 'package:go_router/go_router.dart';

class EditarUsuarioPage extends StatefulWidget {
  final int id;

  const EditarUsuarioPage({super.key, required this.id});

  @override
  State<EditarUsuarioPage> createState() => _EditarUsuarioPageState();
}

class _EditarUsuarioPageState extends State<EditarUsuarioPage> {
   // ! Se inicializa el servicio para obtener los datos del usuario
  // ! Se inicializa el key para el formulario
  //GlobalKey<FormState>() se usa para validar el formulario
  // y para acceder a los datos del formulario
  final _formKey = GlobalKey<FormState>();
   // Se inicializa el servicio para obtener los datos del usuario
  // y para actualizar los datos del usuario
  final _userService = UserService();


  // **Se inicializan los controladores para los campos de texto

  late TextEditingController nombreController;
  late TextEditingController emailController;
  late TextEditingController telefonoController;
  late TextEditingController identificacionController;
  late TextEditingController direccionController;
  late TextEditingController contrasenaController;

  String? tipoDocumentoSeleccionado;
  String? tipoUsuarioSeleccionado;
  String? generoSeleccionado;
  String? estadoSeleccionado;

  bool _loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsuario(); // Cargar datos del usuario al iniciar
  }

   //! loadUsuario
  /// Carga los datos del usuario desde la API
  Future<void> _loadUsuario() async {
    try {
      // Obtener el usuario por ID
      final user = await _userService.getUsuarios()
        .then((usuarios) => usuarios.firstWhere((u) => u.id == widget.id));

      if (!mounted) return;

      // Inicializar controladores con los valores del usuario
      nombreController = TextEditingController(text: user.nombre);
      emailController = TextEditingController(text: user.email);
      telefonoController = TextEditingController(text: user.telefono ?? '');
      identificacionController = TextEditingController(text: user.identificacion);
      direccionController = TextEditingController(text: user.direccion ?? '');
      contrasenaController = TextEditingController(text: user.contrasena ?? '');

      tipoDocumentoSeleccionado = user.tipo_identificacion;
      tipoUsuarioSeleccionado = user.tipo_usuario;
      generoSeleccionado = user.genero;
      estadoSeleccionado = user.estado;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error al cargar los datos del usuario';
        _loading = false;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final userEditado = User(
      id: widget.id,
      nombre: nombreController.text.trim(),
      email: emailController.text.trim(),
      telefono: telefonoController.text.trim(),
      identificacion: identificacionController.text.trim(),
      direccion: direccionController.text.trim(),
      contrasena: contrasenaController.text.trim(),
      tipo_identificacion: tipoDocumentoSeleccionado ?? '',
      tipo_usuario: tipoUsuarioSeleccionado ?? '',
      genero: generoSeleccionado,
      estado: estadoSeleccionado,
    );

    final success = await _userService.updateUsuario(userEditado);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario actualizado correctamente')),
      );
      context.go('/gestionar/usuarios'); // Regresar a la vista anterior
    } else {
      setState(() {
        errorMessage = 'Error al actualizar el usuario';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Editar Usuario',style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildTextField(nombreController, 'Nombre'),
              const SizedBox(height: 12),
              buildTextField(emailController, 'Correo electrónico'),
              const SizedBox(height: 12),
              buildTextField(telefonoController, 'Teléfono'),
              const SizedBox(height: 12),
              buildTextField(identificacionController, 'Identificación'),
              const SizedBox(height: 12),
              buildTextField(direccionController, 'Dirección'),
              const SizedBox(height: 12),
              buildTextField(contrasenaController, 'Contraseña', obscure: true),
              const SizedBox(height: 12),
              buildDropdown('Tipo de documento', tipoDocumentoSeleccionado, [
                'Cedula de ciudadania',
                'Pasaporte',
                'Cedula de extranjeria'
              ], (val) => setState(() => tipoDocumentoSeleccionado = val)),
              const SizedBox(height: 12),
              buildDropdown('Tipo de usuario', tipoUsuarioSeleccionado, [
                'Paciente',
                'Medico',
                'Administrador'
              ], (val) => setState(() => tipoUsuarioSeleccionado = val)),
              const SizedBox(height: 12),
              buildDropdown('Género', generoSeleccionado, ['Masculino', 'Femenino'], (val) => setState(() => generoSeleccionado = val)),
              const SizedBox(height: 12),
              buildDropdown('Estado', estadoSeleccionado, ['Activo', 'Inactivo'], (val) => setState(() => estadoSeleccionado = val)),
              const SizedBox(height: 20),
              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
                ),
                child: const Text('Guardar cambios', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label, {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (value) => value == null || value.isEmpty ? 'Este campo es obligatorio' : null,
    );
  }

  Widget buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Seleccione una opción' : null,
    );
  }
}
