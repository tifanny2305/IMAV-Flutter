import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taller_1/auth/providers/audios_provider.dart';
import 'package:taller_1/auth/providers/diagnosticos_provider.dart';

/// Vista de diagnósticos: muestra una lista simple sin lógica de sockets.
class Diagnosticos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final todos = context.watch<DiagnosticosProvider>().diagnosticos;

    // Separa en activos (pendiente/proceso) y completados
    final activos = todos.where((d) => d.estado != 'terminado').toList();
    final completados = todos.where((d) => d.estado == 'terminado').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnósticos Asignados')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          //crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lista de activos
            if (activos.isEmpty)
              const Center(child: Text('No tienes diagnósticos activos.')),
            if (activos.isNotEmpty)
              ...activos.map((d) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      // Mostrar matrícula en lugar de ID
                      title: Text('Placa: ${d.vehiculo.matricula}'),
                      subtitle: Text(
                        'Fecha: ${d.fechaCreacion.toLocal().toString().split(".")[0]}\n'
                        'Estado: ${d.estado}',
                      ),
                      trailing: (d.estado == 'pendiente' ||
                              d.estado == 'proceso')
                          // Mostrar botón solo si no está finalizado
                          ? ElevatedButton(
                              onPressed: () =>
                                  _handleDiagnosticoTap(context, d),
                              child: Text(
                                  d.estado == 'pendiente' ? 'Tomar' : 'Grabar'),
                            )
                          : null,
                      isThreeLine: true,
                    ),
                  )),
            // Separador para completados
            if (completados.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Completados',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              ...completados.map((d) => Card(
                    color: Colors.grey[100],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text('Placa: ${d.vehiculo.matricula}'),
                      subtitle: Text(
                        'Fecha: ${d.fechaCreacion.toLocal().toString().split(".")[0]}\n'
                        'Estado: ${d.estado}',
                      ),
                      // Sin botón
                      isThreeLine: true,
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _handleDiagnosticoTap(BuildContext context, dynamic diagnostico) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Procesando...'),
            ],
          ),
        ),
      );

      final audioProv = context.read<AudioProvider>();

      // Asegurar que el socket esté listo
      await audioProv.ensureSocketReady();

      // Configurar el ID del diagnóstico
      audioProv.setDiagnosticoId(diagnostico.id);

      // Si está pendiente, emitir evento para tomarlo
      if (diagnostico.estado == 'pendiente') {
        debugPrint('🚀 Emisión → tomar-diagnostico: ${diagnostico.id}');
        audioProv.socketService.tomarDiagnostico(diagnostico.id);

        // Pequeña pausa para que el servidor procese
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Cerrar el diálogo de carga
      Navigator.of(context).pop();

      // Navegar a la página de audios
      Navigator.pushNamed(
        context,
        'audios',
        arguments: diagnostico,
      );
    } catch (e) {
      // Cerrar diálogo si está abierto
      Navigator.of(context).pop();

      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );

      debugPrint('❌ Error al procesar diagnóstico: $e');
    }
  }
}
