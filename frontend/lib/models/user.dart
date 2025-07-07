class User {
  // Representa todos los atributos de la tabla usuarios en la base de datos
  final int id;
  final String nombre;
  final String telefono;
  final String email;
  final String identificacion;
  final String genero;
  final String estado;
  final String tipo_identificacion;
  final String contrasena;
  final String tipo_usuario;

  User({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.identificacion,
    required this.genero,
    required this.estado,
    required this.tipo_identificacion,
    required this.contrasena,
    required this.tipo_usuario,
  });

  // Método para convertir un mapa a un objeto User
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    nombre: json['nombre'],
    telefono: json['telefono'],
    email: json['email'],
    identificacion: json['identificacion'],
    genero: json['genero'],
    estado: json['estado'],
    tipo_identificacion: json['tipo_identificacion'],
    contrasena: json['contrasena'],
    tipo_usuario: json['tipo_usuario'],
  );

  // Método para convertir un objeto User a un mapa
  //Se usa para enviar el objeto a la API
  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'telefono': telefono,
    'email': email,
    'identificacion': identificacion,
    'genero': genero,
    'estado': estado,
    'tipo_identificacion': tipo_identificacion,
    'contrasena': contrasena,
    'tipo_usuario': tipo_usuario
  };
}
