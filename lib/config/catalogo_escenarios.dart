import '../models/loseta.dart';
import '../data/escenario_uno.dart' as esc1;
import '../core/reglas/reglas_base.dart';
import '../core/reglas/reglas_escenario1.dart';

/// Definición de un escenario de juego.
///
/// Un escenario combina:
///   - Una loseta de inicio fija.
///   - Un conjunto de losetas shuffleables para el mazo.
///   - Las reglas de juego que aplican (ciclo, movimiento, stats).
class DefinicionEscenario {
  /// Nombre descriptivo del escenario
  final String nombre;

  /// Descripción para la futura pantalla de selección
  final String descripcion;

  /// Número de jugadores soportados (1 = solitario, 2-4 = grupal)
  final int maxJugadores;

  /// Las reglas que rigen este escenario
  final ReglaJuego reglas;

  /// Factory que construye el mazo de losetas (se llama al iniciar la partida).
  /// Retorna una lista ya en el orden de revelación deseado (incluyendo shuffle interno).
  final List<Loseta> Function() construirMazo;

  /// Loseta de inicio (siempre fija en (0,0))
  final Loseta losetaInicio;

  const DefinicionEscenario({
    required this.nombre,
    required this.descripcion,
    required this.reglas,
    required this.construirMazo,
    required this.losetaInicio,
    this.maxJugadores = 1,
  });
}

/// Registro de todos los escenarios disponibles en el juego.
///
/// PRÓXIMAMENTE (Fase 5+):
///   - Escenario 2: "El Despertar del Reino" (2 jugadores)
///   - Escenario 3: "La Conquista Final" (campaña completa)
///   - Escenario Personalizado: losetaInicio + mazo configurados por el usuario
class CatalogoEscenarios {
  CatalogoEscenarios._();

  /// Escenario 1: "La Exploración" — Tutorial estándar para 1 jugador.
  static final DefinicionEscenario escenarioUno = DefinicionEscenario(
    nombre: 'La Exploración',
    descripcion: 'El escenario introductorio de Mage Knight. '
        'Explora el territorio, conquista sitios y '
        'acumula poder antes de enfrentarte a la Ciudad.',
    maxJugadores: 1,
    reglas: const ReglasEscenario1(),
    losetaInicio: esc1.losetaInicio,
    construirMazo: esc1.mazoEscenarioUno,
  );

  /// Lista de todos los escenarios disponibles (para futura pantalla de selección).
  static final List<DefinicionEscenario> todos = [
    escenarioUno,
    // TODO(Fase 5): agregar escenario2, escenario3, etc.
  ];

  /// Retorna el escenario por defecto (Escenario 1 por ahora).
  static DefinicionEscenario get porDefecto => escenarioUno;
}
