import 'package:frontend/models/medico.dart';

class Calificaciones {
  final int? id;
  final int calificacion;
  final Medico medico;

  Calificaciones({this.id, required this.calificacion, required this.medico});

   // Método para convertir un mapa a un objeto 
  factory Calificaciones.fromJson(Map<String, dynamic> json) => Calificaciones(
    id: json['id'],
    calificacion: json['calificacion'],
    medico: Medico.fromJson(json['medico']),
  );

  // Método para convertir un objeto especialidad a un mapa
  //Se usa para enviar el objeto a la API
  Map<String, dynamic> toJson() => {
    'id': id,
    'calificacion': calificacion,
    'medico': medico.toJson(),
  };
}
