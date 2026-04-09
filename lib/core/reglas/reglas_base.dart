import '../../models/mana.dart';
import '../../models/fuente_magia.dart';
import '../../models/hexagono.dart';

/// Interfaz abstracta para las Reglas del Juego de Mage Knight.
///
/// Permite que diferentes escenarios, variantes o modos de juego
/// tengan sus propias reglas sin modificar el motor central.
///
/// PATRÓN DE USO:
///   1. Implementar esta clase para cada escenario/variante.
///   2. Inyectar la implementación en SesionJuego al inicializar.
///   3. El motor (FuenteMagia, MapaJuego) consulta las reglas sin conocer la variante.
///
/// EJEMPLOS FUTUROS:
///   - ReglasEscenario1: Las reglas oficiales del juego base.
///   - ReglasDeExplorador: Sin mana negro/dorado para partidas de aprendizaje.
///   - ReglasMultijugador: Ajustes de PM y dados para 2-4 jugadores.
abstract class ReglaJuego {

  // ── Sistema de Maná ──────────────────────────────────────────────────────

  /// Número de dados que se lanzan al inicio del turno en La Fuente.
  int get numeroDados;

  /// Determina si un dado de maná es incompatible con el ciclo actual.
  ///
  /// [mana] — El color del dado a evaluar.
  /// [ciclo] — CicloMundo.dia o CicloMundo.noche.
  ///
  /// Retorna true si el dado debe marcarse como bloqueado (🚫).
  bool dadoEsIncompatible(TipoMana mana, CicloMundo ciclo);

  // ── Sistema de Movimiento ────────────────────────────────────────────────

  /// Costo de movimiento para un tipo de terreno específico.
  /// Por defecto se usa el costo del hexágono, pero una carta o habilidad
  /// podría reducirlo via reglas personalizadas.
  ///
  /// Retorna null para usar el costo base del hexágono sin modificación.
  int? costoMovimientoPersonalizado(TipoTerreno terreno) => null;

  // ── Estadísticas Iniciales del Héroe ────────────────────────────────────

  /// Puntos de Movimiento iniciales por turno para el héroe dado.
  /// Puede variar por escenario (partida rápida vs normal) o nivel dificultad.
  int puntosMovimientoInicial(String nombreHeroe);

  /// Puntos de Influencia iniciales del héroe.
  int puntosInfluenciaInicial(String nombreHeroe) => 4;

  /// Puntos de Ataque base del héroe.
  int puntosAtaqueInicial(String nombreHeroe) => 2;

  /// Puntos de Bloqueo base del héroe.
  int puntosBloqueoInicial(String nombreHeroe) => 2;

  /// Puntos de Curación base del héroe.
  int puntosCuracionInicial(String nombreHeroe) => 1;
}
