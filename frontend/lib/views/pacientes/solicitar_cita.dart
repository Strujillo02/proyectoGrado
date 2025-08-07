import 'package:flutter/material.dart';
import 'package:frontend/models/citas.dart';
import 'package:frontend/models/especialidades.dart';
import 'package:frontend/services/citas_service.dart';
import 'package:frontend/services/especialidades_service.dart';
import 'package:go_router/go_router.dart';

//Pantalla principal para solicitar una cita
class PedircitaPage extends StatefulWidget {
  const PedircitaPage({super.key});

  @override
  State<PedircitaPage> createState() => _PedircitaPageState();
}

class _PedircitaPageState extends State<PedircitaPage> {
  //Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();

  //Variables para especialidades
  List<Especialidades> _especialidades = [];
  Especialidades? _especialidadSeleccionada;
  final EspecialidadesService _especialidadesService = EspecialidadesService();
  bool _cargandoEspecialidades = true;

  //Controladores para cada campo del formulario de citas
  final motivoConsultaController = TextEditingController();
  final ubicacionController = TextEditingController();
  final fechaController = TextEditingController();
  String? _tipoConsultaSeleccionado;

  // Control de carga y mensajes de error
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
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

  //Método para construir el formulario de solicitud de cita
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color.fromARGB(255, 215, 215, 218),
          ),
          onPressed:
              () => context.go(
                '/home/paciente',
              ), //regrear a la pantalla de inicio del paciente
          iconSize: 35,
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //Título de la pantalla
                const Padding(
                  padding: EdgeInsets.only(top: 25, bottom: 1),
                  child: Text(
                    'Solicitar Cita',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(21, 99, 161, 1),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _cargandoEspecialidades
                            ? const CircularProgressIndicator()
                            : buildDropdownField(
                              label: 'Especialidad',
                              value: _especialidadSeleccionada?.nombre,
                              items:
                                  _especialidades.map((e) => e.nombre).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _especialidadSeleccionada = _especialidades
                                      .firstWhere((e) => e.nombre == val);
                                });
                              },
                            ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 300,
                          child: TextFormField(
                            controller: motivoConsultaController,
                            decoration: const InputDecoration(
                              labelText: 'Motivo consulta*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Este campo es obligatorio'
                                        : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 300,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Tipo de consulta*',
                              border: OutlineInputBorder(),
                            ),
                            value: _tipoConsultaSeleccionado,
                            items:
                                ['Inmediata', 'Agendada']
                                    .map(
                                      (tipo) => DropdownMenuItem(
                                        value: tipo,
                                        child: Text(tipo),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              setState(() {
                                _tipoConsultaSeleccionado = val;
                              });
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Selecciona una opción'
                                        : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 300,
                          child: TextFormField(
                            controller: ubicacionController,
                            readOnly: false,
                            decoration: const InputDecoration(
                              labelText: 'Ubicación*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Este campo es obligatorio'
                                        : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 300,
                          child: TextFormField(
                            controller: fechaController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Seleccione la fecha*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  fechaController.text =
                                      picked.toLocal().toString().split(' ')[0];
                                });
                              }
                            },
                            validator:
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Selecciona una fecha'
                                        : null,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 300,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  isLoading = true;
                                  errorMessage = null;
                                });

                               /* try {
                                  final now = DateTime.now();
                                  final nuevaCita = Citas(
                                    especialidad: _especialidadSeleccionada!,
                                    fecha_registro: now,
                                    motivo_consulta:
                                        motivoConsultaController.text,
                                    precio:
                                        '0', 
                                    estado: 'Pendiente',
                                    tipo_consulta: _tipoConsultaSeleccionado!,
                                    fecha_cita: DateTime.parse(
                                      fechaController.text,
                                    ),
                                    latitud:
                                        0.0, 
                                    longitud: 0.0,
                                   /* medico:
                                        Medico.empty(), // Debes ajustar esto con el médico real
                                    usuario:
                                        User.empty(), // Ajusta según el usuario autenticado*/
                                  );

                                  final success = await CitasService()
                                      .createCitas(nuevaCita);

                                  if (success) {
                                    if (!mounted) return;
                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => AlertDialog(
                                            title: const Text(
                                              'Cita solicitada',
                                            ),
                                            content: const Text(
                                              'Tu cita fue registrada exitosamente.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  context.go('/home/paciente');
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          ),
                                    );
                                  } else {
                                    setState(() {
                                      errorMessage =
                                          'Error al registrar la cita.';
                                    });
                                  }
                                } catch (e) {
                                  setState(() {
                                    errorMessage = 'Error: ${e.toString()}';
                                  });
                                } finally {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }*/
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(
                                21,
                                99,
                                161,
                                1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      'Solicitar cita',
                                      style: TextStyle(color: Colors.white),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
