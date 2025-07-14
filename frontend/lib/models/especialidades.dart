class Especialidades {
  final int? id;

  final String nombre;
  final String estado;

  Especialidades({this.id, required this.nombre, required this.estado});

   // Método para convertir un mapa a un objeto especialidades
  factory Especialidades.fromJson(Map<String, dynamic> json) => Especialidades(
    id: json['id'],
    nombre: json['nombre'],
    estado: json['estado'],
  );

  // Método para convertir un objeto especialidad a un mapa
  //Se usa para enviar el objeto a la API
  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'estado': estado,
  };
}
