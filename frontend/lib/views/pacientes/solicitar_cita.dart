import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/models/especialidades.dart';
import 'package:frontend/models/medico.dart';
import 'package:frontend/services/citas_service.dart';
import 'package:frontend/services/especialidades_service.dart';
import 'package:frontend/services/medico_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PedircitaPage extends StatefulWidget {
  const PedircitaPage({super.key});

  @override
  State<PedircitaPage> createState() => _PedircitaPageState();
}

class _PedircitaPageState extends State<PedircitaPage> {
  final _formKey = GlobalKey<FormState>();
  String _formatCOP(int value) {
    final s = value.toString();
    final withDots = s.replaceAllMapped(
      RegExp(r"\B(?=(\d{3})+(?!\d))"),
      (m) => '.',
    );
    return 'COP $withDots';
  }

  // Especialidades
  final _especialidadesService = EspecialidadesService();
  List<Especialidades> _especialidades = [];
  Especialidades? _especialidadSeleccionada;
  bool _cargandoEspecialidades = true;

  // Médicos
  final _medicoService = MedicoService();
  List<Medico> _medicos = [];
  Medico? _medicoSeleccionado;
  bool _cargandoMedicos = false;
  int? _valorConsultaCOP; // precio en COP del médico seleccionado

  // Campos de formulario
  final motivoConsultaController = TextEditingController();
  final fechaController = TextEditingController(); // yyyy-MM-dd
  final direccionController = TextEditingController();
  TimeOfDay? _horaSeleccionada;
  String? _tipoConsultaSeleccionado; // 'Inmediata' | 'Agendada'
  String? _medioPagoSeleccionado; // 'Efectivo' | 'PSE'

  // Ubicación
  double? _latitud;
  double? _longitud;

  // Estado
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarEspecialidades();
    _obtenerUbicacion();
  }

  Future<void> _cargarEspecialidades() async {
    try {
      final lista = await _especialidadesService.getEspecialidades();
      setState(() {
        // Mostrar TODAS las especialidades; si deseas ocultar inactivas, filtra aquí.
        _especialidades = List.of(lista)
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
        _cargandoEspecialidades = false;
      });
    } catch (e) {
      setState(() {
        _cargandoEspecialidades = false;
        errorMessage = 'Error cargando especialidades: $e';
      });
    }
  }

  Future<void> cargarMedicosPorEspecialidad(int especialidadId) async {
    setState(() {
      _cargandoMedicos = true;
      _medicos = [];
      _medicoSeleccionado = null;
      _valorConsultaCOP = null;
    });
    try {
      final lista = await _medicoService.getMedicos();
      setState(() {
        _medicos =
            lista.where((m) => m.especialidad.id == especialidadId).toList();
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error cargando médicos: $e';
      });
    } finally {
      setState(() {
        _cargandoMedicos = false;
      });
    }
  }

  Future<int?> _getUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('user');
    if (s == null) return null;
    try {
      final map = jsonDecode(s) as Map<String, dynamic>;
      final id = map['id'];
      if (id is int) return id;
      return int.tryParse(id?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> _obtenerUbicacion() async {
    try {
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.deniedForever ||
          permiso == LocationPermission.denied) {
        return; // Dejar lat/long null; validaremos antes de enviar
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitud = pos.latitude;
        _longitud = pos.longitude;
      });
    } catch (e) {
      // Ignorar y permitir continuar; lat/long quedarán null
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
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Selecciona una opción' : null,
      ),
    );
  }

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
          onPressed: () => context.go('/home/paciente'),
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
                const SizedBox(height: 16),
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
                                items: _especialidades
                                    .map((e) => e.nombre)
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _especialidadSeleccionada = _especialidades
                                        .firstWhere((e) => e.nombre == val);
                                    // Reset médico seleccionado al cambiar especialidad
                                    _medicoSeleccionado = null;
                                  });
                                  final id = _especialidadSeleccionada?.id;
                                  if (id != null)
                                    cargarMedicosPorEspecialidad(id);
                                },
                              ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 300,
                          child: _cargandoMedicos
                              ? const LinearProgressIndicator()
                              : DropdownButtonFormField<Medico>(
                                  decoration: const InputDecoration(
                                    labelText: 'Médico*',
                                    border: OutlineInputBorder(),
                                  ),
                                  key: ValueKey(
                                      'medicos_${_especialidadSeleccionada?.id ?? 'none'}'),
                                  // Asegura que el value sea la instancia contenida en items
                                  value: (() {
                                    if (_medicoSeleccionado == null)
                                      return null;
                                    final selId = _medicoSeleccionado!.id;
                                    if (selId == null) return null;
                                    final match =
                                        _medicos.where((m) => m.id == selId);
                                    return match.isNotEmpty
                                        ? match.first
                                        : null;
                                  })(),
                                  items: _medicos
                                      .map((m) => DropdownMenuItem(
                                            value: m,
                                            child: Text(m.usuario.nombre),
                                          ))
                                      .toList(),
                                  onChanged: (val) async {
                                    setState(() {
                                      _medicoSeleccionado = val;
                                      _valorConsultaCOP = null;
                                    });
                                    if (val?.id != null) {
                                      try {
                                        final int targetId =
                                            (val!.usuario.id != null)
                                                ? val.usuario.id!
                                                : val.id!;
                                        final precio = await _medicoService
                                            .getValorConsultaPorUsuario(
                                                targetId);
                                        if (!mounted) return;
                                        setState(
                                            () => _valorConsultaCOP = precio);
                                      } catch (e) {
                                        if (!mounted) return;
                                        setState(() => errorMessage =
                                            'No se pudo obtener el valor de la consulta: $e');
                                      }
                                    }
                                  },
                                  validator: (val) => val == null
                                      ? 'Selecciona un médico'
                                      : null,
                                ),
                        ),
                        const SizedBox(height: 16),
                        if (_valorConsultaCOP != null)
                          SizedBox(
                            width: 300,
                            child: Card(
                              color: const Color(0xFFF4F6F8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Valor consulta:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(_formatCOP(_valorConsultaCOP!),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ].map((w) {
                                    return w;
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: 300,
                          child: TextFormField(
                            controller: motivoConsultaController,
                            decoration: const InputDecoration(
                              labelText: 'Motivo consulta*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            validator: (value) => value == null || value.isEmpty
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
                            items: const [
                              DropdownMenuItem(
                                  value: 'Inmediata', child: Text('Inmediata')),
                              DropdownMenuItem(
                                  value: 'Agendada', child: Text('Agendada')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _tipoConsultaSeleccionado = val;
                                if (val == 'Inmediata') {
                                  fechaController.clear();
                                  _horaSeleccionada = null;
                                }
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Selecciona una opción' : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_tipoConsultaSeleccionado == 'Agendada') ...[
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
                                  final hora = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  setState(() {
                                    _horaSeleccionada = hora;
                                    fechaController.text = picked
                                        .toLocal()
                                        .toString()
                                        .split(' ')
                                        .first;
                                  });
                                }
                              },
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Selecciona una fecha'
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: 300,
                          child: TextFormField(
                            controller: direccionController,
                            decoration: const InputDecoration(
                              labelText: 'Dirección*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Este campo es obligatorio'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 300,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Medio de pago*',
                              border: OutlineInputBorder(),
                            ),
                            value: _medioPagoSeleccionado,
                            items: const [
                              DropdownMenuItem(
                                  value: 'Efectivo', child: Text('Efectivo')),
                              DropdownMenuItem(
                                  value: 'PSE', child: Text('PSE')),
                            ],
                            onChanged: (val) =>
                                setState(() => _medioPagoSeleccionado = val),
                            validator: (value) => value == null
                                ? 'Selecciona un medio de pago'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 300,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() {
                                isLoading = true;
                                errorMessage = null;
                              });

                              try {
                                if (_especialidadSeleccionada?.id == null) {
                                  throw Exception(
                                      'Selecciona una especialidad');
                                }
                                if (_medicoSeleccionado?.id == null) {
                                  throw Exception('Selecciona un médico');
                                }

                                final usuarioId = await _getUsuarioId();
                                if (usuarioId == null) {
                                  throw Exception(
                                      'No se pudo obtener el usuario autenticado');
                                }

                                // Construir fecha y hora
                                DateTime fechaCita;
                                if (_tipoConsultaSeleccionado == 'Agendada') {
                                  final fechaTxt = fechaController.text.trim();
                                  final partes = fechaTxt.split('-');
                                  if (partes.length != 3) {
                                    throw Exception('Fecha inválida');
                                  }
                                  final y = int.parse(partes[0]);
                                  final m = int.parse(partes[1]);
                                  final d = int.parse(partes[2]);
                                  final hora = _horaSeleccionada ??
                                      const TimeOfDay(hour: 9, minute: 0);
                                  fechaCita =
                                      DateTime(y, m, d, hora.hour, hora.minute);
                                } else {
                                  fechaCita = DateTime.now();
                                }

                                // Ubicación
                                if (_latitud == null || _longitud == null) {
                                  await _obtenerUbicacion();
                                }
                                final lat = _latitud ?? 0.0;
                                final lon = _longitud ?? 0.0;

                                final precio =
                                    _valorConsultaCOP?.toDouble() ?? 0.0;
                                final ok = await CitasService().crearCitaSimple(
                                  especialidadId:
                                      _especialidadSeleccionada!.id!,
                                  medicoId: _medicoSeleccionado!.id!,
                                  usuarioId: usuarioId,
                                  motivoConsulta:
                                      motivoConsultaController.text.trim(),
                                  tipoConsulta: _tipoConsultaSeleccionado!,
                                  fechaCita: fechaCita,
                                  direccion: direccionController.text.trim(),
                                  medioPago: _medioPagoSeleccionado!,
                                  latitud: lat,
                                  longitud: lon,
                                  precio: precio,
                                );

                                if (!mounted) return;
                                if (ok) {
                                  // Si el medio de pago es PSE, redirigir al flujo de Wompi Sandbox.
                                  if (_medioPagoSeleccionado == 'PSE') {
                                    final monto = (_valorConsultaCOP ?? 15000);
                                    final extra = {
                                      'montoCOP': monto, // Monto del médico
                                      'referencia':
                                          'CITA-${DateTime.now().millisecondsSinceEpoch}',
                                      // Puedes configurar WOMPI_REDIRECT_URL en .env si deseas capturar el retorno
                                    };
                                    final result = await context
                                        .push('/pago/wompi', extra: extra);
                                    // Manejo del resultado del flujo Wompi (con polling)
                                    if (result is Map) {
                                      final status = (result['status'] ?? '')
                                          .toString()
                                          .toUpperCase();
                                      final txId =
                                          (result['transactionId'] ?? '')
                                              .toString();

                                      if (status == 'APPROVED') {
                                        await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Pago aprobado'),
                                            content: Text(
                                              'Tu pago PSE fue aprobado.${txId.isNotEmpty ? '\nRef: $txId' : ''}',
                                            ),
                                          ),
                                        );
                                        if (!mounted) return;
                                        context.go('/home/paciente');
                                      } else if (status == 'DECLINED') {
                                        await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Pago rechazado'),
                                            content: Text(
                                              'El pago fue rechazado.${txId.isNotEmpty ? '\nRef: $txId' : ''}',
                                            ),
                                          ),
                                        );
                                      } else {
                                        // PENDING u otro estado/timeout
                                        await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Pago pendiente'),
                                            content: Text(
                                              'Tu pago PSE quedó pendiente de confirmación.${txId.isNotEmpty ? '\nRef: $txId' : ''}',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } else {
                                    // Efectivo: confirmación normal
                                    await showDialog(
                                      context: context,
                                      builder: (_) => const AlertDialog(
                                        title: Text('Cita solicitada'),
                                        content: Text(
                                            'Tu cita fue registrada exitosamente.'),
                                      ),
                                    );
                                    if (!mounted) return;
                                    context.go('/home/paciente');
                                  }
                                  // Nota: para PSE solo navegamos cuando el estado sea APPROVED
                                } else {
                                  setState(() => errorMessage =
                                      'Error al registrar la cita.');
                                }
                              } catch (e) {
                                if (!mounted) return;
                                setState(() => errorMessage = e.toString());
                              } finally {
                                if (mounted) {
                                  setState(() => isLoading = false);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(21, 99, 161, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Solicitar cita',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          )
                        ],
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
