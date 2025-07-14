import 'package:flutter/material.dart';
import 'package:frontend/models/especialidades.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/especialidades_service.dart';
import 'package:go_router/go_router.dart';

class EditarEspecialidadesPage extends StatefulWidget {
  final int id;

  const EditarEspecialidadesPage({super.key, required this.id});

  @override
  State<EditarEspecialidadesPage> createState() =>
      _EditarEspecialidadesPageState();
}

class _EditarEspecialidadesPageState extends State<EditarEspecialidadesPage> {
  // ! Se inicializa el servicio para obtener los datos del usuario
  // ! Se inicializa el key para el formulario
  //GlobalKey<FormState>() se usa para validar el formulario
  // y para acceder a los datos del formulario
  final _formKey = GlobalKey<FormState>();
  // Se inicializa el servicio para obtener los datos del usuario
  // y para actualizar los datos del usuario
  final _especialidadesService = EspecialidadesService();

  // **Se inicializan los controladores para los campos de texto
  String? NombreTipo;
  String? Estado;

  bool _loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEspecialidad(); // Cargar datos del usuario al iniciar
  }

  //! loadUsuario
  /// Carga los datos del usuario desde la API
  Future<void> _loadEspecialidad() async {
    try {
      // Obtener el usuario por ID
      final especialidad = await _especialidadesService
          .getEspecialidades()
          .then(
            (especialidades) =>
                especialidades.firstWhere((u) => u.id == widget.id),
          );

      if (!mounted) return;

      // Inicializar controladores con los valores de la especialidad
      NombreTipo = especialidad.nombre;
      Estado = especialidad.estado;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Error al cargar los datos de la especialidad';
        _loading = false;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final especialidadEditado = Especialidades(
      id: widget.id,
      nombre: NombreTipo!,
      estado: Estado!,
    );

    final success = await _especialidadesService.updateEspecialidades(
      especialidadEditado,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Especialidad actualizada correctamente')),
      );
      context.go('/gestionar/especialidades'); // Regresar a la vista anterior
    } else {
      setState(() {
        errorMessage = 'Error al actualizar el especialidad';
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
        title: const Text(
          'Editar Especialidad',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildDropdown('Nombre de especialidad', NombreTipo, [
                'Médico general', 'Psicólogo', 'Fisioterapeuta'
              ], (val) => setState(() => NombreTipo = val)),
              const SizedBox(height: 20),
             buildDropdown('Estado', Estado, [
                'Activo',
                'Inactivo',
              ], (val) => setState(() => Estado = val)),
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

  // Método para construir un campo de selección (Dropdown)
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
}
