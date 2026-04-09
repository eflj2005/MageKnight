import '../models/carta.dart';

/// Catálogo centralizado con la numeración oficial de cartas (001-064).
/// Implementado mediante plantillas base y diccionarios específicos por héroe.
/// Los IDs internos siguen la convención oficial: PrefijoMazo_###
class CatalogoCartas {
  
  // ===========================================================================
  // 1. DICCIONARIO DE PLANTILLAS ÚNICAS (Prefijos de Mazo)
  // ===========================================================================

  // -- Acciones Básicas Comunes (BasicAction) --
  static const Carta _pMarcha = Carta(idInterno: 'BasicAction', nombre: 'Marcha', tipo: TipoCarta.accion, colorBase: ColorMana.verde, categoria: 'comun', iconosPuntos: ['👣'], textoBasico: 'Movimiento 2', textoPotenciado: 'Movimiento 4', imagenNombre: 'art_march');
  static const Carta _pResistencia = Carta(idInterno: 'BasicAction', nombre: 'Resistencia', tipo: TipoCarta.accion, colorBase: ColorMana.azul, categoria: 'comun', iconosPuntos: ['👣'], textoBasico: 'Movimiento 2', textoPotenciado: 'Movimiento 4', imagenNombre: 'art_stamina');
  static const Carta _pAgilidad = Carta(idInterno: 'BasicAction', nombre: 'Agilidad', tipo: TipoCarta.accion, colorBase: ColorMana.blanco, categoria: 'comun', iconosPuntos: ['👣', '⚔️'], textoBasico: 'Movimiento 2', textoPotenciado: 'Ataque a Distancia 3', imagenNombre: 'art_swiftness');
  static const Carta _pFuria = Carta(idInterno: 'BasicAction', nombre: 'Furia', tipo: TipoCarta.accion, colorBase: ColorMana.rojo, categoria: 'comun', iconosPuntos: ['⚔️'], textoBasico: 'Ataque 2', textoPotenciado: 'Ataque 4', imagenNombre: 'art_rage');
  static const Carta _pDeterminacion = Carta(idInterno: 'BasicAction', nombre: 'Determinación', tipo: TipoCarta.accion, colorBase: ColorMana.azul, categoria: 'comun', iconosPuntos: ['🛡️'], textoBasico: 'Bloqueo 2', textoPotenciado: 'Bloqueo 4', imagenNombre: 'art_deter');
  static const Carta _pTranquilidad = Carta(idInterno: 'BasicAction', nombre: 'Tranquilidad', tipo: TipoCarta.accion, colorBase: ColorMana.verde, categoria: 'comun', iconosPuntos: ['❤️'], textoBasico: 'Cura 1 herida', textoPotenciado: 'Cura 2 heridas', imagenNombre: 'art_tranq');
  static const Carta _pPromesa = Carta(idInterno: 'BasicAction', nombre: 'Promesa', tipo: TipoCarta.accion, colorBase: ColorMana.blanco, categoria: 'comun', iconosPuntos: ['👤'], textoBasico: 'Influencia 2', textoPotenciado: 'Influencia 4', imagenNombre: 'art_promise');
  static const Carta _pAmenaza = Carta(idInterno: 'BasicAction', nombre: 'Amenaza', tipo: TipoCarta.accion, colorBase: ColorMana.rojo, categoria: 'comun', iconosPuntos: ['👤', '⚔️'], textoBasico: 'Influencia 2\nPierdes 1 Reputación', textoPotenciado: 'Ataque 3', imagenNombre: 'art_threat');
  static const Carta _pCristalizacion = Carta(idInterno: 'BasicAction', nombre: 'Cristalización', tipo: TipoCarta.accion, colorBase: ColorMana.azul, categoria: 'comun', iconosPuntos: ['💎'], textoBasico: 'Gana 1 Cristal', textoPotenciado: 'Gana 2 Cristales', imagenNombre: 'art_cryst');
  static const Carta _pExtraccionMana = Carta(idInterno: 'BasicAction', nombre: 'Extracción de Maná', tipo: TipoCarta.accion, colorBase: ColorMana.azul, categoria: 'comun', iconosPuntos: ['✨', '💎'], textoBasico: 'Gana 1 ficha de maná', textoPotenciado: 'Gana 2 fichas o 1 Cristal', imagenNombre: 'art_draw');
  static const Carta _pConcentracion = Carta(idInterno: 'BasicAction', nombre: 'Concentración', tipo: TipoCarta.accion, colorBase: ColorMana.verde, categoria: 'comun', iconosPuntos: ['✨'], textoBasico: 'Úsala como Maná Verde,\no potencia una carta Verde.', textoPotenciado: 'Cualquier Maná o carta.', imagenNombre: 'art_conc');
  static const Carta _pImprovisacion = Carta(idInterno: 'BasicAction', nombre: 'Improvisación', tipo: TipoCarta.accion, colorBase: ColorMana.rojo, categoria: 'comun', iconosPuntos: ['👣', '⚔️', '🛡️', '👤'], textoBasico: 'Descarta 1:\nGana Mov/Atq/Blq 3', textoPotenciado: 'Descarta 1:\nGana Mov/Atq/Blq 5', imagenNombre: 'art_impro');

  // -- Únicas de Héroe (HeroAction) --
  static const Carta _pResistenciaFria = Carta(idInterno: 'HeroAction', nombre: 'Resistencia Fría', tipo: TipoCarta.accion, colorBase: ColorMana.azul, categoria: 'tovak', iconosPuntos: ['🛡️'], textoBasico: 'Bloqueo 3', textoPotenciado: 'Bloqueo de Hielo 5', imagenNombre: 'art_t_cold');
  static const Carta _pInstinto = Carta(idInterno: 'HeroAction', nombre: 'Instinto', tipo: TipoCarta.accion, colorBase: ColorMana.rojo, categoria: 'tovak', iconosPuntos: ['⚔️', '🛡️'], textoBasico: 'Gana Atq/Blq 2. Si hiere, roba 1.', textoPotenciado: 'Gana Atq/Blq 4. Si hiere, roba 1.', imagenNombre: 'art_t_inst');
  static const Carta _pFocoVoluntad = Carta(idInterno: 'HeroAction', nombre: 'Foco de Voluntad', tipo: TipoCarta.accion, colorBase: ColorMana.verde, categoria: 'goldyx', iconosPuntos: ['✨'], textoBasico: 'Gana la ficha del dado.', textoPotenciado: 'El dado no vuelve a fuente.', imagenNombre: 'art_g_will');
  static const Carta _pAlegriaCristal = Carta(idInterno: 'HeroAction', nombre: 'Alegría de Cristal', tipo: TipoCarta.accion, colorBase: ColorMana.azul, categoria: 'goldyx', iconosPuntos: ['💎'], textoBasico: 'Gana 1 Cristal. Todos roban.', textoPotenciado: 'Gana 2 Cristales.', imagenNombre: 'art_g_joy');
  static const Carta _pVersatilidad = Carta(idInterno: 'HeroAction', nombre: 'Versatilidad de Batalla', tipo: TipoCarta.accion, colorBase: ColorMana.rojo, categoria: 'arythea', iconosPuntos: ['⚔️', '🛡️'], textoBasico: 'Ataque o Bloqueo 2', textoPotenciado: 'Ataque 4 o Bloqueo 4', imagenNombre: 'art_a_vers');
  static const Carta _pSuccionMana = Carta(idInterno: 'HeroAction', nombre: 'Succión de Maná', tipo: TipoCarta.accion, colorBase: ColorMana.azul, categoria: 'arythea', iconosPuntos: ['✨', '💎'], textoBasico: 'Gana ficha de la fuente.', textoPotenciado: 'Gana 2 fichas o 1 cristal.', imagenNombre: 'art_a_pull');
  static const Carta _pModalesNobles = Carta(idInterno: 'HeroAction', nombre: 'Modales Nobles', tipo: TipoCarta.accion, colorBase: ColorMana.blanco, categoria: 'norowas', iconosPuntos: ['👤'], textoBasico: 'Influencia 2. +1 Reput.', textoPotenciado: 'Influencia 4. +2 Reput.', imagenNombre: 'art_n_noble');
  static const Carta _pRejuvenecer = Carta(idInterno: 'HeroAction', nombre: 'Rejuvenecer', tipo: TipoCarta.accion, colorBase: ColorMana.verde, categoria: 'norowas', iconosPuntos: ['❤️'], textoBasico: 'Cura 1 o roba 1.', textoPotenciado: 'Cura 2 o roba 2.', imagenNombre: 'art_n_rejuv');


  // ===========================================================================
  // 2. DICCIONARIOS POR HÉROE (CON ASIGNACIÓN DE NÚMERO OFICIAL)
  // ===========================================================================

  static List<Carta> obtenerMazoTovak() {
    return [
      _pMarcha.copiarConNumero('017'),
      _pMarcha.copiarConNumero('018'),
      _pResistencia.copiarConNumero('019'),
      _pResistencia.copiarConNumero('020'),
      _pAgilidad.copiarConNumero('021'),
      _pAgilidad.copiarConNumero('022'),
      _pFuria.copiarConNumero('023'),
      _pFuria.copiarConNumero('024'),
      _pResistenciaFria.copiarConNumero('025'), // Unique
      _pTranquilidad.copiarConNumero('026'),
      _pPromesa.copiarConNumero('027'),
      _pAmenaza.copiarConNumero('028'),
      _pCristalizacion.copiarConNumero('029'),
      _pExtraccionMana.copiarConNumero('030'),
      _pConcentracion.copiarConNumero('031'),
      _pInstinto.copiarConNumero('032'), // Unique
    ];
  }

  static List<Carta> obtenerMazoGoldyx() {
    return [
      _pMarcha.copiarConNumero('049'),
      _pMarcha.copiarConNumero('050'),
      _pResistencia.copiarConNumero('051'),
      _pResistencia.copiarConNumero('052'),
      _pAgilidad.copiarConNumero('053'),
      _pAgilidad.copiarConNumero('054'),
      _pFuria.copiarConNumero('055'),
      _pFuria.copiarConNumero('056'),
      _pDeterminacion.copiarConNumero('057'),
      _pTranquilidad.copiarConNumero('058'),
      _pPromesa.copiarConNumero('059'),
      _pAmenaza.copiarConNumero('060'),
      _pAlegriaCristal.copiarConNumero('061'), // Unique
      _pExtraccionMana.copiarConNumero('062'),
      _pFocoVoluntad.copiarConNumero('063'),   // Unique
      _pImprovisacion.copiarConNumero('064'),
    ];
  }

  static List<Carta> obtenerMazoArythea() {
    return [
      _pMarcha.copiarConNumero('001'),
      _pMarcha.copiarConNumero('002'),
      _pResistencia.copiarConNumero('003'),
      _pResistencia.copiarConNumero('004'),
      _pAgilidad.copiarConNumero('005'),
      _pAgilidad.copiarConNumero('006'),
      _pFuria.copiarConNumero('007'),
      _pVersatilidad.copiarConNumero('008'), // Unique
      _pDeterminacion.copiarConNumero('009'),
      _pTranquilidad.copiarConNumero('010'),
      _pPromesa.copiarConNumero('011'),
      _pAmenaza.copiarConNumero('012'),
      _pCristalizacion.copiarConNumero('013'),
      _pSuccionMana.copiarConNumero('014'),  // Unique
      _pConcentracion.copiarConNumero('015'),
      _pImprovisacion.copiarConNumero('016'),
    ];
  }

  static List<Carta> obtenerMazoNorowas() {
    return [
      _pMarcha.copiarConNumero('033'),
      _pMarcha.copiarConNumero('034'),
      _pResistencia.copiarConNumero('035'),
      _pResistencia.copiarConNumero('036'),
      _pAgilidad.copiarConNumero('037'),
      _pAgilidad.copiarConNumero('038'),
      _pFuria.copiarConNumero('039'),
      _pFuria.copiarConNumero('040'),
      _pDeterminacion.copiarConNumero('041'),
      _pRejuvenecer.copiarConNumero('042'),    // Unique
      _pModalesNobles.copiarConNumero('043'),  // Unique
      _pAmenaza.copiarConNumero('044'),
      _pCristalizacion.copiarConNumero('045'),
      _pExtraccionMana.copiarConNumero('046'),
      _pConcentracion.copiarConNumero('047'),
      _pImprovisacion.copiarConNumero('048'),
    ];
  }
}
