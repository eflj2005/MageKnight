import 'package:flutter/material.dart';

/// Define los 6 colores fundamentales de magia en el ecosistema físico de Mage Knight
enum TipoMana {
  azul,    // Efectos de Hielo y Bloqueo mágico
  rojo,    // Fuego y Ataques Ranged/Siege
  verde,   // Movimiento y Modificación de Cartas/Curación
  blanco,  // Efectos puros, Liderazgo, Armadura
  dorado,  // Comodín Diurno
  negro    // Magia Oscura (Solo Nocturno para conjuros fuertes)
}

/// Extensión para darle identidad visual instantánea a cada tipo de maná
extension AtributosMana on TipoMana {
  Color get colorVisual {
    switch (this) {
      case TipoMana.azul:
        return const Color(0xFF29B6F6);
      case TipoMana.rojo:
        return const Color(0xFFE53935);
      case TipoMana.verde:
        return const Color(0xFF66BB6A);
      case TipoMana.blanco:
        return Colors.white;
      case TipoMana.dorado:
        return const Color(0xFFFFCA28);
      case TipoMana.negro:
        return const Color(0xFF424242);
    }
  }

  String get nombreLegible {
    switch (this) {
      case TipoMana.azul: return 'Azul';
      case TipoMana.rojo: return 'Rojo';
      case TipoMana.verde: return 'Verde';
      case TipoMana.blanco: return 'Blanco';
      case TipoMana.dorado: return 'Dorado';
      case TipoMana.negro: return 'Negro';
    }
  }

  IconData get iconoVisual {
    switch (this) {
      case TipoMana.azul: return Icons.ac_unit;
      case TipoMana.rojo: return Icons.local_fire_department;
      case TipoMana.verde: return Icons.eco;
      case TipoMana.blanco: return Icons.auto_awesome; // [Refinamiento] Magia pura
      case TipoMana.dorado: return Icons.wb_sunny;    // [Sync] Mismo icono que botón de Día
      case TipoMana.negro: return Icons.nights_stay;  // [Sync] Mismo icono que botón de Noche
    }
  }

  /// Mage knight balance: Los colores básicos tienen 1/6 de probabilidad.
  /// (Dorado y Negro comparten caras en el juego físico, pero matemáticamente en digital
  /// podemos simular el d6: Azul, Rojo, Verde, Blanco, Dorado, Negro)
  static TipoMana desdeCaraD6(int cara) {
    if (cara < 0 || cara > 5) return TipoMana.blanco; // Fallback
    return TipoMana.values[cara];
  }
}

/// Representa el estado físico de un dado dentro de "La Fuente"
class DadoMana {
  /// Color mágico actual que muestra la cara alzada del dado
  TipoMana tipo;
  
  /// Controla la economía por turno: Un usuario solo puede vaciar 1 dado básico por turno (sin cartas limit limit breaking).
  bool estaAgotado;

  /// [Refinamiento] Indica si el dado es inválido por el ciclo actual (Día/Noche)
  /// Un dado incompatible no puede ser consumido ni re-lanzado manualmente.
  bool esIncompatible;

  DadoMana({
    required this.tipo, 
    this.estaAgotado = false,
    this.esIncompatible = false,
  });
  
  /// Acción táctica: Consumir el dado.
  void agotar() {
    estaAgotado = true;
  }
  
  /// Al final del turno o inicio de ronda
  void reactivar() {
    estaAgotado = false;
  }

  DadoMana clone() {
    return DadoMana(
      tipo: tipo, 
      estaAgotado: estaAgotado,
      esIncompatible: esIncompatible,
    );
  }
}
