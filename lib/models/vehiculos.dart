// lib/models/vehiculos.dart

class Vehiculo {
  final int id;
  final String matricula;
  final String marca;
  final String modelo;
  final int anio;
  // Puedes ignorar fecha_eliminacion si no lo usas en Flutter
  // final String? fechaEliminacion; 

  Vehiculo({
    required this.id,
    required this.matricula,
    required this.marca,
    required this.modelo,
    required this.anio,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) {
    return Vehiculo(
      id: json['id'] as int,
      matricula: json['matricula'] as String,
      marca: json['marca'] as String,
      modelo: json['modelo'] as String,
      anio: json['anio'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'matricula': matricula,
        'marca': marca,
        'modelo': modelo,
        'anio': anio,
      };
}
