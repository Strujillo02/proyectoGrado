// Pantalla principal para crear y listar especilidades
import 'package:flutter/material.dart';
import 'package:frontend/models/especialidades.dart';
import 'package:frontend/services/especialidades_service.dart';
import 'package:go_router/go_router.dart';

class EspecialidadesManagementPage extends StatefulWidget {
  const EspecialidadesManagementPage({super.key});

  @override
  State<EspecialidadesManagementPage> createState() =>
      _EspecialidadesManagementPageState();
}

class _EspecialidadesManagementPageState
    extends State<EspecialidadesManagementPage> {
  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controladores para cada campo del formulario
  String? _selectedNombreTipo;
  String? _selectedEstado;

  // Instancia del servicio que conecta con la API
  final EspecialidadesService _especialidadesService = EspecialidadesService();

  // Lista futura de especialidades, para la vista de listar
  late Future<List<Especialidades>> _futureEspecialidades;

  // Control de carga y mensajes de error
  bool isLoading = false;
  String? errorMessage;

  // Variable que determina si estamos creando o listando
  String currentView = 'listar';

  // Cuando inicia la pantalla, se cargan las especialidades
  @override
  void initState() {
    super.initState();
    _futureEspecialidades = _especialidadesService.getEspecialidades();
  }

  // Función que se llama al presionar el botón "Crear especialidad"
  void register() async {
    // Si el formulario no es válido, no hace nada
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    // Verifica si la especialidad ya existe
    final existe = await _especialidadesService.existeEspecialidadConNombre(
      _selectedNombreTipo!,
    );
    if (existe) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La especialidad ya existe con ese nombre'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Crea un objeto especialidad con los datos del formulario
    final newEspecialidades = Especialidades(
      nombre: _selectedNombreTipo.toString(),
      estado: _selectedEstado.toString(),
    );

    final success = await _especialidadesService.createEspecialidades(
      newEspecialidades,
    );

    if (success) {
      // Si fue exitoso, limpiar el formulario
      setState(() {
        _selectedNombreTipo = null;
        _selectedEstado = null;
        _futureEspecialidades = _especialidadesService.getEspecialidades();
        currentView = 'listar';
        isLoading = false;
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Especialidad creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        errorMessage = 'No se pudo crear la especialidad';
        isLoading = false;
      });
    }
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
                    'Gestión de especialidades',
                    style: TextStyle(
                      fontSize: 31,
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
                            'Crear especialidad',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Botón "Listar especialidades"
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              currentView = 'listar';
                              _futureEspecialidades =
                                  _especialidadesService
                                      .getEspecialidades(); // Recarga la lista
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
                            'Listar especialidades',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

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

  // Construye el formulario de creación de una especialidad
  Widget buildCreateForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'Formulario de creación de especialidades',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(21, 99, 161, 1),
            ),
          ),
          const SizedBox(height: 5),
          Image.asset('assets/images/logo.png', height: 270),
          const SizedBox(height: 15),

          // Campos del formulario
          buildDropdownField(
            label: 'Nombre de especialidad*',
            value: _selectedNombreTipo,
            items: const ['Médico general', 'Psicólogo', 'Fisioterapeuta'],
            onChanged: (val) => setState(() => _selectedNombreTipo = val),
          ),
          const SizedBox(height: 20),

          buildDropdownField(
            label: 'Estado*',
            value: _selectedEstado,
            items: const ['Activo', 'Inativo'],
            onChanged: (val) => setState(() => _selectedEstado = val),
          ),
          const SizedBox(height: 16),
          // Botón para crear especialidad
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
                        'Crear especialidad',
                        style: TextStyle(color: Colors.white),
                      ),
            ),
          ),
          const SizedBox(height: 20),
        ],
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

  // Lista de especialidades con opción de eliminar
  Widget buildUserList() {
    return FutureBuilder<List<Especialidades>>(
      future: _futureEspecialidades,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No hay especialidades disponibles');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final especialidades = snapshot.data![index];
            return Card(
              color: const Color.fromARGB(255, 208, 221, 233),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(especialidades.nombre),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('Estado: ${especialidades.estado}')],
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
                        context.go(
                          '/especialidades/editar/${especialidades.id}',
                        );
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
                                title: const Text('¿Eliminar especialidad?'),
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
                          final eliminado = await _especialidadesService
                              .deleteEspecialidad(especialidades.id!);
                          if (eliminado) {
                            final updateEspecialidades =
                                _especialidadesService.getEspecialidades();
                            setState(() {
                              _futureEspecialidades = updateEspecialidades;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Especialidad eliminad correctamente',
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error al eliminar la especialidad',
                                ),
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
