import 'package:flutter/material.dart';

/// Constantes globales del tema visual de Mage Knight.
/// Centraliza todos los valores mágicos (colores, duraciones, tamaños) en un solo lugar,
/// para que cambiar el arte o el look del juego requiera modificar un único archivo.
///
/// GUÍA DE USO:
///   Color fondo = AppColors.fondoPrincipal;
///   Duration anim = AppDuraciones.animacionRodado;
///   double hex  = AppMedidas.tamanoHexPorDefecto;
class AppColors {
  AppColors._(); // Clase no instanciable

  // ── Fondos y superficies ────────────────────────────────────────────────
  static const Color fondoPrincipal    = Color(0xFF0D0D1A);
  static const Color fondoAppBar       = Color(0xFF12002B);
  static const Color fondoPanelInfo    = Color(0xFF1B0035);
  static const Color fondoPanelActivo  = Color(0xFF1B2838);
  static const Color fondoPanel        = Color(0xCC1A1B2D);
  static const Color fondoPurpura      = Color(0xFF4A148C);
  static const Color fondoPurpuraOsc   = Color(0xFF6A1B9A);
  static const Color fondoVerde        = Color(0xFF004D40);

  // ── Colores de acento ───────────────────────────────────────────────────
  static const Color dorado            = Color(0xFFFFD700);
  static const Color doradoRastro      = Color(0xFFFFAA00);
  static const Color cianBorde         = Color(0xFF00E5FF);
  static const Color cianMovimiento    = Color(0xFF00E676);

  // ── Semántica de héroe (override por héroe individual) ──────────────────
  static const Color tovakColor        = Color(0xFFFFD700);
  static const Color tovakRastro       = Color(0xFFFFAA00);
  static const Color goldyxColor       = Color(0xFFE53935);
  static const Color goldyxRastro      = Color(0xFFFF1744);

  // ── Selección de maná ───────────────────────────────────────────────────
  /// Color del aura de selección (alta visibilidad sobre dado blanco)
  static const Color auraManaSeleccionado = Color(0xFFFF4081); // pinkAccent
}

/// Duraciones estándar de animaciones del juego.
class AppDuraciones {
  AppDuraciones._();

  static const Duration animacionRodadoPaso   = Duration(milliseconds: 100);
  static const Duration animacionRodadoTotal  = Duration(milliseconds: 800);
  static const Duration animacionDado         = Duration(milliseconds: 300);
  static const Duration mensajeTop            = Duration(seconds: 2);
  static const Duration ondaChoque            = Duration(milliseconds: 800);
  static const Duration longPressDrag         = Duration(milliseconds: 500);
}

/// Medidas y escalas del motor visual.
class AppMedidas {
  AppMedidas._();

  static const double tamanoHexPorDefecto  = 52.0;
  static const double radioBaseHeroe       = 65.0;
  static const double escaladeHeroeNormal  = 1.2;
  static const double escalaHeroeElevado   = 1.296; // +8% al alzar [v1.5.1]
  static const double elevacionHeroe       = 15.0;

  // Dados de maná
  static const double tamanoGivenado       = 40.0;
  static const double auraManaBlur         = 14.0;
  static const double auraManaSpread       = 4.0;
  static const double auraManaOpacidad     = 0.9;
  static const double bordeManaSelec       = 3.0;
  static const double bordeManaDefecto     = 1.5;
}
