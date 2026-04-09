import 'package:flutter/material.dart';
import 'mana.dart';

/// Clase que representa al héroe controlado por el jugador.
/// Mantiene su posición en el grid y sus recursos actuales (como PM).
class Heroe {
  /// Nombre del héroe (ej. Tovak)
  final String nombre;

  /// Ruta del asset PNG de la miniatura (ej. "heroe1") [Fase 2A]
  final String imageName;

  /// Coordenada axial Q (columna)
  int q;

  /// Coordenada axial R (fila)
  int r;

  /// Puntos de Movimiento (PM) disponibles
  int puntosMovimiento;

  /// Puntos de Influencia (PI) — [Fase 2B]
  int puntosInfluencia;

  /// Puntos de Ataque (PA) — [Fase 2B]
  int puntosAtaque;

  /// Puntos de Bloqueo (PB) — [Fase 2B]
  int puntosBloqueo;

  /// Puntos de Curación (PC) — [Fase 2B]
  int puntosCuracion;

  /// Inventario Físico: Cristales de Maná almacenados (permanecen entre turnos)
  final Map<TipoMana, int> inventarioCristales;

  /// Icono representativo del héroe
  final String icono;

  /// Color distintivo del héroe para la UI de la AppBar
  final Color color;

  /// Color base del rastro místico de luz (Fase 1E) [Fase 2A]
  /// Permite que cada héroe tenga una huella visual única al moverse
  final Color colorRastro;

  Heroe({
    required this.nombre,
    this.imageName = 'heroe1',
    required this.q,
    required this.r,
    this.puntosMovimiento = 0,
    this.puntosInfluencia = 0,
    this.puntosAtaque = 0,
    this.puntosBloqueo = 0,
    this.puntosCuracion = 0,
    Map<TipoMana, int>? inventarioCristales,
    this.icono = '🛡️',
    this.color = const Color(0xFFFFD700),
    this.colorRastro = const Color(0xFFFFD700),
  }) : inventarioCristales = inventarioCristales ?? {
        TipoMana.azul: 0,
        TipoMana.rojo: 0,
        TipoMana.verde: 0,
        TipoMana.blanco: 0,
        // (El Dorado y Negro nunca pueden ser cristales en reglas MK, pero se dejan en 0 por consistencia del map)
        TipoMana.dorado: 0,
        TipoMana.negro: 0,
       };

  /// Actualiza la posición del héroe
  void moverA(int nuevaQ, int nuevaR) {
    q = nuevaQ;
    r = nuevaR;
  }

  /// Consume puntos de movimiento
  void consumirMovimiento(int costo) {
    puntosMovimiento -= costo;
    if (puntosMovimiento < 0) puntosMovimiento = 0;
  }

  /// Recarga puntos de movimiento (útil para fin de turno o cartas)
  void recargarMovimiento(int cantidad) {
    puntosMovimiento += cantidad;
  }
}
