import 'package:flutter/material.dart';
import 'heroe.dart';
import 'loseta.dart';
import 'fuente_magia.dart';
import '../core/reglas/reglas_base.dart';
import '../config/catalogo_escenarios.dart';
import 'mazo_heroe.dart'; // [Fase 5A] Importar gestor de cartas

// =============================================================================
// SISTEMA DE COMANDOS (Patrón Command para Undo/Redo)
// =============================================================================

/// Contrato para todas las acciones reversibles del juego.
///
/// Cada acción de juego que pueda deshacerse implementa esta interfaz.
/// El SesionJuego mantiene dos stacks: historial y rehacibles.
///
/// PATRÓN DE USO:
///   final cmd = ComandoMoverHeroe(...);
///   cmd.ejecutar(sesion);
///   sesion._registrarComando(cmd);
abstract class ComandoJuego {
  /// Descripción legible para debug y futuro panel de historial
  String get descripcion;

  /// Número de turno en el que se ejecutó esta acción [Fase 4B]
  int get turno;

  /// Deshace el efecto de este comando sobre la sesión
  void deshacer(SesionJuego sesion);

  /// Re-ejecuta el comando tras un deshacer (para el botón "Rehacer")
  void reejecutar(SesionJuego sesion);
}

// --------------------------------------------------------------------------

/// Comando: Movimiento del Héroe en el mapa.
///
/// Guarda la posición anterior y los PM gastados para restaurarlos en el undo.
class ComandoMoverHeroe implements ComandoJuego {
  final int qAntes;
  final int rAntes;
  final int qDespues;
  final int rDespues;
  final int pmGastados;

  @override
  final int turno;

  const ComandoMoverHeroe({
    required this.qAntes,
    required this.rAntes,
    required this.qDespues,
    required this.rDespues,
    required this.pmGastados,
    required this.turno,
  });

  @override
  String get descripcion => 'Mover héroe: ($qAntes,$rAntes) → ($qDespues,$rDespues) [-$pmGastados P(m)]';

  @override
  void deshacer(SesionJuego sesion) {
    // Restaurar posición y PM consumidos
    sesion.mapa.heroe?.moverA(qAntes, rAntes);
    sesion.mapa.heroe?.recargarMovimiento(pmGastados);
  }

  @override
  void reejecutar(SesionJuego sesion) {
    // Re-consumir el movimiento
    final costo = sesion.mapa.celdas['$qDespues,$rDespues']?.costo ?? 0;
    sesion.mapa.heroe?.moverA(qDespues, rDespues);
    sesion.mapa.heroe?.consumirMovimiento(costo);
  }
}

// --------------------------------------------------------------------------

/// Comando: Cambio del Ciclo Día/Noche.
///
/// El undo simplemente revierte el ciclo al estado anterior.
class ComandoCambiarCiclo implements ComandoJuego {
  final CicloMundo cicloAntes;
  final CicloMundo cicloDespues;

  @override
  final int turno;

  const ComandoCambiarCiclo({
    required this.cicloAntes,
    required this.cicloDespues,
    required this.turno,
  });

  @override
  String get descripcion =>
      'Cambiar ciclo: ${cicloAntes.name} → ${cicloDespues.name}';

  @override
  void deshacer(SesionJuego sesion) {
    // Revertir el ciclo y re-evaluar compatibilidad de dados
    sesion.fuente.cicloActual = cicloAntes;
    sesion.fuente.aplicarReglaIncompatible();
  }

  @override
  void reejecutar(SesionJuego sesion) {
    sesion.fuente.cicloActual = cicloDespues;
    sesion.fuente.aplicarReglaIncompatible();
  }
}

// --------------------------------------------------------------------------

/// Comando: Fin de Turno (recarga de PM del héroe).
///
/// Registra cuántos PM se recargaron para poder revertirlo.
class ComandoFinTurno implements ComandoJuego {
  final int pmRecargados;

  @override
  final int turno;

  const ComandoFinTurno({
    required this.pmRecargados,
    required this.turno,
  });

  @override
  String get descripcion => 'Fin de turno: +$pmRecargados P(m)';

  @override
  void deshacer(SesionJuego sesion) {
    // Revertir la recarga de PM
    sesion.mapa.heroe?.consumirMovimiento(pmRecargados);
  }

  @override
  void reejecutar(SesionJuego sesion) {
    sesion.mapa.heroe?.recargarMovimiento(pmRecargados);
  }
}

// --------------------------------------------------------------------------

/// Comando: Revelación de nueva loseta de terreno.
///
/// Registra la loseta obtenida para poder devolverla al mazo en el des-hacer.
class ComandoExpandirMapa implements ComandoJuego {
  final Loseta loseta;
  final int q, r;
  final int pmGastados;

  @override
  final int turno;

  const ComandoExpandirMapa({
    required this.loseta,
    required this.q,
    required this.r,
    required this.pmGastados,
    required this.turno,
  });

  @override
  String get descripcion => 'Explorar: +1 Loseta [-$pmGastados P(m)]';

  @override
  void deshacer(SesionJuego sesion) {
    sesion.mapa.revertirExpansion(loseta, q, r);
    sesion.mapa.heroe?.recargarMovimiento(pmGastados);
  }

  @override
  void reejecutar(SesionJuego sesion) {
    sesion.mapa.expandirEn(q, r);
    sesion.mapa.heroe?.consumirMovimiento(pmGastados);
  }
}

// =============================================================================
// SESIÓN DE JUEGO — Estado Unificado
// =============================================================================

/// GameState unificado para una partida de Mage Knight.
///
/// Agrupa [MapaJuego] + [FuenteMagia] como una unidad coherente.
/// Gestiona el historial de acciones para deshacer/rehacer.
///
/// RESPONSABILIDADES:
///   - Inicializar y mantener el estado de la partida.
///   - Proveer la API de acciones (moverHeroe, cambiarCiclo, etc.).
///   - Mantener los stacks de undo/redo.
///   - Notificar a la UI de cualquier cambio de estado.
///
/// MULTI-JUGADOR (futuro):
///   - Cada jugador en su turno tendrá su propio contexto de SesionJuego,
///     o SesionJuego se extenderá para gestionar lista de jugadores activos.
class SesionJuego extends ChangeNotifier {

  // ── Estado de la Partida ─────────────────────────────────────────────────

  late MapaJuego _mapa;
  late FuenteMagia _fuente;
  late ReglaJuego _reglas;
  late MazoHeroe _mazoHeroe; // [Fase 5A] Instancia del mazo del héroe

  /// Acceso de solo lectura al mapa del juego
  MapaJuego get mapa => _mapa;

  /// Acceso de solo lectura a La Fuente de Magia
  FuenteMagia get fuente => _fuente;

  /// Reglas activas en esta sesión
  ReglaJuego get reglas => _reglas;

  /// [Fase 5A] Acceso al gestor de cartas del héroe activo
  MazoHeroe get mazoHeroe => _mazoHeroe;

  // ── Sistema de Undo/Redo ─────────────────────────────────────────────────

  /// Stack de comandos ya ejecutados (para deshacer)
  final List<ComandoJuego> _historial = [];

  /// Stack de comandos deshechados (para rehacer)
  final List<ComandoJuego> _rehacibles = [];

  /// Turno cronológico de la sesión
  int _turnoActual = 1;
  int get turnoActual => _turnoActual;

  /// Costos estándar de acciones tácticas
  static const int COSTO_EXPLORACION = 2;

  /// Límite de acciones visibles en el historial
  static const int _limiteHistorial = 30;

  /// Permite deshacer SOLO si hay historial Y la última acción pertenece al turno actual
  bool get puedeDeshacer => 
      _historial.isNotEmpty && _historial.last.turno == _turnoActual;

  bool get puedeRehacer  => _rehacibles.isNotEmpty;

  /// Devuelve los comandos para el panel de historial [Fase 4B]
  List<ComandoJuego> get historialAcciones => List.unmodifiable(_historial);

  /// Devuelve el historial completo para un futuro panel de "Historial de Turno"
  List<String> get descripcionesHistorial =>
      _historial.map((c) => c.descripcion).toList().reversed.toList();

  // ── Inicialización ───────────────────────────────────────────────────────

  /// Inicia una nueva partida con el escenario y héroe dados.
  ///
  /// [escenario] — Define el mazo, loseta inicial y reglas del juego.
  /// [heroeInicial] — El héroe ya construido (con sus stats según las reglas).
  void inicializar({
    required DefinicionEscenario escenario,
    required Heroe heroeInicial,
  }) {
    _reglas = escenario.reglas;

    // Crear el mapa e inyectar el héroe
    _mapa = MapaJuego();
    _mapa.inicializar(
      losetaInicio: escenario.losetaInicio,
      mazo: escenario.construirMazo(),
      heroeInicial: heroeInicial,
    );

    // Crear La Fuente con las reglas del escenario
    _fuente = FuenteMagia(reglas: _reglas);

    // [Fase 5A] Inicializar el mazo de cartas real para el héroe seleccionado
    _mazoHeroe = MazoHeroe(heroeNombre: heroeInicial.nombre);
    // Vincular listener para propagar redibujados cuando el mazo cambia
    _mazoHeroe.addListener(notifyListeners);

    // Limpiar historial al reiniciar
    _historial.clear();
    _rehacibles.clear();
    _turnoActual = 1;

    notifyListeners();
  }

  // ── Acciones de Juego (Registradas en el Historial) ─────────────────────

  /// Mueve el héroe a (q, r) si es válido. Registra el comando para undo.
  ///
  /// Retorna `true` si el movimiento fue exitoso.
  bool moverHeroe(int q, int r) {
    final heroe = _mapa.heroe;
    if (heroe == null || !_mapa.puedeMoverseA(q, r)) return false;

    // Guardar el estado antes
    final costo = _mapa.celdas['$q,$r']?.costo ?? 0;
    final cmd = ComandoMoverHeroe(
      qAntes: heroe.q,
      rAntes: heroe.r,
      qDespues: q,
      rDespues: r,
      pmGastados: costo,
      turno: _turnoActual,
    );

    // Ejecutar
    _mapa.moverHeroe(q, r);
    _registrarComando(cmd);
    notifyListeners();
    return true;
  }

  /// Expande el mapa colocando la siguiente loseta en (q, r).
  ///
  /// Requiere PM suficientes y adyacencia del héroe.
  bool expandirMapa(int q, int r) {
    final heroe = _mapa.heroe;
    if (heroe == null) return false;

    // 1. Validar PM suficientes
    if (heroe.puntosMovimiento < SesionJuego.COSTO_EXPLORACION) return false;

    // 2. Ejecutar la expansión (la validación de adyacencia ocurre dentro de MapaJuego)
    final losetaRevelada = _mapa.expandirEn(q, r);
    if (losetaRevelada == null) return false;

    // 3. Consumir PM y registrar comando
    heroe.consumirMovimiento(SesionJuego.COSTO_EXPLORACION);
    final cmd = ComandoExpandirMapa(
      loseta: losetaRevelada,
      q: q,
      r: r,
      pmGastados: SesionJuego.COSTO_EXPLORACION,
      turno: _turnoActual,
    );
    _registrarComando(cmd);

    notifyListeners();
    return true;
  }

  /// Cambia el ciclo Día/Noche. Registra el comando para undo.
  void cambiarCiclo() {
    final cicloAntes = _fuente.cicloActual;
    _fuente.alternarCiclo();
    final cmd = ComandoCambiarCiclo(
      cicloAntes: cicloAntes,
      cicloDespues: _fuente.cicloActual,
      turno: _turnoActual,
    );
    _registrarComando(cmd);
    notifyListeners();
  }

  /// Ejecuta Fin de Turno: recarga [pmRecarga] puntos de movimiento.
  void finDeTurno({int pmRecarga = 12}) {
    final cmd = ComandoFinTurno(pmRecargados: pmRecarga, turno: _turnoActual);
    _mapa.heroe?.recargarMovimiento(pmRecarga);
    _registrarComando(cmd);
    
    // [Fase 4B] Sellar el historial anterior incrementando el turno
    _turnoActual++;
    
    notifyListeners();
  }

  // ── Undo / Redo ──────────────────────────────────────────────────────────

  /// Deshace la última acción registrada.
  void deshacer() {
    if (!puedeDeshacer) return;
    final cmd = _historial.removeLast();
    cmd.deshacer(this);
    _rehacibles.add(cmd);
    notifyListeners();
  }

  /// Re-ejecuta la última acción deshecha.
  void rehacer() {
    if (!puedeRehacer) return;
    final cmd = _rehacibles.removeLast();
    cmd.reejecutar(this);
    _historial.add(cmd);
    notifyListeners();
  }

  // ── Gestión Interna del Historial ────────────────────────────────────────

  void _registrarComando(ComandoJuego cmd) {
    _historial.add(cmd);
    _rehacibles.clear(); // Una nueva acción invalida el historial de redo

    // Limitar el tamaño del historial (evitar memory leaks en partidas largas)
    if (_historial.length > _limiteHistorial) {
      _historial.removeAt(0);
    }
  }

  @override
  void dispose() {
    _fuente.dispose();
    super.dispose();
  }
}
