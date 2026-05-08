import 'package:flutter/material.dart';
import 'package:frontend/widgets/common_appbar.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/citas_service.dart';
import 'package:frontend/models/citas.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HistorialCitasPage extends StatefulWidget {
  const HistorialCitasPage({super.key});

  @override
  State<HistorialCitasPage> createState() => _HistorialCitasPageState();
}

class _HistorialCitasPageState extends State<HistorialCitasPage> {
  int _tabIndex = 0; // 0 = Pendientes, 1 = Completadas
  final _citasService = CitasService();
  final _authService = AuthService();
  List<Citas> _todas = [];
  final TextEditingController _filterController = TextEditingController();
  String _filterText = '';
  bool _cargando = true;
  int? _actualizandoCitaId;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Inicializa datos de localización para evitar LocaleDataException
    initializeDateFormatting('es').then((_) => _cargar());
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final user = await _authService.getUser();
      if (user?.id == null) {
        setState(() => _error = 'No se pudo determinar el usuario logueado');
        return;
      }
      // Intenta primero con el endpoint específico del usuario
      try {
        final lista = await _citasService.getCitasPorUsuario(user!.id!);
        setState(() => _todas = lista);
      } catch (e) {
        // Si falla, obtiene todas las citas y filtra localmente
        debugPrint('Fallback: obteniendo todas las citas - $e');
        final todasLasCitas = await _citasService.getCitas();
        final citasDelUsuario = todasLasCitas
            .where((cita) => cita.usuario.id == user!.id!)
            .toList();
        setState(() => _todas = citasDelUsuario);
      }
    } catch (e) {
      setState(() => _error = 'Error cargando citas: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(
        backgroundColor: Color.fromRGBO(21, 99, 161, 1),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título debajo de la barra azul
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Center(
              child: Text(
                'Historial de citas',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(21, 99, 161, 1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _segmented(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _filterController,
              decoration: InputDecoration(
                hintText: 'Filtrar por paciente, médico, motivo o especialidad',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filterText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterController.clear();
                          setState(() {
                            _filterText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (v) => setState(() => _filterText = v.trim()),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _segmented() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFE3EEF6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _segmentButton(index: 0, label: 'Pendientes'),
            _segmentButton(index: 1, label: 'Completadas'),
          ],
        ),
      ),
    );
  }

  Widget _segmentButton({required int index, required String label}) {
    final selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!selected) setState(() => _tabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected
                  ? const Color.fromRGBO(21, 99, 161, 1)
                  : const Color(0xFF5A6572),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _cargar,
                child: const Text('Reintentar'),
              )
            ],
          ),
        ),
      );
    }

    final pendientes = _todas.where((c) => !c.esCompletada).toList();
    final completadas = _todas.where((c) => c.esCompletada).toList();
    // Order newest to oldest
    final baseList = _tabIndex == 0 ? pendientes : completadas;
    baseList.sort((a, b) => b.fecha_cita.compareTo(a.fecha_cita));

    // Apply filter if present
    final lista = _filterText.isEmpty
        ? baseList
        : baseList.where((c) {
            final q = _filterText.toLowerCase();
            final paciente = c.usuario.nombre.toLowerCase();
            final medico = c.medico.usuario.nombre.toLowerCase();
            final motivo = c.motivo_consulta.toLowerCase();
            final esp = c.especialidad.nombre.toLowerCase();
            return paciente.contains(q) ||
                medico.contains(q) ||
                motivo.contains(q) ||
                esp.contains(q);
          }).toList();

    if (lista.isEmpty) {
      return Center(
        child: Text(
          _tabIndex == 0
              ? 'No hay citas pendientes'
              : 'No hay citas completadas',
          style: const TextStyle(color: Color(0xFF586471)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        itemCount: lista.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => _citaCard(lista[i]),
      ),
    );
  }

  Future<void> _marcarComoCompletada(Citas cita) async {
    if (cita.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar la cita')),
      );
      return;
    }

    setState(() {
      _actualizandoCitaId = cita.id;
      _error = null;
    });

    final citaActualizada = Citas(
      id: cita.id,
      especialidad: cita.especialidad,
      fecha_registro: cita.fecha_registro,
      motivo_consulta: cita.motivo_consulta,
      precio: cita.precio,
      estado: 'CONFIRMADA',
      tipo_consulta: cita.tipo_consulta,
      fecha_cita: cita.fecha_cita,
      latitud: cita.latitud,
      longitud: cita.longitud,
      medico: cita.medico,
      usuario: cita.usuario,
      respuesta_medico: cita.respuesta_medico,
    );

    try {
      final ok = await _citasService.marcarComoCompletada(cita);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar el estado de la cita')),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _todas = _todas.map((c) {
          if (c.id == cita.id) return citaActualizada;
          return c;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita marcada como completada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error actualizando la cita: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actualizandoCitaId = null;
        });
      }
    }
  }

  Widget _citaCard(Citas c) {
    final completada = c.esCompletada;
    final puedeCompletar = c.esPendiente;
    // Uso de locale 'es' ya inicializado en initState
    final rawFecha =
        DateFormat('EEEE d, HH:mm', 'es').format(c.fecha_cita.toLocal());
    final fechaTxt = rawFecha.isNotEmpty
        ? rawFecha[0].toUpperCase() + rawFecha.substring(1)
        : rawFecha;
    // Set background color based on tipo_consulta
    final tipoLower = c.tipo_consulta.toLowerCase();
    final Color cardColor = tipoLower.contains('agend')
        ? const Color(0xFFfbf9be) // agendada
        : tipoLower.contains('inmedi')
            ? const Color(0xFFffc2d2) // inmediata
            : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
        border: Border.all(
          color: const Color(0xFFE0E6EC),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.motivo_consulta,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2A33),
                    ),
                  ),
                ),
                Icon(
                  completada
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: completada
                      ? const Color.fromRGBO(21, 99, 161, 1)
                      : const Color(0xFF9AA6B5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              fechaTxt,
              style: const TextStyle(
                fontSize: 13,
                color: Color.fromRGBO(21, 99, 161, 1),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Especialidad: ${c.especialidad.nombre}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5A6572)),
            ),
            Text(
              'Paciente: ${c.usuario.nombre}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5A6572)),
            ),
            Text(
              'Médico: ${c.medico.usuario.nombre}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5A6572)),
            ),
            // Precio / valor de la consulta
            Builder(builder: (_) {
              // Usa el getter del modelo que prioriza el valor del médico y si no, parsea 'precio'.
              final double valor = c.valor_consulta;
              final miles = valor.toStringAsFixed(0).replaceAllMapped(
                  RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
              return Text(
                'Precio: COP $miles',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A6572)),
              );
            }),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!completada && puedeCompletar)
                  ElevatedButton.icon(
                    onPressed: _actualizandoCitaId == c.id
                        ? null
                        : () => _marcarComoCompletada(c),
                    icon: _actualizandoCitaId == c.id
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 16),
                    label: const Text('Marcar completada'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: completada
                        ? const Color(0xFFDDE9F3)
                        : const Color(0xFFE9EDF1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    completada ? 'Completada' : c.estadoLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: completada
                          ? const Color.fromRGBO(21, 99, 161, 1)
                          : const Color(0xFF586471),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
