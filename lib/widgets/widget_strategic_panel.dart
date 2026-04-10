import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sesion_juego.dart';
import '../models/mazo_heroe.dart';
import '../models/carta.dart';
import 'widget_carta.dart';

/// Clase auxiliar para rastrear cartas en el área de juego
class CartaEnTrabajo {
  final Carta carta;
  bool girada;

  CartaEnTrabajo({required this.carta, this.girada = false});
}

/// Estructura para el visor de Zoom que incluye estado de rotación
class InfoZoom {
  final Carta carta;
  final bool girada;
  const InfoZoom({required this.carta, this.girada = false});
}

class WidgetStrategicPanel extends StatefulWidget {
  final SesionJuego sesion;
  final VoidCallback onClose;

  const WidgetStrategicPanel({
    super.key,
    required this.sesion,
    required this.onClose,
  });

  @override
  State<WidgetStrategicPanel> createState() => _WidgetStrategicPanelState();
}

class _WidgetStrategicPanelState extends State<WidgetStrategicPanel> {
  InfoZoom? _zoomInfo;
  final List<CartaEnTrabajo> _areaTrabajo = [];

  void _seleccionarCarta(Carta carta, {bool girada = false}) {
    setState(() {
      _zoomInfo = InfoZoom(carta: carta, girada: girada);
    });
  }

  void _moverAlAreaTrabajo(Carta carta) {
    if (!_areaTrabajo.any((c) => c.carta.idInterno == carta.idInterno)) {
      setState(() {
        _areaTrabajo.add(CartaEnTrabajo(carta: carta));
      });
    }
  }

  void _removerDelAreaTrabajo(int index) {
    setState(() {
      _areaTrabajo.removeAt(index);
    });
  }

  void _toggleGiroCarta(int index) {
    setState(() {
      _areaTrabajo[index].girada = !_areaTrabajo[index].girada;
      // Sincronizar zoom si es la misma carta
      if (_zoomInfo?.carta.idInterno == _areaTrabajo[index].carta.idInterno) {
        _zoomInfo = InfoZoom(carta: _areaTrabajo[index].carta, girada: _areaTrabajo[index].girada);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sesion.mazoHeroe,
      builder: (context, _) {
        final mazoHeroe = widget.sesion.mazoHeroe;
        final mano = mazoHeroe.mano;

        return Stack(
          children: [
            // Fondo Oscurecido interactivo para cerrar
            GestureDetector(
              onTap: widget.onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),

            // Modal Central con Animación de Entrada
            Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, val, child) {
                  return Transform.scale(
                    scale: 0.8 + (val * 0.2), 
                    child: Opacity(
                      opacity: val.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  height: MediaQuery.of(context).size.height * 0.92,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161621),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3), 
                      width: 2
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8), 
                        blurRadius: 30, 
                        spreadRadius: 5
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cabecera del Panel
                        _buildHeader(mazoHeroe),

                        // Cuerpo Principal (3 Zonas funcionales)
                        Expanded(child: _buildMainBody(mano)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(MazoHeroe mazoHeroe) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF12002B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_moon, color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 8),
              Text(
                'CENTRO ESTRATÉGICO',
                style: GoogleFonts.cinzel(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          
          Row(
            children: [
              _buildTextCounter('Descartadas', mazoHeroe.descarte.length),
              const SizedBox(width: 16),
              _buildTextCounter('Restantes', mazoHeroe.mazo.length),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextCounter(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: GoogleFonts.marcellus(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: GoogleFonts.firaCode(
            color: const Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMainBody(List<Carta> mano) {
    return Row(
      children: [
        // Columna Izquierda (Carrusel + Área de Trabajo)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildHandCarousel(mano),
              Expanded(child: _buildWorkArea()),
            ],
          ),
        ),

        // Separador vertical
        Container(width: 1, color: Colors.white.withValues(alpha: 0.1)),

        // Columna Derecha (Visor Zoom)
        _buildZoomPanel(),
      ],
    );
  }

  Widget _buildHandCarousel(List<Carta> mano) {
    return Container(
      height: 125,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: mano.length,
        itemBuilder: (context, index) {
          final carta = mano[index];
          final enTrabajo = _areaTrabajo.any((c) => c.carta.idInterno == carta.idInterno);
          final esSeleccionada = _zoomInfo?.carta.idInterno == carta.idInterno;

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Center(
              child: Draggable<Carta>(
                data: carta,
                maxSimultaneousDrags: enTrabajo ? 0 : 1,
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.8, 
                    child: WidgetCarta(carta: carta, compacta: true)
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.2, 
                  child: WidgetCarta(carta: carta, compacta: true)
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: esSeleccionada ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        blurRadius: 10,
                        spreadRadius: 2
                      )
                    ] : null,
                  ),
                  child: Opacity(
                    opacity: enTrabajo ? 0.3 : 1.0,
                    child: WidgetCarta(
                      carta: carta,
                      compacta: true,
                      onTap: () => _seleccionarCarta(carta, girada: false),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWorkArea() {
    return DragTarget<Carta>(
      onAcceptWithDetails: (details) {
        _moverAlAreaTrabajo(details.data);
        _seleccionarCarta(details.data, girada: false);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF2A2A3E),
                const Color(0xFF161621),
              ],
              center: Alignment.center,
              radius: 1.2,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: candidateData.isNotEmpty 
                ? const Color(0xFFFFD700) 
                : Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: _areaTrabajo.isEmpty
              ? _buildEmptyWorkArea()
              : _buildPopulatedWorkArea(),
        );
      },
    );
  }

  Widget _buildEmptyWorkArea() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style_outlined, color: Colors.white10, size: 42),
            const SizedBox(height: 8),
            Text(
              'ÁREA TÁCTICA',
              style: GoogleFonts.cinzel(color: Colors.white24, fontSize: 13, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulatedWorkArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _areaTrabajo.asMap().entries.map((entry) {
          int idx = entry.key;
          CartaEnTrabajo ct = entry.value;
          final esSeleccionada = _zoomInfo?.carta.idInterno == ct.carta.idInterno;
          
          return GestureDetector(
            onTap: () {
              _seleccionarCarta(ct.carta, girada: ct.girada);
              _toggleGiroCarta(idx);
            },
            onLongPress: () {
              _removerDelAreaTrabajo(idx);
              if (_zoomInfo?.carta.idInterno == ct.carta.idInterno) {
                setState(() => _zoomInfo = null);
              }
            },
            child: AnimatedRotation(
              turns: ct.girada ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutBack,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: esSeleccionada ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 3
                    )
                  ] : null,
                ),
                child: WidgetCarta(carta: ct.carta, compacta: true),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildZoomPanel() {
    return Expanded(
      flex: 1,
      child: Container(
        color: Colors.black.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: _zoomInfo == null
                    ? _buildZoomPlaceholder()
                    : _buildZoomViewer(_zoomInfo!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomPlaceholder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.zoom_in, color: Colors.white.withValues(alpha: 0.05), size: 64),
        const SizedBox(height: 12),
        Text(
          'Inspecionar...',
          textAlign: TextAlign.center,
          style: GoogleFonts.marcellus(color: Colors.white10, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildZoomViewer(InfoZoom info) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(info.carta.idInterno + (info.carta.numeroCarta ?? '') + (info.girada ? '_g' : '_n')),
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.9, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale * 1.25,
          child: child,
        );
      },
      child: WidgetCarta(carta: info.carta),
    );
  }
}
