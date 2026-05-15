import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/models/especialidades.dart';
import 'package:frontend/models/medico.dart';
import 'package:frontend/services/citas_service.dart';
import 'package:frontend/services/especialidades_service.dart';
import 'package:frontend/services/medico_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/widgets/common_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PedircitaPage extends StatefulWidget {
  const PedircitaPage({super.key});

  @override
  State<PedircitaPage> createState() => _PedircitaPageState();
}

class _PedircitaPageState extends State<PedircitaPage> {
  static const int _tarifaPorKmCOP = 2000;
  final _formKey = GlobalKey<FormState>();
  final _direccionController = TextEditingController();
  final _numeroViaController = TextEditingController();
  final _numeroViviendaController = TextEditingController();

  static String _stripDiacritics(String input) {
    const map = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'Á': 'a',
      'À': 'a',
      'Ä': 'a',
      'Â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'É': 'e',
      'È': 'e',
      'Ë': 'e',
      'Ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'Í': 'i',
      'Ì': 'i',
      'Ï': 'i',
      'Î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'Ó': 'o',
      'Ò': 'o',
      'Ö': 'o',
      'Ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'Ú': 'u',
      'Ù': 'u',
      'Ü': 'u',
      'Û': 'u',
      'ñ': 'n',
      'Ñ': 'n',
    };

    final b = StringBuffer();
    for (final ch in input.characters) {
      b.write(map[ch] ?? ch);
    }
    return b.toString();
  }

  static String _normKey(String s) =>
      _stripDiacritics(s).toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  static const List<String> _sintomasPsicologo = [
    'Ansiedad',
    'Depresión',
    'Estrés',
    'Estrés postraumático',
    'Insomnio',
    'Tristeza',
  ];

  static const List<String> _sintomasMedicoGeneral = [
    'Cansancio',
    'Congestión nasal',
    'Diarrea',
    'Dificultad para respirar',
    'Dolor abdominal',
    'Dolor al respirar',
    'Dolor de cabeza',
    'Dolor de estómago',
    'Dolor de garganta',
    'Dolor de oído',
    'Dolor en el pecho',
    'Escalofríos',
    'Falta de apetito',
    'Fiebre',
    'Flema',
    'Gripe',
    'Malestar estomacal',
    'Malestar general',
    'Mareos',
    'Migraña',
    'Náuseas',
    'Sensibilidad a la luz',
    'Tos',
    'Vómitos',
  ];

  static const List<String> _sintomasFisioterapeuta = [
    'Dolor articular',
    'Dolor de espalda',
    'Dolor de hombro',
    'Dolor de muñeca',
    'Dolor de pierna',
    'Dolor de rodillas',
    'Dolor en el cuello',
    'Dolor lumbar',
    'Dolor muscular',
    'Lesión en la pierna',
  ];

  static const Map<String, List<String>> _sintomasPorEspecialista = {
    // Psicólogo
    'psicologo': _sintomasPsicologo,
    'psicologia': _sintomasPsicologo,

    // Médico general
    'medico general': _sintomasMedicoGeneral,
    'medicina general': _sintomasMedicoGeneral,

    // Fisioterapeuta
    'fisioterapeuta': _sintomasFisioterapeuta,
    'fisioterapia': _sintomasFisioterapeuta,
  };

  final Set<String> _sintomasSeleccionados = <String>{};

  List<String> _sintomasDisponiblesParaEspecialidad() {
    final esp = _especialidadSeleccionada?.nombre;
    if (esp == null) return const [];
    final key = _normKey(esp);
    final list = _sintomasPorEspecialista[key];
    return (list ?? const [])..sort((a, b) => a.compareTo(b));
  }

  Future<void> _seleccionarSintomas(BuildContext context) async {
    final disponibles = _sintomasDisponiblesParaEspecialidad();
    if (disponibles.isEmpty) return;

    final seleccion = Set<String>.of(_sintomasSeleccionados);

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Selecciona síntomas'),
          content: StatefulBuilder(
            builder: (ctx, setLocalState) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: disponibles.length,
                  itemBuilder: (ctx, i) {
                    final item = disponibles[i];
                    final checked = seleccion.contains(item);
                    return CheckboxListTile(
                      value: checked,
                      title: Text(item),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setLocalState(() {
                          if (val == true) {
                            seleccion.add(item);
                          } else {
                            seleccion.remove(item);
                          }
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(seleccion),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      _sintomasSeleccionados
        ..clear()
        ..addAll(result);
      motivoConsultaController.text = _sintomasSeleccionados.join(', ');
    });
  }

  static const List<String> _barrios = [
    'Alameda',
    'Alvernia',
    'Americana de Vivienda',
    'Asoagrin - Farfán',
    'Bello Horizonte',
    'Bolívar',
    'Bosques de Maracaibo',
    'Buenos Aires',
    'Céspedes',
    'Chiminangos',
    'Ciudad Las Palmas',
    'Comfamiliar',
    'Comuneros',
    'Corazón del Valle',
    'El Dorado',
    'El Jazmín',
    'El Jardín',
    'El Limonar',
    'El Palmar',
    'El Pinar',
    'El Porvenir',
    'El Príncipe',
    'El Refugio',
    'Entre Ríos',
    'Estambul',
    'Fátima',
    'Flor de la Campana',
    'Horizonte',
    'Jorge Eliecer Gaitán',
    'La Ceiba',
    'La Esperanza',
    'La Graciela',
    'La Herradura',
    'La Independencia',
    'La Quinta',
    'La Rivera',
    'La Trinidad',
    'La Villa',
    'Las Brisas',
    'Las Delicias',
    'Lomitas',
    'Maracaibo',
    'Marandúa',
    'Morales',
    'Municipal',
    'Peñaranda',
    'Playas',
    'Popular',
    'Primero de Mayo',
    'Progresar',
    'Pueblo Nuevo',
    'Río Paila',
    'San Antonio',
    'San Benito',
    'San Luis',
    'San Pedro Claver',
    'Santa Inés',
    'Santa Isabel',
    'Santa Rita del Río',
    'Siete de Agosto',
    'Sintra',
    'Victoria',
    'Villa Colombia',
    'Villa del Río',
    'Villanueva',
  ];

  static const List<String> _tiposVia = [
    'Avenida',
    'Carrera',
    'Calle',
    'Diagonal',
    'Kilómetro',
    'Parque',
    'Plazoleta',
    'Transversal',
  ];

  String _formatearCalificacion(double valor) {
    return valor.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _estrellasCalificacion(double valor) {
    final v = valor.clamp(0, 5).toDouble();

    final llenas = v.round();
    final vacias = 5 - llenas;
    return '${'★' * llenas}${'☆' * vacias}';
  }

  Widget _medicoDropdownLabel(Medico m) {
    final cal = m.calificacion.clamp(0, 5).toDouble();
    return Row(
      children: [
        Expanded(
          child: Text(
            m.usuario.nombre,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_estrellasCalificacion(cal)} ${_formatearCalificacion(cal)}',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

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
  int? _valorBaseConsultaCOP; // precio base del médico
  int? _valorConsultaCOP; // total (base + distancia)
  int? _costoDistanciaCOP;
  double? _distanciaKm;

  // Campos de formulario
  final motivoConsultaController = TextEditingController();
  final fechaController = TextEditingController(); // yyyy-MM-dd
  TimeOfDay? _horaSeleccionada;
  String? _tipoConsultaSeleccionado; // 'Inmediata' | 'Agendada'
  String? _medioPagoSeleccionado; // 'Efectivo' | 'PSE'
  String? _modoDireccionSeleccionado; // 'Ubicación actual' | 'Otra'
  String? _barrioSeleccionado;
  String? _tipoViaSeleccionado;

  // Ubicación
  double? _latitud;
  double? _longitud;

  // Estado
  bool isLoading = false;
  String? errorMessage;

  String _googleMapsUrl(double lat, double lon) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
  }

  void _actualizarDireccionDesdeGps() {
    if (_latitud == null || _longitud == null) return;
    _direccionController.text = _googleMapsUrl(_latitud!, _longitud!);
  }

  Future<void> _recalcularValorConsulta() async {
    final medico = _medicoSeleccionado;
    final base = _valorBaseConsultaCOP;
    if (medico == null || base == null) {
      if (!mounted) return;
      setState(() {
        _distanciaKm = null;
        _costoDistanciaCOP = null;
        _valorConsultaCOP = base;
      });
      return;
    }

    if (_latitud == null || _longitud == null) {
      await _obtenerUbicacion();
    }

    if (_latitud == null || _longitud == null) {
      if (!mounted) return;
      setState(() {
        _distanciaKm = null;
        _costoDistanciaCOP = null;
        _valorConsultaCOP = base;
      });
      return;
    }

    final distanciaMetros = Geolocator.distanceBetween(
      _latitud!,
      _longitud!,
      medico.latitud,
      medico.longitud,
    );
    final distanciaKm = distanciaMetros / 1000;
    final costoDistancia = (distanciaKm * _tarifaPorKmCOP).round();
    final total = base + costoDistancia;

    if (!mounted) return;
    setState(() {
      _distanciaKm = distanciaKm;
      _costoDistanciaCOP = costoDistancia;
      _valorConsultaCOP = total;
    });
  }

  String _construirDireccionManual() {
    final barrio = (_barrioSeleccionado ?? '').trim();
    final tipoVia = (_tipoViaSeleccionado ?? '').trim();
    final numeroVia = _numeroViaController.text.trim();
    final numeroVivienda = _numeroViviendaController.text.trim();
    return 'Colombia, Valle del Cauca, Tuluá, $barrio, $tipoVia, $numeroVia, $numeroVivienda';
  }

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
      _valorBaseConsultaCOP = null;
      _valorConsultaCOP = null;
      _distanciaKm = null;
      _costoDistanciaCOP = null;
    });
    try {
      final lista = await _medicoService.getMedicos();
      setState(() {
        _medicos = lista
            .where(
              (m) =>
                  m.especialidad.id == especialidadId &&
                  m.estado.toLowerCase() == 'activo',
            )
            .toList();
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
        if (_modoDireccionSeleccionado == 'Ubicación actual') {
          _actualizarDireccionDesdeGps();
        }
      });
      await _recalcularValorConsulta();
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
  void dispose() {
    motivoConsultaController.dispose();
    fechaController.dispose();
    _direccionController.dispose();
    _numeroViaController.dispose();
    _numeroViviendaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(
        backgroundColor: Color.fromRGBO(21, 99, 161, 1),
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
                                    // Reset síntomas al cambiar especialidad
                                    _sintomasSeleccionados.clear();
                                    motivoConsultaController.clear();
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
                                            child: _medicoDropdownLabel(m),
                                          ))
                                      .toList(),
                                  onChanged: (val) async {
                                    setState(() {
                                      _medicoSeleccionado = val;
                                      _valorBaseConsultaCOP = null;
                                      _valorConsultaCOP = null;
                                      _distanciaKm = null;
                                      _costoDistanciaCOP = null;
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
                                        setState(() {
                                          _valorBaseConsultaCOP = precio;
                                          _valorConsultaCOP = precio;
                                        });
                                        await _recalcularValorConsulta();
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Valor cita:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text(_formatCOP(_valorConsultaCOP!),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                    if (_valorBaseConsultaCOP != null)
                                      Text(
                                        'Base: ${_formatCOP(_valorBaseConsultaCOP!)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    if (_distanciaKm != null &&
                                        _costoDistanciaCOP != null)
                                      Text(
                                        'Distancia: ${_distanciaKm!.toStringAsFixed(2)} km x COP 2.000 = ${_formatCOP(_costoDistanciaCOP!)}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: 300,
                          child: Builder(
                            builder: (ctx) {
                              final disponibles =
                                  _sintomasDisponiblesParaEspecialidad();
                              final hasEspecialidad =
                                  _especialidadSeleccionada != null;
                              final hasSintomas = disponibles.isNotEmpty;
                              final enabledSelector =
                                  hasEspecialidad && hasSintomas;

                              return TextFormField(
                                controller: motivoConsultaController,
                                readOnly: enabledSelector,
                                onTap: enabledSelector
                                    ? () => _seleccionarSintomas(ctx)
                                    : null,
                                decoration: InputDecoration(
                                  labelText: 'Motivo consulta (síntomas)*',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: enabledSelector
                                      ? const Icon(
                                          Icons.keyboard_arrow_down_outlined,
                                        )
                                      : const Icon(Icons.info_outline),
                                  helperText: enabledSelector
                                      ? 'Puedes seleccionar varios'
                                      : (hasEspecialidad
                                          ? 'Escribe el motivo o selecciona otra especialidad'
                                          : 'Selecciona una especialidad para ver síntomas'),
                                ),
                                validator: (value) {
                                  final v = (value ?? '').trim();
                                  if (v.isNotEmpty) return null;
                                  return enabledSelector
                                      ? 'Selecciona al menos un síntoma'
                                      : 'Este campo es obligatorio';
                                },
                              );
                            },
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
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Dirección*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            value: _modoDireccionSeleccionado,
                            items: const [
                              DropdownMenuItem(
                                value: 'Ubicación actual',
                                child: Text('Ubicación actual'),
                              ),
                              DropdownMenuItem(
                                value: 'Otra',
                                child: Text('Otra'),
                              ),
                            ],
                            onChanged: (val) async {
                              setState(() {
                                _modoDireccionSeleccionado = val;
                                if (val == 'Otra') {
                                  _direccionController.clear();
                                } else {
                                  _barrioSeleccionado = null;
                                  _tipoViaSeleccionado = null;
                                  _numeroViaController.clear();
                                  _numeroViviendaController.clear();
                                }
                              });

                              if (val == 'Ubicación actual') {
                                if (_latitud == null || _longitud == null) {
                                  await _obtenerUbicacion();
                                }
                                if (!mounted) return;
                                setState(() {
                                  _actualizarDireccionDesdeGps();
                                });
                                await _recalcularValorConsulta();
                              }
                            },
                            validator: (value) =>
                                value == null ? 'Selecciona una opción' : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_modoDireccionSeleccionado == 'Otra')
                          Column(
                            children: [
                              SizedBox(
                                width: 300,
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Barrio*',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.apartment),
                                  ),
                                  value: _barrioSeleccionado,
                                  items: _barrios
                                      .map(
                                        (b) => DropdownMenuItem(
                                          value: b,
                                          child: Text(b),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() => _barrioSeleccionado = val);
                                  },
                                  validator: (value) {
                                    if (_modoDireccionSeleccionado != 'Otra') {
                                      return null;
                                    }
                                    return value == null
                                        ? 'Selecciona un barrio'
                                        : null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 300,
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo de vía*',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.alt_route),
                                  ),
                                  value: _tipoViaSeleccionado,
                                  items: _tiposVia
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() => _tipoViaSeleccionado = val);
                                  },
                                  validator: (value) {
                                    if (_modoDireccionSeleccionado != 'Otra') {
                                      return null;
                                    }
                                    return value == null
                                        ? 'Selecciona un tipo de vía'
                                        : null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: _numeroViaController,
                                  decoration: const InputDecoration(
                                    labelText: 'Número de vía*',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.pin_outlined),
                                  ),
                                  validator: (value) {
                                    if (_modoDireccionSeleccionado != 'Otra') {
                                      return null;
                                    }
                                    return value == null || value.trim().isEmpty
                                        ? 'Este campo es obligatorio'
                                        : null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: _numeroViviendaController,
                                  decoration: const InputDecoration(
                                    labelText: 'Número de vivienda*',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.home_outlined),
                                  ),
                                  validator: (value) {
                                    if (_modoDireccionSeleccionado != 'Otra') {
                                      return null;
                                    }
                                    return value == null || value.trim().isEmpty
                                        ? 'Este campo es obligatorio'
                                        : null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        if (_modoDireccionSeleccionado == 'Ubicación actual')
                          SizedBox(
                            width: 300,
                            child: TextFormField(
                              controller: _direccionController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Dirección GPS',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.map_outlined),
                              ),
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
                                if (_modoDireccionSeleccionado == null) {
                                  throw Exception('Selecciona una dirección');
                                }

                                if (_modoDireccionSeleccionado ==
                                    'Ubicación actual') {
                                  if (_latitud == null || _longitud == null) {
                                    await _obtenerUbicacion();
                                  }
                                  if (_latitud == null || _longitud == null) {
                                    throw Exception(
                                      'No se pudo obtener la ubicación actual',
                                    );
                                  }
                                  _actualizarDireccionDesdeGps();
                                }
                                final lat = _latitud ?? 0.0;
                                final lon = _longitud ?? 0.0;
                                final direccion = _modoDireccionSeleccionado ==
                                        'Ubicación actual'
                                    ? _direccionController.text.trim()
                                    : _construirDireccionManual();

                                if (direccion.isEmpty) {
                                  throw Exception(
                                      'La dirección es obligatoria');
                                }

                                await _recalcularValorConsulta();
                                final precio =
                                    (_valorConsultaCOP ?? 0).toDouble();
                                final ok = await CitasService().crearCitaSimple(
                                  especialidadId:
                                      _especialidadSeleccionada!.id!,
                                  medicoId: _medicoSeleccionado!.id!,
                                  usuarioId: usuarioId,
                                  motivoConsulta:
                                      motivoConsultaController.text.trim(),
                                  tipoConsulta: _tipoConsultaSeleccionado!,
                                  fechaCita: fechaCita,
                                  direccion: direccion,
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
                                          barrierDismissible: false,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Pago aprobado'),
                                            content: Text(
                                              'Su cita fue aprobada, por favor espere al especialista o el especialista se pondra en contacto con usted.${txId.isNotEmpty ? '\n\nID de transaccion: $txId' : ''}',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                                child: const Text('Aceptar'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (!mounted) return;
                                        context.go('/historial/citasPaciente');
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
