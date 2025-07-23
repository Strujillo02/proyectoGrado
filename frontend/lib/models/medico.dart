import 'package:frontend/models/especialidades.dart';
import 'package:frontend/models/user.dart';

class Medico {
  final int? id;
  final Especialidades especialidad;
  final User usuario;
  final String estado;
  final String tarjetaProfe; 

  Medico({
    this.id,
    required this.especialidad,
    required this.usuario,
    required this.estado,
    required this.tarjetaProfe, 
  });

  // Convierte un objeto JSON a un objeto Medico
  factory Medico.fromJson(Map<String, dynamic> json) {
  return Medico(
    id: json['id'] is int
        ? json['id']
        : int.tryParse(json['id'].toString()), // <-- asegura que sea int
    especialidad: Especialidades.fromJson(json['especialidad']),
    usuario: User.fromJson(json['usuario']),
    estado: json['estado'],
    tarjetaProfe: json['tarjetaProfe'] ?? json['tarjeta_profe'] ?? '',
  );
}

  // Convierte un objeto Medico a un objeto JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'especialidad': especialidad.toJson(),
      'usuario': usuario.toJson(),
      'estado': estado,
      'tarjetaProfe': tarjetaProfe, 
    };
  }
}