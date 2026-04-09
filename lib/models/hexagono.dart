import 'package:flutter/material.dart';

/// Tipos de terreno disponibles en el mapa de Mage Knight.
/// Cada tipo define el costo de movimiento y el aspecto visual de la celda.
enum TipoTerreno {
  pradera,   // p
  colina,    // h
  bosque,    // f
  paramo,    // w
  desierto,  // d
  pantano,   // s
  montania,  // m
  lago,      // l
  ciudad,    // c (terreno base de ciudad)
}

/// Clasificación de la loseta para mostrar en la interfaz.
enum TipoLoseta {
  inicial, // Loseta A o B
  campo,   // Losetas verdes (1-15)
  nucleo,  // Losetas marrones (C1-C8)
}

/// Colores de maná oficiales de Mage Knight.
enum ColorMana { verde, azul, rojo, blanco }

/// Puntos de interés (Sitios) que pueden existir sobre cualquier hexágono de la loseta.
enum TipoSitio {
  portal,
  minasCristal,
  claroMagico,
  orcos,
  draconum,
  aldea,
  monasterio,
  torreMago,
  fortaleza,
  guaridaMonstruo,
  sitioGeneracion,
  dungeon,
  tumba,
  ruinas,
  ciudad
}

/// Retorna el costo de movimiento de un tipo de terreno.
/// En Mage Knight, mover a un hex cuesta los puntos de movimiento indicados.
int costoMovimiento(TipoTerreno tipo) {
  switch (tipo) {
    case TipoTerreno.pradera:
    case TipoTerreno.ciudad:
      return 2;
    case TipoTerreno.colina:
    case TipoTerreno.bosque:
      return 3;
    case TipoTerreno.paramo:
      return 4;
    case TipoTerreno.desierto:
    case TipoTerreno.pantano:
      return 5;
    case TipoTerreno.montania:
    case TipoTerreno.lago:
      return 999; // Intransitable
  }
}

/// Retorna el color base de renderizado para cada tipo de terreno.
/// Se usará en el CustomPainter para pintar la celda.
Color colorTerreno(TipoTerreno tipo) {
  switch (tipo) {
    case TipoTerreno.pradera:
      return const Color(0xFF4CAF50); // Verde medio
    case TipoTerreno.colina:
      return const Color(0xFF8D6E63); // Marrón claro
    case TipoTerreno.bosque:
      return const Color(0xFF1B5E20); // Verde oscuro
    case TipoTerreno.paramo:
      return const Color(0xFFBCAAA4); // Marrón grisáceo
    case TipoTerreno.desierto:
      return const Color(0xFFFFCC80); // Arena
    case TipoTerreno.pantano:
      return const Color(0xFF4E342E); // Marrón oscuro
    case TipoTerreno.montania:
      return const Color(0xFF757575); // Gris roca
    case TipoTerreno.lago:
      return const Color(0xFF1565C0); // Azul profundo
    case TipoTerreno.ciudad:
      return const Color(0xFFB71C1C); // Rojo carmesí
  }
}

/// Retorna el emoji o símbolo que representa el tipo de terreno en el mapa.
String iconoTerreno(TipoTerreno tipo) {
  switch (tipo) {
    case TipoTerreno.pradera:   return '🌿'; // Restaurado para praderas
    case TipoTerreno.colina:    return '🏔️'; // Colina (Intercambiado: ahora es la nevada, más redondeada)
    case TipoTerreno.bosque:    return '🌲';
    case TipoTerreno.paramo:    return '🏜️';
    case TipoTerreno.desierto:  return '🐪';
    case TipoTerreno.pantano:   return '🐊';
    case TipoTerreno.montania:  return '⛰️'; // Montaña (Intercambiado: ahora es el pico estándar)
    case TipoTerreno.lago:      return '🌊';
    case TipoTerreno.ciudad:    return '';
  }
}

/// Retorna el string descriptivo del sitio
String stringSitio(TipoSitio sitio) {
  switch (sitio) {
    case TipoSitio.portal: return 'Portal Mágico';
    case TipoSitio.minasCristal: return 'Minas de Cristal';
    case TipoSitio.claroMagico: return 'Claro Mágico';
    case TipoSitio.orcos: return 'Orcos Merodeadores';
    case TipoSitio.draconum: return 'Draconum';
    case TipoSitio.aldea: return 'Aldea';
    case TipoSitio.monasterio: return 'Monasterio';
    case TipoSitio.torreMago: return 'Torre de Mago';
    case TipoSitio.fortaleza: return 'Fortaleza';
    case TipoSitio.guaridaMonstruo: return 'Guarida de Monstruo';
    case TipoSitio.sitioGeneracion: return 'Sitio de Generación';
    case TipoSitio.dungeon: return 'Dungeon';
    case TipoSitio.tumba: return 'Tumba';
    case TipoSitio.ruinas: return 'Ruinas Antiguas';
    case TipoSitio.ciudad: return 'Ciudad';
  }
}

/// Retorna el color de la UI para el maná.
Color obtenerColorMana(ColorMana color) {
  switch (color) {
    case ColorMana.verde: return const Color(0xFF4CAF50);
    case ColorMana.azul: return const Color(0xFF2196F3);
    case ColorMana.rojo: return const Color(0xFFF44336);
    case ColorMana.blanco: return Colors.white;
  }
}

/// Retorna el nombre en español del color de maná.
String obtenerNombreColorMana(ColorMana color) {
  switch (color) {
    case ColorMana.verde: return 'VERDE';
    case ColorMana.azul: return 'AZUL';
    case ColorMana.rojo: return 'ROJO';
    case ColorMana.blanco: return 'BLANCO';
  }
}

/// Retorna la inicial del color de maná.
String obtenerLetraMana(ColorMana color) {
  switch (color) {
    case ColorMana.verde: return 'V';
    case ColorMana.azul: return 'A';
    case ColorMana.rojo: return 'R';
    case ColorMana.blanco: return 'B';
  }
}

/// Retorna el emoji del sitio
String iconoSitio(TipoSitio sitio) {
  switch (sitio) {
    case TipoSitio.portal: return '🌀';
    case TipoSitio.minasCristal: return '💎';
    case TipoSitio.claroMagico: return '✨';
    case TipoSitio.orcos: return '👹';
    case TipoSitio.draconum: return '🐉';
    case TipoSitio.aldea: return '🏘️';
    case TipoSitio.monasterio: return '⛪';
    case TipoSitio.torreMago: return '🗼';
    case TipoSitio.fortaleza: return '🏰';
    case TipoSitio.guaridaMonstruo: return '🐺';
    case TipoSitio.sitioGeneracion: return '🦂';
    case TipoSitio.dungeon: return '🦇';
    case TipoSitio.tumba: return '⚰️';
    case TipoSitio.ruinas: return '🏛️';
    case TipoSitio.ciudad: return '🏙️'; // Icono estándar de ciudad
  }
}

/// Modelo de un hexágono individual del mapa.
/// Usa el sistema de coordenadas axiales (q, r) estándar para grids hexagonales.
/// Referencia: https://www.redblobgames.com/grids/hexagons/
class Hexagono {
  /// Coordenada axial columna
  final int q;

  /// Coordenada axial fila
  final int r;

  /// Tipo de terreno de esta celda
  final TipoTerreno tipo;

  /// Sitio de interés en esta celda (puede ser null si está vacío)
  final TipoSitio? sitio;

  /// Indica si esta celda ya fue revelada al jugador.
  /// En Mage Knight, las celdas se revelan al explorar losetas adyacentes.
  bool esExplorado;

  /// Indica si esta celda está en el borde del área explorada actual.
  /// Tocar un borde dispara la expansión del mapa.
  bool esBorde;

  /// Identificador de qué loseta pertenece esta celda (para agrupar)
  final int idLoseta;

  /// Indica si esta celda es el hexágono central de su loseta (para dibujo de UI)
  final bool esCentroLoseta;

  /// Rotación con la que fue colocada esta loseta (para orientar arte base)
  final int rotacion;

  /// Clasificación de la loseta a la que pertenece
  final TipoLoseta tipoLoseta;

  /// Color de maná asociado (principalmente para minas)
  final ColorMana? colorMana;

  /// Clave única para uso en mapas y conjuntos
  String get clave => '$q,$r';

  Hexagono({
    required this.q,
    required this.r,
    required this.tipo,
    this.sitio,
    required this.idLoseta,
    this.esCentroLoseta = false,
    this.rotacion = 0,
    required this.tipoLoseta,
    this.colorMana,
    this.esExplorado = false,
    this.esBorde = false,
  });

  /// Retorna el costo de movimiento de esta celda según su terreno
  int get costo => costoMovimiento(tipo);

  /// Retorna el color de renderizado según el terreno
  Color get color => colorTerreno(tipo);

  /// Retorna el ícono representativo del terreno base
  String get iconoTerrenoStr => iconoTerreno(tipo);

  /// Retorna el ícono del sitio si existe, si no, null
  String? get iconoSitioStr => sitio != null ? iconoSitio(sitio!) : null;

  /// Retorna si la celda es transitable (ni lago ni montaña)
  bool get esTransitable => tipo != TipoTerreno.lago && tipo != TipoTerreno.montania;

  @override
  String toString() => 'Hex($q,$r) [$tipo] ${sitio ?? ''}';
}
