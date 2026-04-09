import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sesion_juego.dart';
import '../core/constants.dart';

/// Widget que muestra el historial de acciones tácticas (El Pergamino de Memoria).
///
/// Permite visualizar los últimos 30 movimientos y ejecutar deshacer/rehacer.
/// Sigue la estética Glassmorphism del resto de la aplicación.
class WidgetHistorial extends StatelessWidget {
  final SesionJuego sesion;

  const WidgetHistorial({super.key, required this.sesion});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sesion,
      builder: (context, _) {
        final acciones = sesion.historialAcciones.reversed.toList();
        final puedeDeshacer = sesion.puedeDeshacer;
        final puedeRehacer = sesion.puedeRehacer;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 238, // [Fase 4E] Reducido un 15% (de 280)
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8, // [Fase 4E] Ajuste responsivo
              ),
              decoration: BoxDecoration(
                color: AppColors.fondoPanel.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.dorado.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // [Fase 4E] Para que el panel no ocupe más de lo necesario
                children: [
                  // ── Cabecera ──────────────────────────────────────────────
                  _buildHeader(),

                  // ── Lista de Acciones ─────────────────────────────────────
                  Expanded(
                    child: acciones.isEmpty
                        ? _buildEmptyState()
                        : _buildActionList(acciones),
                  ),

                  // ── Controles de Undo/Redo ───────────────────────────────
                  _buildControls(puedeDeshacer, puedeRehacer),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: Border.all(color: Colors.white10).bottom,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_edu, color: AppColors.dorado, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'PERGAMINO DE MEMORIA',
                style: GoogleFonts.marcellus(
                  color: AppColors.dorado,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.dorado.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'T${sesion.turnoActual}',
              style: GoogleFonts.marcellus(
                color: AppColors.dorado,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Sin memorias recientes...',
        style: GoogleFonts.marcellus(
          color: Colors.white24,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildActionList(List<ComandoJuego> acciones) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // [Fase 4E] Reducido
      itemCount: acciones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4), // [Fase 4E] Reducido
      itemBuilder: (context, index) {
        final cmd = acciones[index];
        final esTurnoActual = cmd.turno == sesion.turnoActual;

        // [Fase 4E] Procesar descripción para Sentence case
        final descFinal = cmd.descripcion.isNotEmpty 
            ? cmd.descripcion[0].toUpperCase() + cmd.descripcion.substring(1)
            : '';

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), // [Fase 4E] Reducido
          decoration: BoxDecoration(
            color: esTurnoActual 
                ? Colors.white.withOpacity(0.05) 
                : Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: esTurnoActual 
                  ? AppColors.dorado.withOpacity(0.15) 
                  : Colors.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // [Fase 4E] T# indicador integrado
              Text(
                'T${cmd.turno}', // [Fase 4E] Sin flecha "->" para mayor limpieza
                style: GoogleFonts.marcellus(
                  color: esTurnoActual ? AppColors.dorado : Colors.white24,
                  fontSize: 7, // Ligeramente más pequeño
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  descFinal,
                  style: GoogleFonts.marcellus(
                    color: esTurnoActual ? Colors.white : Colors.white54,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls(bool puedeDeshacer, bool puedeRehacer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.black26,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // [Fase 4F.3] Cambio a inicio absoluto
        children: [
          _buildButton(
            icon: Icons.undo,
            activo: puedeDeshacer,
            onTap: puedeDeshacer ? () => sesion.deshacer() : null,
          ),
          const SizedBox(width: 8),
          _buildButton(
            icon: Icons.redo,
            activo: puedeRehacer,
            onTap: puedeRehacer ? () => sesion.rehacer() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required bool activo,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, // [Fase 4F] Ancho fijo para mayor precisión espacial
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: activo ? AppColors.dorado.withOpacity(0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: activo ? AppColors.dorado.withOpacity(0.5) : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20, // Más grande ya que no hay texto
              color: activo ? AppColors.dorado : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}
