import '../models/loseta.dart';
import '../models/hexagono.dart';

/// Define las losetas del Escenario 1 basándose en la configuración oficial de Mage Knight.
/// Extraído del motor de datos numérico, respetando terrenos y sitios exactos.

TipoTerreno _c2T(String c) {
  switch (c) {
    case 'p': return TipoTerreno.pradera;
    case 'h': return TipoTerreno.colina;
    case 'f': return TipoTerreno.bosque;
    case 'w': return TipoTerreno.paramo;
    case 'd': return TipoTerreno.desierto;
    case 's': return TipoTerreno.pantano;
    case 'm': return TipoTerreno.montania;
    case 'l': return TipoTerreno.lago;
    case 'c': return TipoTerreno.ciudad;
    default: return TipoTerreno.pradera;
  }
}

List<({int q, int r, TipoTerreno tipo, TipoSitio? sitio, ColorMana? colorMana})> _parseDef(
  String terrains, 
  List<TipoSitio?> sites, {
  List<ColorMana?>? colors,
}) {
  final List<ColorMana?> safeColors = colors ?? List.filled(7, null);
  return [
    (q: 0, r: 0, tipo: _c2T(terrains[0]), sitio: sites[0], colorMana: safeColors[0]),
    (q: 1, r: -1, tipo: _c2T(terrains[1]), sitio: sites[1], colorMana: safeColors[1]),
    (q: 1, r: 0, tipo: _c2T(terrains[2]), sitio: sites[2], colorMana: safeColors[2]),
    (q: 0, r: 1, tipo: _c2T(terrains[3]), sitio: sites[3], colorMana: safeColors[3]),
    (q: -1, r: 1, tipo: _c2T(terrains[4]), sitio: sites[4], colorMana: safeColors[4]),
    (q: -1, r: 0, tipo: _c2T(terrains[5]), sitio: sites[5], colorMana: safeColors[5]),
    (q: 0, r: -1, tipo: _c2T(terrains[6]), sitio: sites[6], colorMana: safeColors[6]),
  ];
}

// ---------------------------------------------------------------------------
// Loseta de Inicio A
// ---------------------------------------------------------------------------
final Loseta losetaInicio = Loseta(
  id: 0,
  nombre: 'Inicio A',
  definicion: _parseDef('pfplllp', [TipoSitio.portal, null, null, null, null, null, null]),
  tipo: TipoLoseta.inicial,
);

// ---------------------------------------------------------------------------
// Losetas de Campo (Countryside Tiles) 1 a 11
// ---------------------------------------------------------------------------
final Loseta loseta1 = Loseta(id: 1, nombre: 'Campo 1', tipo: TipoLoseta.campo, definicion: _parseDef('flpppff', [TipoSitio.claroMagico, null, TipoSitio.aldea, null, null, null, TipoSitio.orcos]));
final Loseta loseta2 = Loseta(id: 2, nombre: 'Campo 2', tipo: TipoLoseta.campo, definicion: _parseDef('hfpphph', [null, TipoSitio.claroMagico, TipoSitio.aldea, null, TipoSitio.minasCristal, null, TipoSitio.orcos], colors: [null, null, null, null, ColorMana.verde, null, null]));
final Loseta loseta3 = Loseta(id: 3, nombre: 'Campo 3', tipo: TipoLoseta.campo, definicion: _parseDef('fhhhppp', [null, TipoSitio.fortaleza, null, TipoSitio.minasCristal, TipoSitio.aldea, null, null], colors: [null, null, null, ColorMana.blanco, null, null, null]));
final Loseta loseta4 = Loseta(id: 4, nombre: 'Campo 4', tipo: TipoLoseta.campo, definicion: _parseDef('ddmpphd', [TipoSitio.torreMago, null, null, TipoSitio.aldea, null, TipoSitio.orcos, null]));
final Loseta loseta5 = Loseta(id: 5, nombre: 'Campo 5', tipo: TipoLoseta.campo, definicion: _parseDef('lpphfff', [null, TipoSitio.monasterio, TipoSitio.orcos, TipoSitio.minasCristal, null, TipoSitio.claroMagico, null], colors: [null, null, null, ColorMana.azul, null, null, null]));
final Loseta loseta6 = Loseta(id: 6, nombre: 'Campo 6', tipo: TipoLoseta.campo, definicion: _parseDef('hfpfhhm', [TipoSitio.minasCristal, null, null, TipoSitio.orcos, null, TipoSitio.guaridaMonstruo, null], colors: [ColorMana.rojo, null, null, null, null, null, null]));
final Loseta loseta7 = Loseta(id: 7, nombre: 'Campo 7', tipo: TipoLoseta.campo, definicion: _parseDef('sffpppl', [null, TipoSitio.orcos, TipoSitio.claroMagico, TipoSitio.dungeon, null, TipoSitio.monasterio, null]));
final Loseta loseta8 = Loseta(id: 8, nombre: 'Campo 8', tipo: TipoLoseta.campo, definicion: _parseDef('sfpssff', [TipoSitio.orcos, TipoSitio.ruinas, null, TipoSitio.aldea, null, null, TipoSitio.claroMagico]));
final Loseta loseta9 = Loseta(id: 9, nombre: 'Núcleo 9 (c2)', tipo: TipoLoseta.nucleo, definicion: _parseDef('lshssfl', [null, TipoSitio.ruinas, TipoSitio.minasCristal, TipoSitio.draconum, TipoSitio.torreMago, null, null], colors: [null, null, ColorMana.rojo, null, null, null, null]));
final Loseta loseta10 = Loseta(id: 10, nombre: 'Núcleo 10 (c4)', tipo: TipoLoseta.nucleo, definicion: _parseDef('mhwwwwh', [TipoSitio.draconum, null, TipoSitio.fortaleza, null, TipoSitio.ruinas, null, TipoSitio.minasCristal], colors: [null, null, null, null, null, null, ColorMana.blanco]));
final Loseta loseta11 = Loseta(id: 11, nombre: 'Ciudad (c6)', tipo: TipoLoseta.nucleo, definicion: _parseDef('cpllhmf', [TipoSitio.ciudad, TipoSitio.monasterio, null, null, null, TipoSitio.draconum, null]));


/// Retorna el mazo del escenario 1. 
/// Las primeras 8 losetas son VERDES (Campo) y salen en orden secuencial.
/// Las últimas 3 losetas son MARRONES (Núcleo) y salen en orden aleatorio,
/// garantizando que una sea la ciudad (Loseta #11).
List<Loseta> mazoEscenarioUno() {
  // Losetas de Campo (Verdes) - Salen en orden para el tutorial
  final verdes = [
    loseta1, loseta2, loseta3, loseta4, loseta5, loseta6, 
    loseta7, loseta8
  ];

  // Losetas de Núcleo (Marrones) - Salen aleatorias al final
  final marrones = [loseta9, loseta10, loseta11];
  marrones.shuffle(); // Las marrones siempre se barajan

  return [...verdes, ...marrones];
}
