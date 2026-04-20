import 'package:frontend/models/especialidades.dart';
import 'package:frontend/models/user.dart';

class Medico {
  final int? id;
  final Especialidades especialidad;
  final User usuario;
  final String estado;
  final String tarjetaProfe;
  // Valor de consulta del médico
  final double valorConsulta;
  final double latitud;
  final double longitud;
  final double calificacion;

  Medico({
    this.id,
    required this.especialidad,
    required this.usuario,
    required this.estado,
    required this.tarjetaProfe,
    this.valorConsulta = 0,
    required this.latitud,
    required this.longitud,
    this.calificacion = 0,
  });

  // Convierte un objeto JSON a un objeto Medico
  factory Medico.fromJson(Map<String, dynamic> json) => Medico(
        id: json['id'] is int
            ? json['id']
            : int.tryParse(json['id'].toString()), // <-- asegura que sea int
        especialidad: Especialidades.fromJson(json['especialidad']),
        usuario: User.fromJson(json['usuario']),
        estado: json['estado'],
        tarjetaProfe: json['tarjetaProfe'] ?? json['tarjeta_profe'] ?? '',
        valorConsulta: _parseValor(json['valor_consulta']),
        latitud: _parseValor(json['latitud']),
        longitud: _parseValor(json['longitud']),
        calificacion: _parseValor(json['calificacion']),
      );

  // Convierte un objeto Medico a un objeto JSON
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'especialidad': especialidad.toJson(),
        'usuario': usuario.toJson(),
        'estado': estado,
        'tarjetaProfe': tarjetaProfe,
        'valor_consulta': valorConsulta,
        'latitud': latitud,
        'longitud': longitud,
        'calificacion': calificacion,
      };

  static double _parseValor(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final raw = v.toString().trim();
    return double.tryParse(raw.replaceAll(',', '.')) ?? 0;
  }
}
