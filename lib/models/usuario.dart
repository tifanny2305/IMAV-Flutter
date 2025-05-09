class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String password;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.password,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'password': password,
    };
  }
}
