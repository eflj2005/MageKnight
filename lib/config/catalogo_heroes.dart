import 'package:flutter/material.dart';
import '../models/heroe.dart';
import '../models/mana.dart';

/// Definición completa de un héroe para el catálogo.
///
/// Separa los metadatos de la UI (icono, colores, asset) de la
/// lógica de juego (stats), permitiendo que cada uno evolucione
/// de forma independiente.
class DefinicionHeroe {
  /// Nombre oficial del héroe en el juego
  final String nombre;

  /// Nombre del asset de imagen (sin ruta ni extensión, se resuelve con AssetPaths)
  final String imageName;

  /// Emoji representativo del héroe para la UI compacta
  final String icono;

  /// Color principal del héroe (AppBar, rastros, auras)
  final Color color;

  /// Color del rastro de luz al moverse en el mapa
  final Color colorRastro;

  const DefinicionHeroe({
    required this.nombre,
    required this.imageName,
    required this.icono,
    required this.color,
    required this.colorRastro,
  });
}

/// Catálogo central de todos los héroes jugables.
///
/// ANTES (Fase 2A): La lista vivía hardcoded en `_PantallaJuegoState._catalogoHeroes`.
/// AHORA (Fase 4): Vive aquí, separada de la UI, lista para ser parametrizada
///                 por escenario, modo de juego o preferencia del jugador.
///
/// AGREGAR UN HÉROE NUEVO:
///   1. Añadir su asset PNG a `assets/images/`.
///   2. Declarar la constante en `AssetPaths`.
///   3. Añadir un `DefinicionHeroe(...)` a la lista `todos`.
class CatalogoHeroes {
  CatalogoHeroes._();

  /// Lista de todos los héroes disponibles en esta versión.
  static const List<DefinicionHeroe> todos = [
    DefinicionHeroe(
      nombre: 'Tovak',
      imageName: 'heroe1',
      icono: '🛡️',
      color: Color(0xFFFFD700),      // Dorado — el Caballero clásico
      colorRastro: Color(0xFFFFAA00), // Ámbar cálido
    ),
    DefinicionHeroe(
      nombre: 'Goldyx',
      imageName: 'heroe2',
      icono: '🔥',
      color: Color(0xFFE53935),      // Rojo — la Guerrera del fuego
      colorRastro: Color(0xFFFF1744), // Plasma ardiente
    ),

    DefinicionHeroe(
      nombre: 'Arythea',
      imageName: 'heroe1', // Placeholder hasta tener heroe3
      icono: '🩸',
      color: Color(0xFFC62828),      // Carmesí — La sed de sangre
      colorRastro: Color(0xFFFF5252), // Brillo carmesí
    ),
    DefinicionHeroe(
      nombre: 'Norowas',
      imageName: 'heroe2', // Placeholder hasta tener heroe4
      icono: '🌿',
      color: Color(0xFF2E7D32),      // Verde — El líder de los bosques
      colorRastro: Color(0xFF66BB6A), // Luz de naturaleza
    ),
  ];

  /// Crea una instancia de [Heroe] desde el catálogo, en la posición (q, r).
  ///
  /// Los stats iniciales del héroe son asignados por [ReglasEscenario1] o
  /// las reglas del escenario activo. Por defecto usa valores estándar MK.
  static Heroe crear(
    int indice, {
    int q = 0,
    int r = 0,
    int puntosMovimiento = 26,
    int puntosInfluencia = 4,
    int puntosAtaque = 8,
    int puntosBloqueo = 5,
    int puntosCuracion = 2,
  }) {
    final def = todos[indice % todos.length];
    return Heroe(
      nombre: def.nombre,
      imageName: def.imageName,
      icono: def.icono,
      color: def.color,
      colorRastro: def.colorRastro,
      q: q,
      r: r,
      puntosMovimiento: puntosMovimiento,
      puntosInfluencia: puntosInfluencia,
      puntosAtaque: puntosAtaque,
      puntosBloqueo: puntosBloqueo,
      puntosCuracion: puntosCuracion,
      inventarioCristales: {
        TipoMana.azul: 0,
        TipoMana.rojo: 0,
        TipoMana.verde: 0,
        TipoMana.blanco: 0,
        TipoMana.dorado: 0,
        TipoMana.negro: 0,
      },
    );
  }
}
