import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/citas_service.dart';
import 'package:frontend/models/citas.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HistorialCitasPacientePage extends StatefulWidget {
  const HistorialCitasPacientePage({super.key});

  @override
  State<HistorialCitasPacientePage> createState() => _HistorialCitasPacientePageState();
}

class _HistorialCitasPacientePageState extends State<HistorialCitasPacientePage> {
  int _tabIndex = 0; // 0 = Pendientes, 1 = Completadas
  final _citasService = CitasService();
  final _authService = AuthService();
  List<Citas> _todas = [];
  bool _cargando = true;
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
      final lista = await _citasService.getCitasPorUsuarioid(user!.id!);
      setState(() => _todas = lista);
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
      // Barra azul solo con flecha blanca para volver al home del médico
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(21, 99, 161, 1),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Cambia la ruta según tu home de médico
            context.go('/home/paciente');
            // Si no usas go_router: Navigator.of(context).pop();
          },
        ),
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
          const SizedBox(height: 16),
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

    final pendientes =
        _todas.where((c) => c.estado.toUpperCase() == 'PENDIENTE').toList();
    final completadas =
        _todas.where((c) => c.estado.toUpperCase() == 'CONFIRMADA').toList();
    final lista = _tabIndex == 0 ? pendientes : completadas;

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

  Widget _citaCard(Citas c) {
    final completada = c.estado.toUpperCase() == 'CONFIRMADA';
    // Uso de locale 'es' ya inicializado en initState
    final rawFecha =
        DateFormat('HH:mmEEEE, d, MMM, y', 'es').format(c.fecha_cita.toLocal());
    final fechaTxt = rawFecha.isNotEmpty
        ? rawFecha[0].toUpperCase() + rawFecha.substring(1)
        : rawFecha;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: completada
                      ? const Color(0xFFDDE9F3)
                      : const Color(0xFFE9EDF1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  completada ? 'Completado' : 'En proceso',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: completada
                        ? const Color.fromRGBO(21, 99, 161, 1)
                        : const Color(0xFF586471),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
