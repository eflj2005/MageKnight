import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/carta.dart';

class WidgetCarta extends StatelessWidget {
  final Carta carta;
  /// Si es true, la carta es una réplica exacta a escala (aprox 60x90)
  final bool compacta;
  final VoidCallback? onTap;

  const WidgetCarta({
    super.key, 
    required this.carta, 
    this.compacta = false,
    this.onTap,
  });

  String _getManaEmoji(ColorMana? tipo) {
    switch (tipo) {
      case ColorMana.azul: return '💧';
      case ColorMana.rojo: return '🔥';
      case ColorMana.verde: return '🌿';
      case ColorMana.blanco: return '☀️';
      case ColorMana.dorado: return '✨';
      case ColorMana.negro: return '🌑';
      default: return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color acentoCard = carta.colorBase?.colorVisual ?? Colors.grey;

    final double targetWidth = compacta ? 60 : 160;
    final double targetHeight = compacta ? 90 : 240;

    Widget contenido = Container(
      width: targetWidth,
      height: targetHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(compacta ? 6 : 12),
        border: Border.all(
          color: acentoCard.withOpacity(compacta ? 0.3 : 0.8),
          width: compacta ? 0.6 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: compacta ? 4 : 12,
            offset: Offset(0, compacta ? 1 : 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compacta ? 5 : 10),
        child: Stack(
          children: [
            // Marca de agua centralizada (reducida si hay arte)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Center(
                  child: Text(
                    _getManaEmoji(carta.colorBase),
                    style: TextStyle(fontSize: compacta ? 40 : 100),
                  ),
                ),
              ),
            ),

            // Contenido de la Carta (Escalado en modo compacto para fidelidad total)
            compacta 
              ? FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: 160,
                    height: 240,
                    child: _buildFullLayout(acentoCard),
                  ),
                )
              : _buildFullLayout(acentoCard),
            
            // Número de Carta
            if (carta.numeroCarta != null)
              Positioned(
                bottom: compacta ? 2 : 4,
                right: compacta ? 2 : 4,
                child: Text(
                  '#${carta.numeroCarta}',
                  style: GoogleFonts.marcellus(
                    color: Colors.white24,
                    fontSize: compacta ? 6 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: contenido,
      );
    }
    return contenido;
  }

  /// Construye el layout completo de la carta corrigiendo espacio para el Arte
  Widget _buildFullLayout(Color acentoCard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Cabecera (Nombre)
        _buildHeader(acentoCard),
        
        // 2. Área de Arte
        _buildArtArea(acentoCard),

        // 3. Cuerpo con textos y separador
        Expanded(
          child: _buildBody(acentoCard),
        ),

        // 4. Pie de carta
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader(Color acentoCard) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      decoration: BoxDecoration(
        color: acentoCard.withOpacity(0.15),
        border: Border(bottom: BorderSide(color: acentoCard.withOpacity(0.3))),
      ),
      child: Text(
        carta.nombre,
        style: GoogleFonts.marcellus(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Sección dedicada a la ilustración de la carta
  Widget _buildArtArea(Color acentoCard) {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: acentoCard.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder temático
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    acentoCard.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Carga de Imagen Real (Asignada en Catalogo)
            if (carta.imagenNombre != null)
              Image.asset(
                'assets/images/cards/${carta.imagenNombre}.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: acentoCard.withOpacity(0.2),
                      size: 32,
                    ),
                  );
                },
              )
            else
              Center(
                child: Icon(
                  Icons.auto_awesome_motion,
                  color: acentoCard.withOpacity(0.15),
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color acentoCard) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (carta.iconosPuntos.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: carta.iconosPuntos.map((icono) => Text(
                icono, 
                style: const TextStyle(fontSize: 11)
              )).toList(),
            ),

          Text(
            carta.textoBasico,
            textAlign: TextAlign.center,
            style: GoogleFonts.marcellus(
              color: Colors.white70, 
              fontSize: 10,
              height: 1.1 
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          _buildSeparator(acentoCard),

          Text(
            carta.textoPotenciado,
            textAlign: TextAlign.center,
            style: GoogleFonts.marcellus(
              color: acentoCard.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.1
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator(Color acentoCard) {
    return Row(
      children: [
        Expanded(child: Divider(color: acentoCard.withOpacity(0.2), thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(_getManaEmoji(carta.colorBase), style: const TextStyle(fontSize: 10)),
        ),
        Expanded(child: Divider(color: acentoCard.withOpacity(0.2), thickness: 0.5)),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      color: Colors.black.withOpacity(0.4),
      child: Text(
        carta.tipo.name.toUpperCase(),
        textAlign: TextAlign.center,
        style: GoogleFonts.marcellus(
          color: Colors.white24,
          fontSize: 8,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
