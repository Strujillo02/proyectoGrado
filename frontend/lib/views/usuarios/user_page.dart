import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/models/especialidades.dart';
import 'package:frontend/models/medico.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/especialidades_service.dart';
import 'package:frontend/services/medico_service.dart';
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

  // Controladores para cada campo del formulario usuario
  final numeroDocumentoController = TextEditingController();

  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  final telefonoController = TextEditingController();
  final identificacionController = TextEditingController();
  final direccionController = TextEditingController();
  final contrasenaController = TextEditingController();
  String? _selectedDocumentType;
  String? _selectedUserType;
  String? _selectedGenero;
  String? _selectedEstado;

  // Almacena el usuario encontrado por identificación
  User? usuarioEncontrado;

  //Controladores para cada campo de formulario de médico
  String? _selectedEspecialidad;
  String? _selectedEstadoMedico;
  final tarjetaProfeController = TextEditingController();

  // Instancia del servicio que conecta con la API
  final UserService _userService = UserService();

  //Instancia del servicio de médico
  final MedicoService _medicoService = MedicoService();

  // Lista futura de usuarios, para la vista de listar
  late Future<List<User>> _futureUsuarios;

  // Lista futura de médicos, para la vista de listar
  late Future<List<Medico>> _futureMedicos;

  // Control de carga y mensajes de error
  bool isLoading = false;
  String? errorMessage;

  // Variable que determina si estamos creando o listando
  String currentView = 'listar';

  //Variables para especialidades
  List<Especialidades> _especialidades = [];
  Especialidades? _especialidadSeleccionada;
  final EspecialidadesService _especialidadesService = EspecialidadesService();
  bool _cargandoEspecialidades = true;

  // Cuando inicia la pantalla, se cargan los usuarios
  @override
  void initState() {
    super.initState();
    _futureUsuarios = _userService.getUsuarios();
    _futureMedicos = _medicoService.getMedicos();
    cargarEspecialidades();
  }

  void cargarEspecialidades() async {
    try {
      final lista = await _especialidadesService.getEspecialidades();
      setState(() {
        _especialidades = lista;
        _cargandoEspecialidades = false;
      });
    } catch (e) {
      setState(() {
        _cargandoEspecialidades = false;
      });
    }
  }

  void limpiarCampos() {
    nombreController.clear();
    emailController.clear();
    telefonoController.clear();
    identificacionController.clear();
    direccionController.clear();
    contrasenaController.clear();
    numeroDocumentoController.clear();
    tarjetaProfeController.clear();
    _selectedDocumentType = null;
    _selectedUserType = null;
    _selectedGenero = null;
    _selectedEstado = null;
    _selectedEspecialidad = null;
    _especialidadSeleccionada = null;
    _selectedEstadoMedico = null;
    usuarioEncontrado = null;
    errorMessage = null;
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

  // crear un medico
  Future<void> registerMedico() async {
    if (!_formKey.currentState!.validate()) return;
    if (usuarioEncontrado == null) {
      setState(() {
        errorMessage = 'busca y selecciona un usuario médico primero.';
      });
      return;
    }
    if (_especialidadSeleccionada == null) {
      setState(() {
        errorMessage = 'selecciona una especialidad.';
      });
      return;
    }
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final medico = Medico(
      especialidad: _especialidadSeleccionada!,
      usuario: usuarioEncontrado!,
      estado: _selectedEstadoMedico ?? 'Activo',
      tarjetaProfe: tarjetaProfeController.text.trim(),
    );

    final success = await _medicoService.createMedicos(medico);

    setState(() {
      isLoading = false;
      if (success) {
        errorMessage = null;
        usuarioEncontrado = null;
        tarjetaProfeController.clear();
        identificacionController.clear();
        _selectedEstadoMedico = null;
        _especialidadSeleccionada = null;
        _futureMedicos = _medicoService.getMedicos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Médico creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        errorMessage = 'No se pudo crear el médico';
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
                              limpiarCampos();
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
                              _futureUsuarios = _userService.getUsuarios();
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

                const SizedBox(height: 16),

                // Fila adicional para botones de médicos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botón "Crear Médico"
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              limpiarCampos();
                              currentView = 'crearmedico';
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
                            'Crear Médico',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botón "Listar Médico"
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              currentView = 'listarmedico';
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
                            'Listar Médico',
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
                if (currentView == 'crearmedico') buildCrearMedicoForm(),
                if (currentView == 'listarmedico') buildMedicoList(),
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

  // Construye el formulario para crear un médico
  Widget buildCrearMedicoForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'Formulario de creación de médico',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(21, 99, 161, 1),
            ),
          ),
          const SizedBox(height: 20),

          // Campo de identificación con ícono de búsqueda al final
          SizedBox(
            width: 300,
            child: TextFormField(
              controller: identificacionController,
              decoration: InputDecoration(
                labelText: 'Número de documento',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final id = identificacionController.text.trim();
                    final user = await _userService.getUsuarioByIdentificacion(
                      id,
                    );

                    if (user != null && user.tipo_usuario == 'Medico') {
                      setState(() {
                        usuarioEncontrado = user;
                        nombreController.text = user.nombre;
                        emailController.text = user.email;
                        telefonoController.text = user.telefono ?? '';
                        identificacionController.text = user.identificacion;
                        direccionController.text = user.direccion ?? '';
                        contrasenaController.text = user.contrasena ?? '';
                        _selectedDocumentType = user.tipo_identificacion;
                        _selectedUserType = user.tipo_usuario;
                        _selectedGenero = user.genero ?? '';
                        _selectedEstado = user.estado ?? '';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Usuario médico encontrado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Usuario no encontrado o no es tipo médico',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
            ),
          ),
          const SizedBox(height: 10),

          // Muestra los campos solo si se encontró el usuario
          if (usuarioEncontrado != null) ...[
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
            const SizedBox(height: 12),
            buildDropdownField(
              label: 'Tipo de usuario',
              value: _selectedUserType,
              items: const ['Paciente', 'Medico', 'Administrador'],
              onChanged: (val) => setState(() => _selectedUserType = val),
            ),
            const SizedBox(height: 12),
            buildDropdownField(
              label: 'Genero',
              value: _selectedGenero,
              items: const ['Masculino', 'Femenino'],
              onChanged: (val) => setState(() => _selectedGenero = val),
            ),
            const SizedBox(height: 12),
            buildDropdownField(
              label: 'Estado de Usuario',
              value: _selectedEstado,
              items: const ['Activo', 'Inactivo'],
              onChanged: (val) => setState(() => _selectedEstado = val),
            ),
            const SizedBox(height: 12),
            _cargandoEspecialidades
                ? const CircularProgressIndicator()
                : buildDropdownField(
                  label: 'Especialidad',
                  value: _especialidadSeleccionada?.nombre,
                  items: _especialidades.map((e) => e.nombre).toList(),
                  onChanged: (val) {
                    setState(() {
                      _especialidadSeleccionada = _especialidades.firstWhere(
                        (e) => e.nombre == val,
                      );
                    });
                  },
                ),
            const SizedBox(height: 12),
            buildDropdownField(
              label: 'Estado de médico',
              value: _selectedEstadoMedico,
              items: const ['Activo', 'Inactivo'],
              onChanged: (val) => setState(() => _selectedEstadoMedico = val),
            ),
            const SizedBox(height: 12),
            buildTextField(
              tarjetaProfeController,
              'Tarjeta profesional',
              obscure: true,
            ),
            const SizedBox(height: 12),
          ],
          // Botón para crear médico
          SizedBox(
            width: 300,
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : registerMedico,
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
                        'Crear Médico',
                        style: TextStyle(color: Colors.white),
                      ),
            ),
          ),
          const SizedBox(height: 12),
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
              color: const Color.fromARGB(255, 208, 221, 233),
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón de editar
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.green,
                      ), // Ícono de editar
                      onPressed: () {
                        context.go('/usuario/editar/${user.id}');
                      },
                    ),
                    // Botón de eliminar (ya existente)
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Color.fromARGB(255, 165, 26, 16),
                      ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Usuario eliminado correctamente',
                                ),
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Lista de médicos con opción de eliminar
  Widget buildMedicoList() {
    return FutureBuilder<List<Medico>>(
      future: _futureMedicos,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No hay médicos disponibles');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final medico = snapshot.data![index];
            return Card(
              color: const Color.fromARGB(255, 208, 221, 233),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(medico.usuario.nombre),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tarjeta Profesional: ${medico.tarjetaProfe}'),
                    Text(
                      'Documento: ${medico.usuario.tipo_identificacion} - ${medico.usuario.identificacion}',
                    ),
                    Text('Tipo de usuario: ${medico.usuario.tipo_usuario}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón de editar
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.green,
                      ), // Ícono de editar
                      onPressed: () {
                        context.go('/medico/editar/${medico.id}');
                      },
                    ),
                    // Botón de eliminar (ya existente)
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Color.fromARGB(255, 165, 26, 16),
                      ),
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
                          final eliminado = await _medicoService.deleteMedico(
                            medico.id!,
                          );//
                          if (eliminado) {
                            final updateMedicos = _medicoService.getMedicos();
                            setState(() {
                              _futureMedicos = updateMedicos;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Usuario eliminado correctamente',
                                ),
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
