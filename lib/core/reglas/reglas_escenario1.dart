import '../../models/mana.dart';
import '../../models/fuente_magia.dart';
import '../../models/hexagono.dart';
import 'reglas_base.dart';

/// Implementación oficial de las reglas del Escenario 1 de Mage Knight.
///
/// Basado en el rulebook oficial: "Mage Knight Board Game Rules" (primera edición).
/// Esta implementación codifica las reglas tal como están en el juego físico.
///
/// NOTA: A medida que el proyecto crezca, agregar aquí los ajustes de dificultad,
/// variantes de escenario, o modos de partida rápida.
class ReglasEscenario1 implements ReglaJuego {

  const ReglasEscenario1();

  // ── Sistema de Maná ──────────────────────────────────────────────────────

  /// En Escenario 1 estándar: 3 dados por turno en La Fuente.
  /// (Nota: Expansiones oficiales pueden subir esto a 5.)
  @override
  int get numeroDados => 3;

  /// Regla de Mata-Magia: Los dados incompatibles con el ciclo se bloquean.
  ///   - Ciclo DÍA   → El maná NEGRO (Oscuro) es inválido.
  ///   - Ciclo NOCHE → El maná DORADO (Comodín Solar) es inválido.
  @override
  bool dadoEsIncompatible(TipoMana mana, CicloMundo ciclo) {
    if (ciclo == CicloMundo.dia   && mana == TipoMana.negro)  return true;
    if (ciclo == CicloMundo.noche && mana == TipoMana.dorado) return true;
    return false;
  }

  // ── Sistema de Movimiento ────────────────────────────────────────────────

  /// Regla estándar: el costo lo define el hexágono (ver TipoTerreno.costo en hexagono.dart).
  /// Retorna null para indicar "sin modificación" al motor.
  @override
  int? costoMovimientoPersonalizado(TipoTerreno terreno) => null;

  // ── Estadísticas Iniciales del Héroe ────────────────────────────────────

  /// Mage Knight regla: Todos los héroes comienzan el turno con 2 Pts de Mov base.
  /// La carta de habilidad inicial suma los adicionales.
  /// [NOTA DEV]: El valor 26 de prueba se reducirá cuando se implemente el
  /// sistema de cartas de acción y habilidades del héroe.
  @override
  int puntosMovimientoInicial(String nombreHeroe) {
    // TODO(Fase 5): Ajustar según las cartas de habilidad del héroe.
    return 26; // Valor de prueba para navegación libre
  }

  @override int puntosInfluenciaInicial(String nombreHeroe) => 4;
  @override int puntosAtaqueInicial(String nombreHeroe)     => 8;
  @override int puntosBloqueoInicial(String nombreHeroe)    => 5;
  @override int puntosCuracionInicial(String nombreHeroe)   => 2;
}
