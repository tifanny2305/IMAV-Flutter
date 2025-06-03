import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taller_1/auth/providers/audios_provider.dart';
import 'package:taller_1/auth/providers/diagnosticos_provider.dart';

class Diagnosticos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final todos = context.watch<DiagnosticosProvider>().diagnosticos;

    // Separa en “activos” (pendiente/proceso) y “completados”
    final activos = todos.where((d) => d.estado != 'terminado').toList();
    final completados = todos.where((d) => d.estado == 'terminado').toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true, // si usas Navigator.pop, etc.
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 20, 18, 110),  // #14126E
                Color.fromARGB(255, 22, 16, 190),  // #1610BE
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Título en blanco para que contraste con el fondo oscuro
        title: const Text(
          'Diagnósticos Asignados',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        // Aseguramos que el icono de “volver” (o cualquier otro icono) quede en blanco
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView(
          children: [
            // --- SECCIÓN “ACTIVOS” ---
            if (activos.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    'No tienes diagnósticos activos.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
            if (activos.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Activos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...activos.map((d) => _buildDiagnosticoCard(context, d, true)),
            ],

            // --- SECCIÓN “COMPLETADOS” ---
            if (completados.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(thickness: 1.2),
              const SizedBox(height: 12),
              const Text(
                'Completados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...completados.map((d) => _buildDiagnosticoCard(context, d, false)),
            ],
          ],
        ),
      ),
    );
  }

  /// Construye cada Card de diagnóstico.
  /// [isActivo] = true si está pendiente/proceso (para mostrar botón).
  Widget _buildDiagnosticoCard(BuildContext context, dynamic d, bool isActivo) {
    // Formatear la fecha en “dd-MM-yyyy HH:mm”
    final fecha = d.fechaCreacion.toLocal();
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: isActivo ? Colors.white : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FILA 1: Ícono + Marca-Modelo + Matrícula ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.directions_car, color: Colors.blueAccent, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${d.vehiculo.marca} ${d.vehiculo.modelo}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  d.vehiculo.matricula, // ← AQUÍ USAMOS “matricula”
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // --- FILA 2: Fecha y Estado ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fecha: $fechaStr',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (d.estado == 'pendiente')
                        ? Colors.orange[100]
                        : (d.estado == 'proceso')
                            ? Colors.lightBlue[100]
                            : Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    d.estado.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: (d.estado == 'pendiente')
                          ? Colors.orange[800]
                          : (d.estado == 'proceso')
                              ? Colors.lightBlue[800]
                              : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // --- BOTÓN “Tomar” / “Grabar” SOLO SI ESTÁ ACTIVO ---
            if (isActivo && (d.estado == 'pendiente' || d.estado == 'proceso'))
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (d.estado == 'pendiente')
                          ? Colors.blueAccent
                          : Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      elevation: 1,
                    ),
                    onPressed: () => _handleDiagnosticoTap(context, d),
                    child: Text(
                      (d.estado == 'pendiente') ? 'Tomar' : 'Grabar',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDiagnosticoTap(BuildContext context, dynamic diagnostico) async {
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

        // Breve espera para que el servidor procese
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Cerrar el diálogo de carga
      Navigator.of(context).pop();

      // Navegar a la pantalla de audios
      Navigator.pushNamed(
        context,
        'audios',
        arguments: diagnostico,
      );
    } catch (e) {
      // Cerrar diálogo si estaba abierto
      Navigator.of(context).pop();

      // Mostrar un Snackbar con el error
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
