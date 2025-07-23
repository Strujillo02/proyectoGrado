import 'package:flutter/material.dart';
import 'package:frontend/models/medico.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/especialidades.dart';
import 'package:frontend/services/especialidades_service.dart';
import 'package:frontend/services/medico_service.dart';
import 'package:go_router/go_router.dart';

class EditarMedicoPage extends StatefulWidget {
  final int id;

  const EditarMedicoPage({super.key, required this.id});

  @override
  State<EditarMedicoPage> createState() => _EditarMedicoPageState();
}

class _EditarMedicoPageState extends State<EditarMedicoPage> {
  final _formKey = GlobalKey<FormState>();
  final _medicoService = MedicoService();

  // Controladores inicializados vacíos
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController identificacionController =
      TextEditingController();
  final TextEditingController direccionController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();
  final TextEditingController tarjetaProfeController = TextEditingController();

  String? _selectedEstadoMedico;
  String? _selectedDocumentType;
  String? _selectedUserType;
  String? _selectedGenero;
  String? _selectedEstado;

  bool _loading = true;
  String? errorMessage;

Medico? _medicoOriginal;


  // Variables para especialidades
  List<Especialidades> _especialidades = [];
  Especialidades? _especialidadSeleccionada;
  final EspecialidadesService _especialidadesService = EspecialidadesService();
  bool _cargandoEspecialidades = true;

  @override
  void initState() {
    super.initState();
    _loadMedico();
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

  Future<void> _loadMedico() async {
  try {
    final medico = await _medicoService.getMedicos().then(
      (medicos) => medicos.firstWhere((m) => m.id == widget.id),
    );

    if (!mounted) return;

    _medicoOriginal = medico; 

    // Llenar campos del formulario
    nombreController.text = medico.usuario.nombre;
    emailController.text = medico.usuario.email;
    telefonoController.text = medico.usuario.telefono ?? '';
    identificacionController.text = medico.usuario.identificacion;
    direccionController.text = medico.usuario.direccion ?? '';
    contrasenaController.text = medico.usuario.contrasena ?? '';
    tarjetaProfeController.text = medico.tarjetaProfe;
    _especialidadSeleccionada = medico.especialidad;
    _selectedEstadoMedico = medico.estado;
    _selectedDocumentType = medico.usuario.tipo_identificacion;
    _selectedUserType = medico.usuario.tipo_usuario;
    _selectedGenero = medico.usuario.genero;
    _selectedEstado = medico.usuario.estado;

    setState(() => _loading = false);
  } catch (e) {
    if (!mounted) return;
    setState(() {
      errorMessage = 'Error al cargar los datos del medico';
      _loading = false;
    });
  }
}


  Future<void> _guardarCambios() async {
  if (!_formKey.currentState!.validate()) return;
  if (_medicoOriginal == null) return;

  final medicoEditado = Medico(
    id: widget.id,
    especialidad: _especialidadSeleccionada!,
    usuario: User(
      id: _medicoOriginal!.usuario.id, 
      nombre: nombreController.text.trim(),
      email: emailController.text.trim(),
      telefono: telefonoController.text.trim(),
      identificacion: identificacionController.text.trim(),
      direccion: direccionController.text.trim(),
      contrasena: contrasenaController.text.trim(),
      tipo_identificacion: _selectedDocumentType ?? '',
      tipo_usuario: _selectedUserType ?? '',
      genero: _selectedGenero,
      estado: _selectedEstado ?? 'Activo',
    ),
    estado: _selectedEstadoMedico ?? 'Activo',
    tarjetaProfe: tarjetaProfeController.text.trim(),
  );

  final success = await _medicoService.updateMedicos(medicoEditado);

  if (success && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Médico actualizado correctamente')),
    );
    context.go('/gestionar/usuarios');
  } else {
    setState(() {
      errorMessage = 'Error al actualizar el médico';
    });
  }
}


  @override
  void dispose() {
    nombreController.dispose();
    emailController.dispose();
    telefonoController.dispose();
    identificacionController.dispose();
    direccionController.dispose();
    contrasenaController.dispose();
    tarjetaProfeController.dispose();
    super.dispose();
  }

  Widget buildTextField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          (value) =>
              value == null || value.isEmpty
                  ? 'Este campo es obligatorio'
                  : null,
    );
  }

  Widget buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Seleccione una opción' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Médico'),
        backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
              buildDropdown(
                'Tipo de documento',
                _selectedDocumentType,
                const [
                  'Cedula de ciudadania',
                  'Pasaporte',
                  'Cedula de extranjeria',
                ],
                (val) => setState(() => _selectedDocumentType = val),
              ),
              const SizedBox(height: 12),
              buildDropdown(
                'Tipo de usuario',
                _selectedUserType,
                const ['Paciente', 'Medico', 'Administrador'],
                (val) => setState(() => _selectedUserType = val),
              ),
              const SizedBox(height: 12),
              buildDropdown(
                'Género',
                _selectedGenero,
                const ['Masculino', 'Femenino'],
                (val) => setState(() => _selectedGenero = val),
              ),
              const SizedBox(height: 12),
              buildDropdown(
                'Estado de usuario',
                _selectedEstado,
                const ['Activo', 'Inactivo'],
                (val) => setState(() => _selectedEstado = val),
              ),
              const SizedBox(height: 12),
              _cargandoEspecialidades
                  ? const CircularProgressIndicator()
                  : buildDropdown(
                    'Especialidad',
                    _especialidadSeleccionada?.nombre,
                    _especialidades.map((e) => e.nombre).toList(),
                    (val) {
                      setState(() {
                        _especialidadSeleccionada = _especialidades.firstWhere(
                          (e) => e.nombre == val,
                        );
                      });
                    },
                  ),
              const SizedBox(height: 12),
              buildDropdown(
                'Estado de médico',
                _selectedEstadoMedico,
                const ['Activo', 'Inactivo'],
                (val) => setState(() => _selectedEstadoMedico = val),
              ),
              const SizedBox(height: 12),
              buildTextField(tarjetaProfeController, 'Tarjeta profesional'),
              const SizedBox(height: 20),
              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
                ),
                child: const Text(
                  'Guardar cambios',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
