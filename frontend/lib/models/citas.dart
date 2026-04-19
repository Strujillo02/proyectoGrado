import 'package:frontend/models/especialidades.dart';
import 'package:frontend/models/medico.dart';
import 'package:frontend/models/user.dart';

class Citas {
  final int? id;

  final Especialidades especialidad;
  final DateTime fecha_registro;
  final String motivo_consulta;
  final String precio;
  final String estado;
  final String tipo_consulta;
  final DateTime fecha_cita;
  final double latitud;
  final double longitud;
  final Medico medico;
  final User usuario;
  final String respuesta_medico;

  Citas({
    this.id,
    required this.especialidad,
    required this.fecha_registro,
    required this.motivo_consulta,
    required this.precio,
    required this.estado,
    required this.tipo_consulta,
    required this.fecha_cita,
    required this.latitud,
    required this.longitud,
    required this.medico,
    required this.usuario,
    this.respuesta_medico = '',
  });

  // Método para convertir un mapa a un objeto Citas
  factory Citas.fromJson(Map<String, dynamic> json) => Citas(
        id: json['id'],
        especialidad: Especialidades.fromJson(json['especialidad']),
        fecha_registro: DateTime.parse(json['fecha_registro']),
        motivo_consulta: json['motivo_consulta'],
        precio: (json['precio'] ?? '0').toString(),
        estado: Citas._normalizeEstado(json['estado']),
        tipo_consulta: json['tipo_consulta'],
        fecha_cita: DateTime.parse(json['fecha_cita']),
        latitud: Citas._parseDouble(json['latitud']),
        longitud: Citas._parseDouble(json['longitud']),
        medico: Medico.fromJson(json['medico']),
        usuario: User.fromJson(json['usuario']),
        respuesta_medico: json['respuesta_medico'] ?? '',
      );

  // Método para convertir un objeto Cita a un mapa
  Map<String, dynamic> toJson() => {
        'id': id,
        'especialidad': especialidad.toJson(),
        'fecha_registro': fecha_registro.toIso8601String(),
        'motivo_consulta': motivo_consulta,
        'precio': precio,
        'estado': estado,
        'tipo_consulta': tipo_consulta,
        'fecha_cita': fecha_cita.toIso8601String(),
        'latitud': latitud,
        'longitud': longitud,
        'medico': medico.toJson(),
        'usuario': usuario.toJson(),
        'respuesta_medico': respuesta_medico,
      };

  // Normaliza el estado recibido del backend para evitar nulls y mantener valores canónicos (BACKEND)
  static String _normalizeEstado(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return 'PENDIENTE';
    switch (raw.toUpperCase()) {
      case 'PENDIENTE':
      case 'AGENDADA':
      case 'PROGRAMADA':
      case 'EN PROCESO':
      case 'EN_PROCESO':
      case 'PENDIENTE PAGO':
      case 'PENDIENTE_PAGO':
        return 'PENDIENTE';
      case 'CONFIRMADA':
      case 'ACEPTADA':
      case 'COMPLETADA':
      case 'FINALIZADA':
      case 'ATENDIDA':
        return 'CONFIRMADA';
      case 'CANCELADA':
      case 'RECHAZADA':
        return 'CANCELADA';
      default:
        return raw.toUpperCase();
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final normalized = value.toString().trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  // Texto amigable para UI
  String get estadoLabel {
    switch (_normalizeEstado(estado)) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'CONFIRMADA':
        return 'Confirmada';
      case 'CANCELADA':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  // Helpers de clasificación para las vistas de historial.
  bool get esCompletada => _normalizeEstado(estado) == 'CONFIRMADA';

  bool get esPendiente {
    final n = _normalizeEstado(estado);
    return n == 'PENDIENTE' || n == 'EN_PROCESO';
  }

  // Valor de consulta unificado para UI.
  // Prioriza el valor configurado por el médico y, si no existe (>0), parsea el campo 'precio'.
  double get valor_consulta {
    if (medico.valorConsulta > 0) return medico.valorConsulta;
    final limpio = precio.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(limpio) ?? 0;
  }
}
