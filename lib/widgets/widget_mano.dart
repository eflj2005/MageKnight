import 'package:flutter/material.dart';
import '../models/sesion_juego.dart';
import '../models/carta.dart';
import 'widget_carta.dart';
import 'widget_strategic_panel.dart';

class WidgetMano extends StatefulWidget {
  final SesionJuego sesion;

  const WidgetMano({super.key, required this.sesion});

  @override
  State<WidgetMano> createState() => _WidgetManoState();
}

class _WidgetManoState extends State<WidgetMano>
    with SingleTickerProviderStateMixin {
  bool _expandida = false;
  Carta? _cartaZoom;

  // Estado para el carrusel interactivo infinito
  double _zoomScrollOffset = 0.0;
  late AnimationController _snapController;
  Animation<double>? _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _snapController.addListener(() {
      if (_snapAnimation != null) {
        setState(() {
          _zoomScrollOffset = _snapAnimation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _toggleExpandida() {
    setState(() {
      _expandida = !_expandida;
    });
  }

  void _setZoom(Carta? carta) {
    if (carta != null) {
      final mano = widget.sesion.mazoHeroe.mano;
      final idx = mano.indexOf(carta);
      setState(() {
        _cartaZoom = carta;
        _zoomScrollOffset = idx.toDouble();
      });
    } else {
      setState(() {
        _cartaZoom = null;
      });
    }
  }

  void _onDragUpdate(DragUpdateDetails details, int total) {
    if (total <= 1) return;
    setState(() {
      // Sensibilidad aumentada: divisor reducido a 300
      _zoomScrollOffset -= details.primaryDelta! / 300.0;
    });
  }

  void _onDragEnd(DragEndDetails details, int total) {
    if (total <= 1) return;

    // Inercia más ligera
    final double velocity = details.primaryVelocity ?? 0;
    final double targetOffset = _zoomScrollOffset - (velocity / 1000.0);
    final double snapTarget = targetOffset.roundToDouble();

    _snapAnimation = Tween<double>(begin: _zoomScrollOffset, end: snapTarget)
        .animate(
          CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
        );

    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sesion.mazoHeroe,
      builder: (context, _) {
        final mano = widget.sesion.mazoHeroe.mano;

        return Stack(
          children: [
            // Mano en abanico normal (inferior)
            if (mano.isNotEmpty && !_expandida)
              Positioned(
                bottom: -9,
                left: 0,
                right: 0,
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

            // Visor Único Infinito (Zoom)
            if (_cartaZoom != null) _buildZoomOverlay(mano),

            // Panel Estratégico
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

  Widget _buildZoomOverlay(List<Carta> mano) {
    final int total = mano.length;

    return Stack(
      children: [
        // Fondo con mayor oscuridad para inmersión
        GestureDetector(
          onTap: () => _setZoom(null),
          child: Container(
            color: Colors.black.withOpacity(0.95),
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Elemento Visual: Halo central místico
        Center(
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Carrusel Infinito Mountain-Fan
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, total),
          onHorizontalDragEnd: (d) => _onDragEnd(d, total),
          child: Center(
            child: SizedBox(
              height: 600, // Carrusel mucho más grande
              width: MediaQuery.of(context).size.width,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children:
                    List.generate(total, (i) {
                      final c = mano[i];

                      // Lógica Circular Infinita
                      double diff = (i - _zoomScrollOffset) % total;
                      if (diff > total / 2) diff -= total;
                      if (diff < -total / 2) diff += total;

                      final double absDiff = diff.abs();
                      final bool isCenterFocus = absDiff < 0.5;

                      // Geometría Fan Layout (Refinada: más grande, menos curva)
                      final double scale = 4 - (absDiff * 0.9).clamp(0, 1.8);
                      final double dx =
                          diff *
                          100.0; // Espaciado ampliado para cartas más grandes
                      final double dy =
                          (diff * diff) * 6.0; // Curvatura mucho más sutil
                      final double rotation = diff * 0.05; // Rotación mínima

                      return Positioned(
                        key: ValueKey(
                          'inf_zoom_${c.idInterno}_${c.numeroCarta}',
                        ),
                        left:
                            (MediaQuery.of(context).size.width / 2) + dx - 22.5,
                        bottom: 150 - dy, // Centrado en los 600 de altura
                        child: IgnorePointer(
                          ignoring: absDiff > 0.8,
                          child: Transform(
                            transform: Matrix4.identity()
                              ..scale(scale)
                              ..rotateZ(rotation),
                            alignment: Alignment.center,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: isCenterFocus
                                        ? const Color(
                                            0xFFFFD700,
                                          ).withOpacity(0.6)
                                        : Colors.black.withOpacity(0.5),
                                    blurRadius: isCenterFocus ? 30 : 12,
                                    spreadRadius: isCenterFocus ? 5 : 0,
                                  ),
                                ],
                              ),
                              child: WidgetCarta(carta: c, compacta: true),
                            ),
                          ),
                        ),
                      );
                    })..sort((a, b) {
                      // Z-Index dinámico basado en proximidad al centro real
                      final keyA = (a.key as ValueKey).value as String;
                      final keyB = (b.key as ValueKey).value as String;

                      final idxA = mano.indexWhere(
                        (c) =>
                            'inf_zoom_${c.idInterno}_${c.numeroCarta}' == keyA,
                      );
                      final idxB = mano.indexWhere(
                        (c) =>
                            'inf_zoom_${c.idInterno}_${c.numeroCarta}' == keyB,
                      );

                      double dA = (idxA - _zoomScrollOffset) % total;
                      if (dA > total / 2) dA -= total;
                      if (dA < -total / 2) dA += total;

                      double dB = (idxB - _zoomScrollOffset) % total;
                      if (dB > total / 2) dB -= total;
                      if (dB < -total / 2) dB += total;

                      return dB.abs().compareTo(dA.abs());
                    }),
              ),
            ),
          ),
        ),

        // Botón cerrar visor (X)
        Positioned(
          top: 40,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 36),
            onPressed: () => _setZoom(null),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomFanHand(List<Carta> mano) {
    final int count = mano.length;
    return SizedBox(
      width: 60.0 + (count - 1) * 35.0,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(count, (i) {
          final carta = mano[i];
          double rel = 0;
          if (count > 1) {
            rel = (i - (count - 1) / 2.0) / ((count - 1) / 2.0);
          }
          final double angle = rel * 0.15;
          final double dy = (rel * rel) * 15.0;
          final double dx = i * 35.0;
          return Positioned(
            left: dx,
            top: dy,
            child: Transform.rotate(
              angle: angle,
              child: WidgetCarta(
                carta: carta,
                compacta: true,
                onTap: () => _setZoom(carta),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStrategicButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: GestureDetector(
        onTap: _toggleExpandida,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1B2838).withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
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
}
