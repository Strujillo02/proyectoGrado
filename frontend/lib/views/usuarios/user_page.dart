import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/user_service.dart';
import 'package:go_router/go_router.dart';

// Pantalla principal para crear y listar usuarios
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para cada campo del formulario
  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  String? _selectedDocumentType;
  final numeroDocumentoController = TextEditingController();
  final contrasenaController = TextEditingController();
  String? _selectedUserType;

  // Instancia del servicio que conecta con la API
  final UserService _userService = UserService();

  // Lista futura de usuarios, para la vista de listar
  late Future<List<User>> _futureUsuarios;

  // Control de carga y mensajes de error
  bool isLoading = false;
  String? errorMessage;

  // Variable que determina si estamos creando o listando
  String currentView = 'listar';

  // Cuando inicia la pantalla, se cargan los usuarios
  @override
  void initState() {
    super.initState();
    _futureUsuarios = _userService.getUsuarios();
  }

  // Función que se llama al presionar el botón "Crear cuenta"
  void register() async {
    // Si el formulario no es válido, no hace nada
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Crea un objeto usuario con los datos del formulario
    final newUser = User(
      nombre: nombreController.text.trim(),
      email: emailController.text.trim(),
      tipo_identificacion: _selectedDocumentType.toString(),
      identificacion: numeroDocumentoController.text.trim(),
      contrasena: contrasenaController.text.trim(),
      tipo_usuario: _selectedUserType.toString(),
    );

    // Intenta crear el usuario usando el servicio
    final success = await _userService.createUsuario(newUser);

    // Después de intentar crear, actualiza la vista
    setState(() {
      isLoading = false;
      if (success) {
        // Si fue exitoso, recarga la lista y cambia a vista "listar"
        _futureUsuarios = _userService.getUsuarios();
        currentView = 'listar';
      } else {
        errorMessage = 'No se pudo crear el usuario';
      }
    });
  }

  // Método principal que construye la interfaz visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
        automaticallyImplyLeading: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color.fromARGB(255, 215, 215, 218),
          ),
          onPressed:
              () =>
                  context.go('/home/admin'), // Regresa a la pantalla principal
          iconSize: 35,
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título de la pantalla
                const Padding(
                  padding: EdgeInsets.only(top: 25, bottom: 1),
                  child: Text(
                    'Gestión de usuarios',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(21, 99, 161, 1),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Botones para cambiar entre "crear" y "listar"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botón "Crear usuario"
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              currentView = 'crear';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(
                              21,
                              99,
                              161,
                              1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Crear Usuario',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botón "Listar usuario"
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              currentView = 'listar';
                              _futureUsuarios =
                                  _userService
                                      .getUsuarios(); // Recarga la lista
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(
                              21,
                              99,
                              161,
                              1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Listar Usuario',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Cambia el contenido según la vista actual
                if (currentView == 'crear') buildCreateForm(),
                if (currentView == 'listar') buildUserList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Construye el formulario de creación de usuario
  Widget buildCreateForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'Formulario de creación de usuario',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(21, 99, 161, 1),
            ),
          ),
          const SizedBox(height: 20),

          // Campos del formulario
          buildTextField(nombreController, 'Nombre y apellido*'),
          const SizedBox(height: 16),

          buildTextField(emailController, 'Email*'),
          const SizedBox(height: 16),

          buildDropdownField(
            label: 'Tipo de documento*',
            value: _selectedDocumentType,
            items: const [
              'Cedula de ciudadania',
              'Pasaporte',
              'Cedula de extranjeria',
            ],
            onChanged: (val) => setState(() => _selectedDocumentType = val),
          ),
          const SizedBox(height: 16),

          buildTextField(numeroDocumentoController, 'Número de documento*'),
          const SizedBox(height: 16),

          buildDropdownField(
            label: 'Tipo de usuario*',
            value: _selectedUserType,
            items: const ['Paciente', 'Medico', 'Administrador'],
            onChanged: (val) => setState(() => _selectedUserType = val),
          ),
          const SizedBox(height: 16),

          buildTextField(contrasenaController, 'Contraseña*', obscure: true),
          const SizedBox(height: 16),

          buildTextField(
            null,
            'Vuelve a escribir la contraseña*',
            obscure: true,
            confirm: true,
          ),
          const SizedBox(height: 16),

          // Muestra mensaje de error si hay uno
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Botón para crear usuario
          SizedBox(
            width: 300,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Crear cuenta',
                        style: TextStyle(color: Colors.white),
                      ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Construye un campo de texto con validación
  Widget buildTextField(
    TextEditingController? controller,
    String label, {
    bool obscure = false,
    bool confirm = false,
  }) {
    return SizedBox(
      width: 300,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (confirm) {
            if (value == null || value.isEmpty) return 'Confirma tu contraseña';
            if (value != contrasenaController.text)
              return 'Las contraseñas no coinciden';
          } else if (value == null || value.isEmpty) {
            return 'Campo obligatorio';
          } else if (label.contains('Contraseña') && value.length < 6) {
            return 'Mínimo 6 caracteres';
          }
          return null;
        },
      ),
    );
  }

  // Construye un dropdown (combo box) con validación
  Widget buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 300,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: value,
        items:
            items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Selecciona una opción' : null,
      ),
    );
  }

  // Lista de usuarios con opción de eliminar
  Widget buildUserList() {
    return FutureBuilder<List<User>>(
      future: _futureUsuarios,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No hay usuarios disponibles');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final user = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(user.nombre),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${user.email}'),
                    Text(
                      'Documento: ${user.tipo_identificacion} - ${user.identificacion}',
                    ),
                    Text('Tipo de usuario: ${user.tipo_usuario}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('¿Eliminar usuario?'),
                            content: const Text(
                              '¿Está seguro que desea eliminar?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                    );

                    if (confirm == true) {
                      final eliminado = await _userService.deleteUsuario(
                        user.id!,
                      );
                      if (eliminado) {
                        final updatedUsuarios = _userService.getUsuarios();
                        setState(() {
                          _futureUsuarios = updatedUsuarios;
                        });

                        // Muestra SnackBar de éxito
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Usuario eliminado correctamente'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al eliminar el usuario'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                ),
                onTap: () {
                  // Aquí se puede implementar la edición
                },
              ),
            );
          },
        );
      },
    );
  }
}
