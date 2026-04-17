import 'package:flutter/material.dart';
import '../models/sesion_juego.dart';
import '../models/carta.dart';
import 'widget_carta.dart';
import 'widget_strategic_panel.dart';

/// Widget principal de la mano del héroe.
///
/// Gestiona dos estados visuales:
///   - [Miniatura]: Abanico compacto inferior con cartas a escala reducida.
///   - [Zoom]: Visor táctico expansivo con cartas ampliadas en fan-layout.
///
/// La transición entre ambos estados usa el mecanismo [Hero] de Flutter,
/// que interpola posición, tamaño y rotación de cada carta individualmente,
/// dando la sensación de que el abanico "se expande" en el visor.
class WidgetMano extends StatefulWidget {
  final SesionJuego sesion;

  const WidgetMano({super.key, required this.sesion});

  @override
  State<WidgetMano> createState() => _WidgetManoState();
}

class _WidgetManoState extends State<WidgetMano> with TickerProviderStateMixin {
  // ── Estado de UI ─────────────────────────────────────────────────────────
  bool _expandida = false;
  Carta? _cartaZoom;

  // ── Controlador 1: Snap al soltar el carrusel ────────────────────────────
  double _zoomScrollOffset = 0.0;
  late AnimationController _snapController;
  Animation<double>? _snapAnimation;

  // ── Controlador 2: Fade del fondo oscuro al abrir/cerrar el visor ────────
  late AnimationController _transicionController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador de snap (inercia al soltar el arrastre)
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 550,
      ), // Un poco más lenta para elegancia
    );
    _snapController.addListener(() {
      if (_snapAnimation != null) {
        setState(() {
          _zoomScrollOffset = _snapAnimation!.value;
        });
      }
    });

    // Controlador de transición del fondo (fade in/out)
    _transicionController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 400,
      ), // Transición más pausada y fluida
    );
    _fadeAnimation = CurvedAnimation(
      parent: _transicionController,
      curve: Curves.easeInOutCubic, // Curva más orgánica
      reverseCurve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _snapController.dispose();
    _transicionController.dispose();
    super.dispose();
  }

  // ── Acciones de Navegación ────────────────────────────────────────────────

  void _toggleExpandida() {
    setState(() {
      _expandida = !_expandida;
    });
  }

  /// Abre el visor de zoom centrado en la carta tocada.
  /// Dispara el fade-in del fondo después de que el Hero inicia su vuelo.
  void _abrirZoom(Carta carta, List<Carta> mano) {
    final int idx = mano.indexOf(carta);
    setState(() {
      _cartaZoom = carta;
      _zoomScrollOffset = idx.toDouble();
    });
    // Iniciar el fade del fondo ligeramente retrasado para que el Hero vuele primero
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _transicionController.forward();
    });
  }

  /// Cierra el visor disparando el fade-out y la vuelta del Hero simultáneamente.
  void _cerrarZoom() {
    _transicionController.reverse();
    setState(() {
      _cartaZoom = null;
    });
  }

  // ── Gestión del arrastre horizontal del carrusel ──────────────────────────

  void _onDragUpdate(DragUpdateDetails details, int total) {
    if (total <= 1) return;
    setState(() {
      // Sensibilidad aumentada para mayor fluidez (divisor de 240)
      final double nuevo = _zoomScrollOffset - details.primaryDelta! / 240.0;
      _zoomScrollOffset = nuevo.clamp(-0.3, (total - 1) + 0.3);
    });
  }

  void _onDragEnd(DragEndDetails details, int total) {
    if (total <= 1) return;

    // Proyectar la posición destino con inercia
    final double velocity = details.primaryVelocity ?? 0;
    final double targetRaw = _zoomScrollOffset - (velocity / 1000.0);

    // Clampear al rango real de la mano [0, total-1]
    final double snapTarget = targetRaw.roundToDouble().clamp(
      0.0,
      (total - 1).toDouble(),
    );

    _snapAnimation = Tween<double>(begin: _zoomScrollOffset, end: snapTarget)
        .animate(
          CurvedAnimation(parent: _snapController, curve: Curves.easeOutQuart),
        );

    _snapController.forward(from: 0);
  }

  // ── Build Principal ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sesion.mazoHeroe,
      builder: (context, _) {
        final mano = widget.sesion.mazoHeroe.mano;

        return Stack(
          children: [
            // 1. Abanico de miniaturas (inferior)
            // IMPORTANTE: Siempre mantener en el árbol (maintainState) para que
            // el motor Hero de Flutter encuentre el widget origen durante el vuelo.
            // Se oculta visualmente (opacity 0) cuando el visor de zoom está activo.
            if (mano.isNotEmpty && !_expandida)
              Positioned(
                bottom: -60, // Se hunde más en el marco inferior
                left: 0,
                right: 0,
                child: Opacity(
                  // Invisible durante el zoom (pero presente en el árbol de widgets)
                  opacity: _cartaZoom != null ? 0.0 : 1.0,
                  child: Center(
                    child: SizedBox(
                      height: 140,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBottomFanHand(mano),
                          const SizedBox(width: 15),
                          _buildStrategicButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 2. Visor de zoom (se superpone cuando hay carta activa)
            if (_cartaZoom != null) _buildZoomOverlay(mano),

            // 3. Panel estratégico
            if (_expandida)
              Positioned.fill(
                child: WidgetStrategicPanel(
                  sesion: widget.sesion,
                  onClose: _toggleExpandida,
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Abanico Inferior (Miniaturas) ─────────────────────────────────────────

  /// Construye el abanico de cartas compactas en el borde inferior.
  ///
  /// Cada carta está envuelta en un [Hero] con tag único basado en su ID.
  /// Flutter usará esas claves para calcular la trayectoria de vuelo
  /// al abrir el visor de zoom.
  Widget _buildBottomFanHand(List<Carta> mano) {
    final int count = mano.length;
    return SizedBox(
      width: 60.0 + (count - 1) * 35.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(count, (i) {
          final carta = mano[i];

          // Posición relativa para la curvatura del abanico
          double rel = 0;
          if (count > 1) {
            rel = (i - (count - 1) / 2.0) / ((count - 1) / 2.0);
          }
          final double angle = rel * 0.15;
          final double dy =
              (rel * rel) * 20.0; // Curvatura vertical más pronunciada
          final double dx = i * 35.0;

          return Positioned(
            left: dx,
            top: dy,
            child: Transform.rotate(
              angle: angle,
              child: Hero(
                // Tag único por carta: clave de sincronización con el visor
                tag: 'carta_hero_${carta.idInterno}',
                // flightShuttleBuilder evita que el Hero use un color de fondo
                // que rompa la apariencia durante el vuelo
                flightShuttleBuilder: _heroEnVuelo,
                child: GestureDetector(
                  onTap: () => _abrirZoom(carta, mano),
                  child: WidgetCarta(carta: carta, compacta: true),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Visor de Zoom (Carrusel Fan-Layout Lineal) ────────────────────────────

  /// Construye el visor de zoom con carrusel lineal (no infinito).
  ///
  /// El carrusel refleja exactamente las [mano.length] cartas disponibles.
  /// La carta en el índice [_zoomScrollOffset] aparece centrada y ampliada.
  /// Las cartas a los lados siguen el mismo Fan-Layout que el abanico inferior.
  Widget _buildZoomOverlay(List<Carta> mano) {
    final int total = mano.length;

    return Stack(
      children: [
        // Fondo oscuro con animación de fade sincronizada con el Hero
        FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _cerrarZoom,
            child: Container(
              color: Colors.black.withValues(
                alpha: 0.55,
              ), // Mucho más transparente a petición del usuario
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),

        // Halo místico central (fijo, decorativo)
        FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Container(
              width: 280, // Halo más pequeño y centrado
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFFFFD700,
                    ).withValues(alpha: 0.06), // Efecto más tenue
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Carrusel Fan-Layout Lineal con detección de arrastre
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _cerrarZoom, // Cierra al tocar áreas vacías del carrusel
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, total),
          onHorizontalDragEnd: (d) => _onDragEnd(d, total),
          child: Center(
            child: SizedBox(
              height: 600,
              width: MediaQuery.of(context).size.width,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children:
                    List.generate(total, (i) {
                        final c = mano[i];

                        // Distancia LINEAL desde el centro (sin aritmética modular)
                        final double diff = i - _zoomScrollOffset;
                        final double absDiff = diff.abs();
                        final bool isCenterFocus = absDiff < 0.5;

                        // Cartas muy alejadas se vuelven invisibles por escala
                        // (no reaparecen por el otro lado como en el bucle infinito)
                        if (absDiff > 3.0) return const SizedBox.shrink();

                        // Geometría Fan-Layout (Agrandado Heroico)
                        final double scale = (3.2 - (absDiff * 1.1)).clamp(
                          0.1,
                          3.2,
                        );
                        final double dx =
                            diff * 110.0; // Espaciado ajustado a escala
                        final double dy =
                            (diff * diff) * 7.0; // Curvatura sutil reforzada
                        final double rotation = diff * 0.05;

                        return Positioned(
                          key: ValueKey('zoom_${c.idInterno}'),
                          left:
                              (MediaQuery.of(context).size.width / 2) +
                              dx -
                              22.5,
                          bottom: 150 - dy,
                          child: IgnorePointer(
                            // Solo la carta central es interactiva
                            ignoring: absDiff > 0.8,
                            child: Transform(
                              transform: Matrix4.identity()
                                ..scaleByDouble(scale, scale, 1.0, 1.0)
                                ..rotateZ(rotation),
                              alignment: Alignment.center,
                              child: Hero(
                                // Mismo tag que en el abanico: Flutter sincroniza el vuelo
                                tag: 'carta_hero_${c.idInterno}',
                                flightShuttleBuilder: _heroEnVuelo,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isCenterFocus
                                            ? const Color(
                                                0xFFFFD700,
                                              ).withValues(alpha: 0.55)
                                            : Colors.black.withValues(
                                                alpha: 0.45,
                                              ),
                                        blurRadius: isCenterFocus ? 28 : 10,
                                        spreadRadius: isCenterFocus ? 4 : 0,
                                      ),
                                    ],
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Absorbe el tap para que la carta central no cierre el visor
                                    },
                                    child: WidgetCarta(
                                      carta: c,
                                      compacta: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                      // Ordenar por Z-Index: cartas más cercanas al centro van encima
                      ..sort((a, b) {
                        if (a is SizedBox) return -1;
                        if (b is SizedBox) return 1;
                        final keyA =
                            (a.key as ValueKey?)?.value as String? ?? '';
                        final keyB =
                            (b.key as ValueKey?)?.value as String? ?? '';
                        final idxA = mano.indexWhere(
                          (c) => 'zoom_${c.idInterno}' == keyA,
                        );
                        final idxB = mano.indexWhere(
                          (c) => 'zoom_${c.idInterno}' == keyB,
                        );
                        final dA = (idxA - _zoomScrollOffset).abs();
                        final dB = (idxB - _zoomScrollOffset).abs();
                        return dB.compareTo(dA);
                      }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Botón Estratégico ────────────────────────────────────────────────────

  Widget _buildStrategicButton() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 51,
      ), // Compensación por el hundimiento del Positioned
      child: GestureDetector(
        onTap: _toggleExpandida,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1B2838).withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            color: Color(0xFFFFD700),
            size: 20,
          ),
        ),
      ),
    );
  }

  // ── Helper: Hero Flight Shuttle ──────────────────────────────────────────

  /// Builder personalizado para el widget visible DURANTE el vuelo Hero.
  ///
  /// Usa siempre la representación compacta de la carta (igual en ambos estados)
  /// envuelta en Material transparente para que el motor Hero no pinte
  /// fondos blancos por defecto durante la animación.
  Widget _heroEnVuelo(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    // Tomar el widget del contexto origen (miniatura o zoom según dirección)
    final Widget fromWidget = fromHeroContext.widget is Hero
        ? (fromHeroContext.widget as Hero).child
        : fromHeroContext.widget;

    return Material(color: Colors.transparent, child: fromWidget);
  }
}
