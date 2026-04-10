import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hexagono.dart';
import '../models/heroe.dart'; // [Fase 2A] Catálogo de héroes
import '../models/loseta.dart';
import '../widgets/widget_mapa.dart';
import '../models/fuente_magia.dart'; // [Fase 2C]
import '../widgets/widget_fuente_mana.dart'; // [Fase 2C]
import '../models/sesion_juego.dart'; // [Fase 4] GameState unificado
import '../config/catalogo_escenarios.dart'; // [Fase 4] Registro de escenarios
import '../widgets/widget_historial.dart'; // [Fase 4B] Panel de memoria
import '../core/constants.dart'; // [Fase 4]
import '../widgets/widget_mano.dart'; // [Fase 5A] Interfaz de la Mano

/// Pantalla principal del juego Mage Knight.
///
/// Gestiona el estado del mapa: las celdas colocadas, el mazo de losetas
/// y el hexágono actualmente seleccionado.
///
/// Layout:
///   - AppBar con título y contador de losetas restantes
///   - Mapa hexagonal interactivo (WidgetMapa) al centro
///   - BottomSheet deslizable con info del hex seleccionado
class PantallaJuego extends StatefulWidget {
  const PantallaJuego({super.key});

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  // ── [Fase 4] GameState Unificado ─────────────────────────────────────────
  /// SesionJuego agrupa MapaJuego + FuenteMagia + undo/redo en un solo objeto.
  late SesionJuego _sesion;

  /// Getters de compatibilidad — permiten que TODO el código existente que
  /// usa `_mapa` y `_fuenteMagia` siga funcionando sin modificaciones.
  MapaJuego get _mapa => _sesion.mapa;
  FuenteMagia get _fuenteMagia => _sesion.fuente;

  // ── Estado de UI ─────────────────────────────────────────────────────────
  /// Loseta seleccionada actualmente (para el BottomSheet)
  Hexagono? _hexSeleccionado;

  /// Controla si se muestra el panel inferior de información
  bool _mostrarInfo = false;

  /// Controla la visibilidad del Panel de Recursos Estratégicos [Fase 2B]
  bool _mostrarEstrategia = true;

  /// Controla la visibilidad del Panel de La Fuente [Fase 2C v2.2]
  bool _mostrarFuente = true;

  /// Controla la visibilidad del Pergamino de Memoria (Historial) [Fase 4B]
  bool _mostrarHistorial = false;

  /// Sistema de notificaciones superior
  String? _mensajeTop;
  Timer? _timerTop;

  /// Clave para acceder a las funciones internas de WidgetMapa (como recentrar)
  final GlobalKey<WidgetMapaState> _mapaKey = GlobalKey<WidgetMapaState>();

  /// Controla el modo de centrado cíclico (Mapa vs Héroe) [Fase 1M]
  bool _proximoCentradoEsHeroe = true;

  // [Fase 4] La FuenteMagia ya NO se instancia aquí; vive dentro de SesionJuego.
  // Se accede vía el getter _fuenteMagia definido arriba.

  // -------------------------------------------------------------------------
  // Catálogo de Héroes disponibles [Fase 2A]
  // -------------------------------------------------------------------------

  /// Lista de todos los héroes jugables con su identidad visual completa.
  static const List<Map<String, Object>> _catalogoHeroes = [
    {
      'nombre': 'Tovak',
      'imageName': 'heroe1',
      'icono': '🛡️',
      'color': Color(0xFFFFD700), // Dorado: el Caballero clásico
      'colorRastro': Color(0xFFFFAA00), // Rastro ámbar/cálido
    },
    {
      'nombre': 'Goldyx',
      'imageName': 'heroe2',
      'icono': '🔥',
      'color': Color(0xFFE53935), // Rojo: la Guerrera del fuego
      'colorRastro': Color(0xFFFF1744), // Rastro rojo/plasma
    },
  ];

  /// Índice del héroe actualmente seleccionado [Fase 2A]
  int _indiceHeroeActivo = 0;

  /// Crea un Heroe a partir del catálogo según el índice dado.
  Heroe _crearHeroeDesdeCatalogo(int indice, {int q = 0, int r = 0}) {
    final datos = _catalogoHeroes[indice];
    final reglas = CatalogoEscenarios.porDefecto.reglas;
    return Heroe(
      nombre: datos['nombre'] as String,
      imageName: datos['imageName'] as String,
      icono: datos['icono'] as String,
      color: datos['color'] as Color,
      colorRastro: datos['colorRastro'] as Color,
      q: q,
      r: r,
      puntosMovimiento: reglas.puntosMovimientoInicial(
        datos['nombre'] as String,
      ),
      puntosInfluencia: reglas.puntosInfluenciaInicial(
        datos['nombre'] as String,
      ),
      puntosAtaque: reglas.puntosAtaqueInicial(datos['nombre'] as String),
      puntosBloqueo: reglas.puntosBloqueoInicial(datos['nombre'] as String),
      puntosCuracion: reglas.puntosCuracionInicial(datos['nombre'] as String),
    );
  }

  /// Cambia al siguiente héroe del catálogo en tiempo real [Fase 2A]
  void _cambiarHeroe() {
    final nuevoIndice = (_indiceHeroeActivo + 1) % _catalogoHeroes.length;
    final heroeActual = _mapa.heroe;
    setState(() {
      _indiceHeroeActivo = nuevoIndice;
      // Reasignar el nuevo héroe conservando la posición actual en el mapa
      _mapa.heroe = _crearHeroeDesdeCatalogo(
        nuevoIndice,
        q: heroeActual?.q ?? 0,
        r: heroeActual?.r ?? 0,
      );
    });
    _mostrarMensaje(
      'Héroe cambiado a ${_catalogoHeroes[nuevoIndice]['nombre']}.',
    );
  }

  @override
  void initState() {
    super.initState();
    _inicializarSesion(); // [Fase 4] FuenteMagia se crea internamente en SesionJuego
  }

  @override
  void dispose() {
    _timerTop?.cancel();
    _sesion.removeListener(_alActualizarEstado);
    _sesion.dispose();
    super.dispose();
  }

  /// [Fase 4] Inicializa la SesionJuego con el escenario y el héroe seleccionado.
  /// Reemplaza a _inicializarMapa() centralizando todo en SesionJuego.
  void _inicializarSesion() {
    final escenario = CatalogoEscenarios.porDefecto;
    final heroeInicial = _crearHeroeDesdeCatalogo(_indiceHeroeActivo);
    _sesion = SesionJuego();
    _sesion.inicializar(escenario: escenario, heroeInicial: heroeInicial);
    _sesion.addListener(_alActualizarEstado);
  }

  /// Callback de SesionJuego: sincroniza la UI cuando cambia el estado del juego.
  void _alActualizarEstado() {
    if (mounted) setState(() {});
  }

  // -------------------------------------------------------------------------
  // Handlers de eventos del mapa
  // -------------------------------------------------------------------------

  /// Se dispara cuando el usuario toca un hexágono normal (selección/inspección).
  void _alSeleccionarHex(Hexagono hex) {
    setState(() {
      _hexSeleccionado = hex;
      _mostrarInfo = true;
    });
  }

  /// Gestiona exclusivamente el MOVIMIENTO del héroe vía Drag & Drop (Soltar pieza).
  void _alMoverHeroe(int q, int r) {
    if (_mapa.heroe != null && _mapa.puedeMoverseA(q, r)) {
      // [Fase 4C] Usar SesionJuego para que la acción se registre en el historial
      final exito = _sesion.moverHeroe(q, r);
      if (exito) {
        setState(() {
          _mostrarMensaje(
            'Movimiento exitoso. P(m): ${_mapa.heroe?.puntosMovimiento}',
          );
        });
      }
    } else if (_mapa.heroe != null &&
        (q != _mapa.heroe!.q || r != _mapa.heroe!.r)) {
      _mostrarMensaje('Movimiento inválido o P(m) insuficientes.');
    }
  }

  /// Se dispara cuando el usuario toca un hexágono fantasma → expandir mapa.
  void _alExpandirMapa(int q, int r) {
    if (_mapa.mazoAgotado) {
      _mostrarMensaje('El mazo de exploración está agotado.');
      return;
    }

    // [Fase 4C] Usar SesionJuego para expandir (acción irreversible pero registrada)
    final exito = _sesion.expandirMapa(q, r);

    if (exito && !_mapa.mazoAgotado) {
      _mostrarMensaje(
        '¡Territorio revelado! ${_mapa.losetasRestantes} losetas restantes.',
      );
    } else if (exito && _mapa.mazoAgotado) {
      _mostrarMensaje('¡Mapa completamente explorado!');
    }
  }

  /// Oculta el panel si se presiona fuera o en un lugar vacío
  void _alTocarVacio() {
    setState(() {
      _hexSeleccionado = null;
      _mostrarInfo = false;
    });
  }

  /// Muestra una notificación en la parte superior de la pantalla.
  void _mostrarMensaje(String mensaje) {
    _timerTop?.cancel();
    setState(() {
      _mensajeTop = mensaje;
    });

    _timerTop = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _mensajeTop = null;
        });
      }
    });
  }

  /// [Fase 4F] Muestra un diálogo de confirmación genérico para acciones críticas.
  void _mostrarDialogoConfirmacion({
    required String titulo,
    required String mensaje,
    required VoidCallback onConfirmar,
  }) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.fondoPanel.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.dorado.withValues(alpha: 0.5)),
          ),
          title: Text(
            titulo,
            style: GoogleFonts.marcellus(
              color: AppColors.dorado,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            mensaje,
            style: GoogleFonts.marcellus(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCELAR',
                style: GoogleFonts.marcellus(color: Colors.white24),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dorado.withValues(alpha: 0.2),
                foregroundColor: AppColors.dorado,
                side: const BorderSide(color: AppColors.dorado),
              ),
              onPressed: () {
                Navigator.pop(context);
                onConfirmar();
              },
              child: Text(
                'CONFIRMAR',
                style: GoogleFonts.marcellus(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [Fase 4F] Muestra un modal central con información de la partida y comandos administrativos.
  void _mostrarDialogoPartida() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 5,
          sigmaY: 5,
        ), // [Fase 4F.7] Igual que confirmación
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.fondoPanel.withValues(
                alpha: 0.9,
              ), // [Fase 4F.7] Consistente con confirmación
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.dorado.withValues(alpha: 0.3),
              ), // [Fase 4F.7] Dorado
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CENTRO DE MANDO',
                  style: GoogleFonts.marcellus(
                    color: AppColors.dorado, // [Fase 4F.7] Dorado habitual
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16), // [Fase 4F.1] Reducido
                // Conteo de losetas (Movido de la AppBar)
                _buildInfoRow('Losetas Restantes', '${_mapa.losetasRestantes}'),
                const SizedBox(height: 12),
                _buildInfoRow('Turno Actual', '${_sesion.turnoActual}'),

                const SizedBox(height: 24),

                // Opción de Cambiar Héroe (Movido de la AppBar para mayor limpieza)
                if (_mapa.heroe != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _mapa.heroe!.color,
                        side: BorderSide(
                          color: _mapa.heroe!.color.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _cambiarHeroe();
                      },
                      icon: const Icon(Icons.portrait),
                      label: Text(
                        'CAMBIAR HÉROE (${_mapa.heroe!.nombre})',
                        style: GoogleFonts.marcellus(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Botón Reiniciar (Movido de la AppBar) - [Fase 4F.1] Color azul táctico
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dorado.withValues(alpha: 0.1),
                      foregroundColor: AppColors.dorado,
                      side: BorderSide(
                        color: AppColors.dorado.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _mostrarDialogoConfirmacion(
                        titulo: 'REINICIAR PARTIDA',
                        mensaje:
                            '¿Estás seguro de que deseas perder todo tu progreso actual?',
                        onConfirmar: () {
                          _sesion.removeListener(_alActualizarEstado);
                          _sesion.dispose();
                          setState(() {
                            _inicializarSesion();
                            _hexSeleccionado = null;
                            _mostrarInfo = false;
                          });
                        },
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'REINICIAR PARTIDA',
                      style: GoogleFonts.marcellus(
                        fontWeight: FontWeight.bold,
                        fontSize: 10, // Un poco más pequeño
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Reducido
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'VOLVER AL JUEGO',
                    style: GoogleFonts.marcellus(
                      color: AppColors.dorado.withValues(
                        alpha: 0.6,
                      ), // [Fase 4F.7] Dorado translúcido
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String etiqueta, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: GoogleFonts.marcellus(color: Colors.white54)),
        Text(
          valor,
          style: GoogleFonts.marcellus(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Stack(
        children: [
          // Mapa principal — ocupa todo el fondo
          WidgetMapa(
            key: _mapaKey,
            celdas: _mapa.celdas,
            heroe: _mapa.heroe,
            puedeMoverseA: (q, r) => _mapa.puedeMoverseA(q, r),
            obtenerCostoRuta: (q1, r1, q2, r2) =>
                _mapa.calcularCostoRuta(q1, r1, q2, r2),
            posicionesFantasma: _mapa.posicionesFantasma,
            onHexSeleccionado: _alSeleccionarHex,
            onHeroeMovido: _alMoverHeroe,
            onExpandir: _alExpandirMapa,
            onTapVacio: _alTocarVacio,
            tamanoHex: 52.0,
          ),

          // AppBar personalizada posicionada en el Stack
          Positioned(top: 0, left: 0, right: 0, child: _construirAppBar()),

          // [Fase 2C] Panel de "La Fuente" (Opción B: Flotando arriba a la izquierda)
          if (_mostrarFuente)
            Positioned(
              top: 70,
              left: 16,
              child: WidgetFuenteMana(
                fuente: _fuenteMagia,
                onCicloTap: () => _sesion
                    .cambiarCiclo(), // [Fase 4C] Inyectar motor de historial
              ),
            ),

          // [Fase 4B] Panel de "El Pergamino de Memoria" (Flotando a la derecha)
          if (_mostrarHistorial)
            Positioned(
              top: 70,
              right: 16,
              child: WidgetHistorial(sesion: _sesion),
            ),

          // [Fase 2B] Panel de Recursos Estratégicos (Sustituye a la leyenda)
          if (_mostrarEstrategia)
            Positioned(
              left: 12,
              bottom: 12, // [Fase 5F] Posición fija, ya no depende de _mostrarInfo
              child: _panelEstrategico(),
            ),

          // Panel de información del hex seleccionado (Relocalizado al espacio del Historial)
          if (_mostrarInfo && _hexSeleccionado != null)
            Positioned(
              top: 70,
              right: 16,
              child: _construirPanelInfo(_hexSeleccionado!),
            ),

          // Botón de Recentrar (Ajuste de Vista) — Estética Premium
          Positioned(
            right: 16,
            bottom: 16, // [Fase 5F] Posición fija, el panel de detalles ahora está arriba
            child: _construirBotonRecentrar(),
          ),

          // [Fase 5A] La Mano de Cartas del Héroe
          WidgetMano(sesion: _sesion),

          // Notificación superior (Top Toast)
          if (_mensajeTop != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: _construirNotificacionTop(),
            ),
        ],
      ),
    );
  }

  /// Construye el botón flotante premium para recentrar el mapa.
  Widget _construirBotonRecentrar() {
    return GestureDetector(
      onTap: () {
        if (_proximoCentradoEsHeroe) {
          // Centrado en el Héroe [Fase 1M]
          final h = _mapa.heroe;
          _mapaKey.currentState?.recentrarMapa(targetQ: h?.q, targetR: h?.r);
          _mostrarMensaje('Cámara centrada en el Héroe.');
        } else {
          // Centrado Global del Mapa [Fase 1L]
          _mapaKey.currentState?.recentrarMapa();
          _mostrarMensaje('Cámara ajustada al territorio explorado.');
        }

        setState(() {
          _proximoCentradoEsHeroe = !_proximoCentradoEsHeroe;
          _mostrarInfo = false;
          _hexSeleccionado = null;
        });
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1B2838).withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _proximoCentradoEsHeroe ? Icons.directions_run : Icons.explore,
          color: const Color(0xFFFFD700),
          size: 28,
        ),
      ),
    );
  }

  /// Construye el widget de notificación flotante superior.
  Widget _construirNotificacionTop() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2838).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                _mensajeTop!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el widget que simula una AppBar minimalista (48px) [Fase 4F].
  Widget _construirAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: Color(0xFF12002B),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: SizedBox(
        height: 48, // [Fase 4F] Reducido de 56
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sección Izquierda: Título
            Positioned(
              left: 16,
              child: Text(
                'Mage Knight',
                style: GoogleFonts.marcellus(
                  color: const Color(0xFFFFD700),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),

            // Sección Central: Botón Fin de Turno [Fase 4F.3]
            ActionChip(
              backgroundColor: const Color(0xFF004D40),
              visualDensity: VisualDensity.compact,
              avatar: const Icon(
                Icons.hourglass_bottom,
                color: Colors.white,
                size: 12,
              ),
              label: Text(
                'Turno',
                style: GoogleFonts.marcellus(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                _mostrarDialogoConfirmacion(
                  titulo: 'FINALIZAR TURNO',
                  mensaje:
                      '¿Has completado todas tus acciones? No podrás deshacer una vez confirmado.',
                  onConfirmar: () {
                    setState(() {
                      _sesion.finDeTurno(pmRecarga: 12);
                      _mostrarMensaje('Turno finalizado. P(m) restaurados.');
                    });
                  },
                );
              },
            ),

            // Sección Derecha: Iconos Tácticos
            Positioned(
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // [Fase 2B] Botón Toggle del Panel Estratégico (Puntos)
                  IconButton(
                    onPressed: () => setState(
                      () => _mostrarEstrategia = !_mostrarEstrategia,
                    ),
                    icon: Icon(
                      _mostrarEstrategia
                          ? Icons.dashboard
                          : Icons.dashboard_outlined,
                      color: _mostrarEstrategia
                          ? AppColors.dorado
                          : Colors.white70,
                      size: 18,
                    ),
                    tooltip: 'Mostrar recursos estratégicos',
                  ),

                  // [Fase 2C] Botón Táctico: Mostrar / Ocultar Panel de Dados
                  ListenableBuilder(
                    listenable: _fuenteMagia,
                    builder: (context, _) {
                      bool esDia = _fuenteMagia.cicloActual == CicloMundo.dia;
                      return IconButton(
                        onPressed: () =>
                            setState(() => _mostrarFuente = !_mostrarFuente),
                        icon: Icon(
                          esDia ? Icons.wb_sunny : Icons.nights_stay,
                          color: _mostrarFuente
                              ? (esDia ? Colors.amber : Colors.blueGrey)
                              : Colors.white24,
                          size: 18,
                        ),
                        tooltip: _mostrarFuente
                            ? 'Ocultar La Fuente'
                            : 'Mostrar La Fuente',
                      );
                    },
                  ),

                  // [Fase 2C] Botón Táctico: Re-Roll Manual (Lanzar Fuente)
                  IconButton(
                    onPressed: () {
                      _fuenteMagia.lanzarDados(rerollAgotados: true);
                      _mostrarMensaje('Los dados agotados se han relanzado.');
                    },
                    icon: const Icon(
                      Icons.casino,
                      color: Colors.white70,
                      size: 18,
                    ),
                    tooltip: 'Relanzar Dados Agotados',
                  ),

                  // [Fase 4B/4C] Botón Táctico: Historial
                  IconButton(
                    onPressed: () =>
                        setState(() => _mostrarHistorial = !_mostrarHistorial),
                    icon: Icon(
                      Icons.history_edu,
                      color: _mostrarHistorial
                          ? AppColors.dorado
                          : Colors.white70,
                      size: 20,
                    ),
                    tooltip: _mostrarHistorial
                        ? 'Cerrar Pergamino'
                        : 'Ver Pergamino de Memoria',
                  ),

                  // [Fase 4F] Botón de Información General
                  IconButton(
                    onPressed: _mostrarDialogoPartida,
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                      size: 20,
                    ),
                    tooltip: 'Ver estado de la partida',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el panel de información del hex seleccionado con estilo Glassmorphism vertical compacto.
  Widget _construirPanelInfo(Hexagono hex) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 190,
          height:
              MediaQuery.of(context).size.height *
              0.8, // [Fase 5F] Tamaño fijo igualado al Historial
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF1B0035), // [Fase 5F] Reversión a mayor opacidad
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.dorado.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.max, // [Fase 5F] Ocupar todo el alto fijo
            children: [
              // ── Cabecera Compacta ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DETALLES',
                    style: GoogleFonts.marcellus(
                      color: AppColors.dorado,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white24,
                      size: 14,
                    ),
                    onPressed: () => setState(() => _mostrarInfo = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
              const Divider(
                color: Colors.white10,
                height: 4,
              ), // [Fase 5F] Reducido de 12
              // ── Contenido con Scroll si es necesario ──────────────────────
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── Icono y Título ──────────────────────────────────
                      Center(
                        child: Text(
                          hex.iconoSitioStr != null
                              ? '${hex.iconoTerrenoStr} ${hex.iconoSitioStr}'
                              : hex.iconoTerrenoStr,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hex.sitio != null
                            ? stringSitio(hex.sitio!).toUpperCase()
                            : _nombreTerreno(hex.tipo).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hex.sitio != null)
                        Text(
                          _nombreTerreno(hex.tipo),
                          style: GoogleFonts.cinzel(
                            color: AppColors.dorado,
                            fontSize: 9,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // ── Costo de Movimiento ──────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: hex.esTransitable
                              ? const Color(0xFF4A148C).withValues(alpha: 0.3)
                              : const Color(0xFF7B0000).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hex.esTransitable
                                ? const Color(0xFF4A148C)
                                : const Color(0xFF7B0000),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              hex.esTransitable ? '${hex.costo}' : '∞',
                              style: GoogleFonts.cinzel(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'MOVIMIENTO',
                              style: GoogleFonts.cinzel(
                                color: Colors.white60,
                                fontSize: 7,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Coordenadas y Clase ──────────────────────────────
                      Text(
                        'Pos: (${hex.q}, ${hex.r})',
                        style: GoogleFonts.marcellus(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _descripTipoLoseta(hex.tipoLoseta),
                        style: GoogleFonts.marcellus(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Descripción ─────────────────────────────────────
                      Text(
                        _descripcionTerreno(hex.tipo),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.marcellus(
                          color: Colors.white70,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Panel lateral con los recursos tácticos del héroe [Fase 2B]
  Widget _panelEstrategico() {
    final h = _mapa.heroe;
    if (h == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8), // [Fase 4E] Reducido de 12
      decoration: BoxDecoration(
        color: const Color(0xCC1A1B2D), // Vidrio esmerilado oscuro
        borderRadius: BorderRadius.circular(10), // [Fase 4E] Reducido de 15
        border: Border.all(color: Colors.white12),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _filaRecurso('👣 P(m)', h.puntosMovimiento, const Color(0xFF2196F3)),
          const SizedBox(height: 4), // [Fase 4E] Reducido de 8
          _filaRecurso('👤 P(i)', h.puntosInfluencia, const Color(0xFF9C27B0)),
          const SizedBox(height: 4),
          _filaRecurso('⚔️ P(a)', h.puntosAtaque, const Color(0xFFF44336)),
          const SizedBox(height: 4),
          _filaRecurso('🛡️ P(b)', h.puntosBloqueo, const Color(0xFF4CAF50)),
          const SizedBox(height: 4),
          _filaRecurso('❤️ P(c)', h.puntosCuracion, const Color(0xFFE91E63)),
        ],
      ),
    );
  }

  Widget _filaRecurso(String etiqueta, int valor, Color colorBase) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 75, // [Fase 4E] Reducido de 90
          child: Text(
            etiqueta,
            style: GoogleFonts.marcellus(
              // [Fase 4E] Cambio de fuente
              color: Colors.white70,
              fontSize: 11, // [Fase 4E] Reducido de 13
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorBase.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorBase.withValues(alpha: 0.5)),
          ),
          child: Text(
            valor.toString(),
            style: GoogleFonts.marcellus(
              // [Fase 4E] Cambio de fuente
              color: Colors.white,
              fontSize: 10, // [Fase 4E] Reducido de 12
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Datos de texto del terreno
  // -------------------------------------------------------------------------

  String _nombreTerreno(TipoTerreno tipo) {
    switch (tipo) {
      case TipoTerreno.pradera:
        return 'Pradera';
      case TipoTerreno.colina:
        return 'Colina';
      case TipoTerreno.bosque:
        return 'Bosque';
      case TipoTerreno.paramo:
        return 'Páramo';
      case TipoTerreno.desierto:
        return 'Desierto';
      case TipoTerreno.pantano:
        return 'Pantano';
      case TipoTerreno.montania:
        return 'Montaña';
      case TipoTerreno.lago:
        return 'Lago';
      case TipoTerreno.ciudad:
        return 'Sitio de Ciudad';
    }
  }

  String _descripcionTerreno(TipoTerreno tipo) {
    switch (tipo) {
      case TipoTerreno.pradera:
        return 'Llanura abierta. Fácil de atravesar.';
      case TipoTerreno.colina:
        return 'Elevaciones suaves que dificultan ligeramente el paso.';
      case TipoTerreno.bosque:
        return 'Vegetación densa. Dificulta el avance.';
      case TipoTerreno.paramo:
        return 'Tierra devastada. Muy dura de cruzar.';
      case TipoTerreno.desierto:
        return 'Dunas de arena sofocantes. El movimiento es agotador.';
      case TipoTerreno.pantano:
        return 'Terreno fangoso. Ralentiza el paso.';
      case TipoTerreno.montania:
        return 'Picos intransitables sin habilidades especiales.';
      case TipoTerreno.lago:
        return 'Masa de agua. Intransitable sin embarcación.';
      case TipoTerreno.ciudad:
        return 'Terreno urbanizado y fortificado.';
    }
  }

  String _descripTipoLoseta(TipoLoseta tipo) {
    switch (tipo) {
      case TipoLoseta.inicial:
        return 'Loseta inicial (Portal)';
      case TipoLoseta.campo:
        return 'Loseta de campo (verde)';
      case TipoLoseta.nucleo:
        return 'Loseta central (marron)';
    }
  }
}
