import 'package:taller_1/models/usuarios.dart';
import 'package:taller_1/models/vehiculos.dart';

class Diagnostico {
  final int id;
  final DateTime fechaCreacion;
  final String estado;
  final String? textoOriginal;
  final String? textoDiagnostico;
  final String? textoCliente;
  final Vehiculo vehiculo;
  final Usuario mecanico;

  Diagnostico({
    required this.id,
    required this.fechaCreacion,
    required this.estado,
    this.textoOriginal,
    this.textoDiagnostico,
    this.textoCliente,
    required this.vehiculo,
    required this.mecanico,
  });

  factory Diagnostico.fromJson(Map<String, dynamic> json) {
    // 1) Extraemos el objeto "clienteVehiculo"
    final clienteVehiculo = json['clienteVehiculo'] as Map<String, dynamic>?;

    if (clienteVehiculo == null) {
      throw Exception('Falta "clienteVehiculo" en el JSON de Diagnostico');
    }

    // 2) Dentro de clienteVehiculo sacamos "vehiculo"
    final vehiculoJson = clienteVehiculo['vehiculo'] as Map<String, dynamic>?;
    if (vehiculoJson == null) {
      throw Exception(
          'Falta "clienteVehiculo.vehiculo" en el JSON de Diagnostico');
    }
    final vehiculoObj = Vehiculo.fromJson(vehiculoJson);

    // 3) Extraemos el objeto "mecanico" de nivel raíz
    final mecanicoJson = json['mecanico'] as Map<String, dynamic>?;
    if (mecanicoJson == null) {
      throw Exception('Falta "mecanico" en el JSON de Diagnostico');
    }
    final mecanicoObj = Usuario.fromJson(mecanicoJson);

    return Diagnostico(
      id: json['id'] as int,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      estado: json['estado'] as String,
      textoOriginal: json['texto_original'] as String?,
      textoDiagnostico: json['texto_diagnostico'] as String?,
      textoCliente: json['texto_cliente'] as String?,
      vehiculo: vehiculoObj,
      mecanico: mecanicoObj,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha_creacion': fechaCreacion.toIso8601String(),
        'estado': estado,
        'texto_original': textoOriginal ?? '',
        'texto_diagnostico': textoDiagnostico ?? '',
        'texto_cliente': textoCliente ?? '',
        'vehiculo': vehiculo.toJson(),
        'mecanico': mecanico.toJson(),
      };
}
