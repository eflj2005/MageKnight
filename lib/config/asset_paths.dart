/// Registro centralizado de TODAS las rutas de assets del juego.
///
/// PROPÓSITO: Cuando se quiera reemplazar los assets placeholder
/// por los assets originales (arte oficial, ilustraciones reales, etc.),
/// SOLO se modifica este archivo. El resto del código permanece intacto.
///
/// GUÍA DE INTERCAMBIO DE ASSETS:
///   1. Añadir el nuevo archivo a `assets/images/` (u otra carpeta).
///   2. Declararlo en `pubspec.yaml` bajo `flutter.assets`.
///   3. Cambiar ÚNICAMENTE la constante de esta clase.
///   4. Hot Reload → El juego completo usa el nuevo asset.
///
/// NOTA: Organizar por categorías para futuras expansiones.
class AssetPaths {
  AssetPaths._(); // No instanciable

  // ── Miniaturas de Héroes ────────────────────────────────────────────────
  /// Miniatura del héroe Tovak (Caballero Dorado)
  static const String heroeTovak   = 'assets/images/heroe1.png';

  /// Miniatura del héroe Goldyx (Guerrera del Fuego)
  static const String heroeGoldyx  = 'assets/images/heroe2.png';

  // ── Arte de Cartas (Placeholder — Fase 5) ──────────────────────────────
  // TODO(Fase 5): Añadir rutas de arte de cartas cuando se implemente Hand UI.
  // static const String cartaAtaque  = 'assets/cards/ataque.png';
  // static const String cartaCuracion = 'assets/cards/curacion.png';

  // ── Terrenos del Mapa (Placeholder — Futuro) ────────────────────────────
  // TODO(Futuro): Si se añaden texturas de terreno en PNG/SVG.
  // static const String terrenosPradera = 'assets/terrain/pradera.png';

  // ── Iconos y UI ─────────────────────────────────────────────────────────
  // TODO(Futuro): Iconos temáticos en SVG si se reemplazan los Material Icons.

  // ── Auxiliar: Obtener la ruta por nombre de héroe ───────────────────────
  /// Retorna la ruta del asset del héroe dado su imageName.
  /// Uso: `AssetPaths.deHeroe(heroe.imageName)`
  static String deHeroe(String imageName) {
    switch (imageName) {
      case 'heroe1': return heroeTovak;
      case 'heroe2': return heroeGoldyx;
      default:       return heroeTovak; // Fallback al héroe principal
    }
  }
}
