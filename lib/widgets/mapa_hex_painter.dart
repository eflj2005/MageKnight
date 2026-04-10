import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/hexagono.dart';
import '../models/heroe.dart';
import '../core/constants.dart';

/// CustomPainter que dibuja la cuadrícula hexagonal del mapa de Mage Knight.
class MapaHexPainter extends CustomPainter {
  /// Todas las celdas del mapa a dibujar
  final Map<String, Hexagono> celdas;

  /// Héroe actual (para dibujar su token)
  final Heroe? heroe;

  /// Hexágono seleccionado actualmente (puede ser null)
  final String? claveSeleccionada;

  /// Conjunto de claves "q,r" que representan posiciones donde se puede expandir
  final Set<String> posicionesFantasma;

  /// Función para validar si el héroe puede moverse a una celda (para resaltar)
  final bool Function(int q, int r)? puedeMoverseA;

  /// Tamaño del radio del hexágono en píxeles (centro a vértice)
  final double tamanoHex;

  /// Offset del canvas para centrar el mapa
  final Offset offset;

  /// Posición actual del arrastre (si está ocurriendo)
  final Offset? posicionArrastreHeroe;

  /// Indica si el héroe está siendo arrastrado por el usuario
  final bool estaArrastrando;

  /// [Fase 1H] Imagen PNG de la miniatura del héroe
  final ui.Image? heroeImage;

  /// [Fase 1F] Origen del arrastre para dibujar la estela
  final Offset? posicionOrigenArrastre;

  /// [Fase 1F] Posición donde ocurrió el último aterrizaje (onda de choque)
  final Offset? posicionAterrizaje;

  /// [Fase 1F] Progreso de la animación de onda de choque (0.0 a 1.0)
  final double progresoChoque;

  /// [Fase 4D] Costo de la ruta calculada actualmente durante el arrastre
  final int? costoArrastre;

  /// [Fase 4D] Indica si la trayectoria actual es válida para mostrar la 'X' si no
  final bool esRutaValida;

  MapaHexPainter({
    required this.celdas,
    this.heroe,
    required this.posicionesFantasma,
    this.puedeMoverseA,
    required this.tamanoHex,
    required this.offset,
    this.claveSeleccionada,
    this.posicionArrastreHeroe,
    this.estaArrastrando = false,
    this.heroeImage,
    this.posicionOrigenArrastre,
    this.posicionAterrizaje,
    this.progresoChoque = 0.0,
    this.costoArrastre,
    this.esRutaValida = true,
  });

  // -------------------------------------------------------------------------
  // Conversión de coordenadas axiales → píxeles (sistema flat-top)
  // -------------------------------------------------------------------------

  Offset axialAPixel(int q, int r) {
    final x = tamanoHex * (3 / 2 * q);
    final y = tamanoHex * (sqrt(3) / 2 * q + sqrt(3) * r);
    return Offset(x + offset.dx, y + offset.dy);
  }

  List<Offset> calcularVertices(Offset centro) {
    return List.generate(6, (i) {
      final angulo = (pi / 180) * (60 * i); 
      return Offset(
        centro.dx + tamanoHex * cos(angulo),
        centro.dy + tamanoHex * sin(angulo),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dibujar hexágonos colocados
    for (final hex in celdas.values) {
      final centro = axialAPixel(hex.q, hex.r);
      final esSeleccionado = hex.clave == claveSeleccionada;
      _dibujarHexagono(canvas, centro, hex, esSeleccionado);
    }

    // 2. [Fase 4D] El resaltado de movimiento por adyacencia se elimina 
    // por ser innecesario con la nueva mecánica de larga distancia.

    // 3. Dibujar hexágonos fantasma translúcidos
    for (final clave in posicionesFantasma) {
      final partes = clave.split(',');
      final q = int.parse(partes[0]);
      final r = int.parse(partes[1]);
      _dibujarFantasma(canvas, q, r);
    }

    // 4. Dibujar efectos de capa superior (Rastro y Onda de Choque)
    if (estaArrastrando && posicionArrastreHeroe != null) {
      if (posicionOrigenArrastre != null) {
        // [Fase 2A] Usar colorRastro del héroe para su estela mística única
        _dibujarRastro(canvas, posicionOrigenArrastre!, posicionArrastreHeroe!, heroe?.colorRastro ?? Colors.amber);
      }
      
      // [Fase M] Dibujar flechas de movimiento en 6 direcciones
      _dibujarFlechasArrastre(canvas, posicionArrastreHeroe!, heroe?.colorRastro ?? Colors.amber);

      // [Fase 4D] Dibujar indicador de costo o 'X' en el origen
      if (posicionOrigenArrastre != null) {
        _dibujarIndicadorCosto(canvas, posicionOrigenArrastre!);
      }
    }

    if (posicionAterrizaje != null && progresoChoque > 0 && progresoChoque < 1.0) {
      // [Fase 2A] La onda de impacto también hereda el colorRastro del héroe
      _dibujarOndaImpacto(canvas, posicionAterrizaje!, heroe?.colorRastro ?? Colors.amber, progresoChoque);
    }

    // 5. Dibujar al Héroe (capa superior)
    if (heroe != null) {
      final Offset posDibujo = estaArrastrando && posicionArrastreHeroe != null
          ? posicionArrastreHeroe!
          : axialAPixel(heroe!.q, heroe!.r);
      _dibujarMiniaturaHeroe(canvas, posDibujo, heroe!, estaArrastrando);
    }
  }

  void _dibujarHexagono(Canvas canvas, Offset centro, Hexagono hex, bool esSeleccionado) {
    final vertices = calcularVertices(centro);
    final path = Path()..addPolygon(vertices, true);

    // Fondo
    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..color = hex.esExplorado ? hex.color : const Color(0xFF1A1A2E);
    canvas.drawPath(path, paintFill);

    // Borde básico/fino
    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = hex.esBorde ? const Color(0xFF00E5FF).withValues(alpha: 0.5) : Colors.white10
      ..strokeWidth = 1.0;
    canvas.drawPath(path, paintStroke);

    // Borde grueso de loseta (sistema de 7 hexágonos)
    final direccionesAxiales = [
      (1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)
    ];
    for (int i = 0; i < 6; i++) {
      final p1 = vertices[i];
      final p2 = vertices[(i + 1) % 6];
      final nQ = hex.q + direccionesAxiales[i].$1;
      final nR = hex.r + direccionesAxiales[i].$2;
      final vecino = celdas['$nQ,$nR'];
      
      final esBordeLoseta = (vecino == null || vecino.idLoseta != hex.idLoseta);
      if (esBordeLoseta) {
        final bColor = esSeleccionado ? const Color(0xFFFFD700) : Colors.black;
        final bWidth = esSeleccionado ? 3.5 : 4.0;
        canvas.drawLine(p1, p2, Paint()..color=bColor..strokeWidth=bWidth..style=PaintingStyle.stroke);
        canvas.drawLine(p1, p2, Paint()..color=Colors.white12..strokeWidth=1.0..style=PaintingStyle.stroke);
      } else if (esSeleccionado) {
        canvas.drawLine(p1, p2, Paint()..color=const Color(0x88FFD700)..strokeWidth=1.5..style=PaintingStyle.stroke);
      }
    }

    // Contenido
    if (hex.esExplorado) {
      if (hex.iconoSitioStr != null) {
        final Offset posSitio = hex.iconoTerrenoStr.isEmpty 
            ? centro 
            : Offset(centro.dx + tamanoHex * 0.25, centro.dy);

        if (hex.iconoTerrenoStr.isEmpty) {
          _dibujarTexto(canvas, centro, hex.iconoSitioStr!, tamanoHex * 0.8);
        } else {
          _dibujarTexto(canvas, Offset(centro.dx - tamanoHex * 0.25, centro.dy), hex.iconoTerrenoStr, tamanoHex * 0.6);
          _dibujarTexto(canvas, posSitio, hex.iconoSitioStr!, tamanoHex * 0.6);
        }

        if (hex.colorMana != null) {
          _dibujarTexto(canvas, posSitio, obtenerLetraMana(hex.colorMana!), tamanoHex * 0.35, 
              color: obtenerColorMana(hex.colorMana!), fontWeight: FontWeight.bold, conBorde: true);
        }
      } else {
        _dibujarTexto(canvas, centro, hex.iconoTerrenoStr, tamanoHex * 0.75);
      }

      if (hex.esTransitable) {
        _dibujarTexto(canvas, Offset(centro.dx, centro.dy + tamanoHex * 0.65), hex.costo.toString(), 
            tamanoHex * 0.35, color: Colors.white70);
      }
    } else {
      _dibujarTexto(canvas, centro, '?', tamanoHex * 0.7, color: Colors.white30);
    }

    if (esSeleccionado) {
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
  }

  /// Dibuja una estela mística de luz entre el origen y el destino del arrastre.
  void _dibujarRastro(Canvas canvas, Offset origen, Offset destino, Color color) {
    final paintTrail = Paint()
      ..shader = ui.Gradient.linear(
        origen,
        destino,
        [color.withValues(alpha: 0.0), color.withValues(alpha: 0.5)],
      )
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(origen, destino, paintTrail);

    // Partículas de luz sutiles
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawLine(origen, destino, glowPaint);
  }

  /// Dibuja una onda expansiva de aterrizaje.
  void _dibujarOndaImpacto(Canvas canvas, Offset posicion, Color color, double progreso) {
    final double radioMax = tamanoHex * 2.0;
    final double radioActual = radioMax * progreso;
    final double opacidad = (1.0 - progreso).clamp(0.0, 1.0);

    final paintOnda = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * (1.0 - progreso)
      ..color = color.withValues(alpha: opacidad);

    canvas.drawCircle(posicion, radioActual, paintOnda);
    
    // Brillo central de impacto
    canvas.drawCircle(posicion, radioActual * 0.5, Paint()
      ..color = color.withValues(alpha: opacidad * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));
  }

  /// Dibuja flechas sólidas y brillantes en 6 direcciones para indicar movimiento.
  void _dibujarFlechasArrastre(Canvas canvas, Offset centro, Color colorBase) {
    // [Rescue 1N] Color cian vibrante por solicitud del usuario
    const Color colorCian = Color(0xFF00E5FF);
    
    final paintArrow = Paint()
      ..color = colorCian.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
      
    final paintGlow = Paint()
      ..color = colorCian.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    for (int i = 0; i < 6; i++) {
        // Direcciones axiales (30°, 90°, 150°, 210°, 270°, 330°)
        final double angulo = (pi / 180) * (60 * i + 30); 
        
        canvas.save();
        canvas.translate(centro.dx, centro.dy);
        canvas.rotate(angulo);
        
        final double distBase = tamanoHex * 0.9;
        final double largoFlecha = tamanoHex * 0.5;
        
        // Dibujo de flecha sólida tipo "PlayStation/Tactics"
        final Path path = Path()
          ..moveTo(distBase, -6)
          ..lineTo(distBase + largoFlecha * 0.7, -6)
          ..lineTo(distBase + largoFlecha * 0.7, -14)
          ..lineTo(distBase + largoFlecha, 0)
          ..lineTo(distBase + largoFlecha * 0.7, 14)
          ..lineTo(distBase + largoFlecha * 0.7, 6)
          ..lineTo(distBase, 6)
          ..close();
          
        canvas.drawPath(path, paintGlow);
        canvas.drawPath(path, paintArrow);
        canvas.restore();
    }
  }

  /// Dibuja una miniatura del héroe deluxe con base tipo pedestal y miniatura PNG.
  /// Dibuja al héroe deluxe focalizado solo en la miniatura PNG y sus efectos físicos.
  void _dibujarMiniaturaHeroe(Canvas canvas, Offset posicion, Heroe heroe, bool elevado) {
    // Aumentado para representar un ~75% del hexágono [Fase 1J]
    const double radioBaseDefault = 65.0;
    
    // Renderizado 'Senior' de la figura (Imagen + Sombra + Rim Light)
    _dibujarHeroeFisico(canvas, posicion, radioBaseDefault, heroe, elevado);
  }

  /// Renderiza el héroe utilizando la imagen de los assets con efectos que simulan una miniatura real.
  void _dibujarHeroeFisico(Canvas canvas, Offset posicion, double radioBase, Heroe heroe, bool elevado) {
    if (heroeImage == null) {
      // Fallback a silueta vectorial si la imagen no carga
      _dibujarSiluetaGuerrero(canvas, posicion, radioBase, heroe.color, elevado);
      return;
    }

    final double escala = elevado ? 1.296 : 1.2; // [Refinado v1.5.1] Escalado exacto +8% al alzar
    final Offset offsetElevacion = Offset(0, elevado ? -15 : 0); // Mayor elevación visual
    final Offset centroFigura = posicion + offsetElevacion;
    final double size = radioBase * escala;

    // 1. Sombra Proyectada (Ground Shadow) — Da sensación de despegarse del suelo
    final paintSombra = Paint()
      ..color = Colors.black.withValues(alpha: elevado ? 0.2 : 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevado ? 12 : 4);
    canvas.drawOval(
      Rect.fromCenter(center: posicion + Offset(elevado ? 10 : 4, elevado ? 10 : 4), width: radioBase * 1.2, height: radioBase * 0.4),
      paintSombra,
    );

    // 2. Brillo de Contorno (Rim Light / Light Wrap) — Separa la miniatura del fondo
    final paintRim = Paint()
      ..color = heroe.color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(centroFigura, radioBase * 0.75, paintRim);

    // 3. Renderizado de la Imagen con Calidad Alta
    final Rect destRect = Rect.fromCenter(center: centroFigura, width: size, height: size);
    
    // Dibujo principal de la imagen
    canvas.drawImageRect(
      heroeImage!,
      Rect.fromLTWH(0, 0, heroeImage!.width.toDouble(), heroeImage!.height.toDouble()),
      destRect,
      Paint()..filterQuality = ui.FilterQuality.high,
    );

    // 4. Brillo 'Glossy' de Plástico (Procedural)
    // Añadimos un pequeño reflejo blanco en la parte superior para simular material físico
    final Path glossPath = Path()
      ..moveTo(centroFigura.dx - size * 0.2, centroFigura.dy - size * 0.4)
      ..quadraticBezierTo(centroFigura.dx, centroFigura.dy - size * 0.45, centroFigura.dx + size * 0.2, centroFigura.dy - size * 0.35)
      ..lineTo(centroFigura.dx + size * 0.15, centroFigura.dy - size * 0.3)
      ..quadraticBezierTo(centroFigura.dx, centroFigura.dy - size * 0.35, centroFigura.dx - size * 0.15, centroFigura.dy - size * 0.3)
      ..close();
    
    canvas.drawPath(glossPath, Paint()..color = Colors.white.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // 5. Aura de poder si está elevado
    if (elevado) {
      canvas.drawCircle(centroFigura, radioBase * 0.6, Paint()
        ..color = heroe.color.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    }
  }

  /// Conservado como fallback [Fase 1F/G]
  void _dibujarSiluetaGuerrero(Canvas canvas, Offset posicion, double radioBase, Color color, bool elevado) {
    final double escala = elevado ? 1.05 : 0.9;
    final Offset offsetElevacion = Offset(0, elevado ? -7 : 0);
    final Offset centroFigura = posicion + offsetElevacion;

    // 1. Sombra de contacto (Drip Shadow) — Ancla la figura al pedestal
    final paintContactSombra = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(Rect.fromCenter(center: posicion, width: radioBase * 0.8, height: radioBase * 0.3), paintContactSombra);

    // 2. Path General del Guerrero (Pose de Reposo: Espada al suelo)
    final Path pathCuerpo = _generarPathGuerrero(centroFigura, radioBase * escala);
    final Rect bounds = pathCuerpo.getBounds();
    
    // 3. Capa Base (Volumen y Oclusión)
    final paintBase = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(color, Colors.white, 0.2)!, // Luz cenital
          color,
          Color.lerp(color, Colors.black, 0.7)!, // Sombra de base
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds);
    canvas.drawPath(pathCuerpo, paintBase);

    // 4. Capa de Biselado (Rim Light / Perfilado de Plástico)
    final paintRim = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5);
    canvas.drawPath(pathCuerpo, paintRim);

    // 5. Brillos Especulares (Puntos de luz dura en metal/casco)
    final Paint paintSpecular = Paint()..color = Colors.white.withAlpha(200);
    // Brillo en el casco
    canvas.drawCircle(centroFigura - Offset(radioBase * 0.1, radioBase * 1.35), 2, paintSpecular);
    // Brillo en el pomo de la espada
    canvas.drawCircle(centroFigura + Offset(radioBase * 0.45, -radioBase * 0.2), 1.5, paintSpecular);

    // 6. Aura espectral (si está elevado)
    if (elevado) {
      canvas.drawPath(pathCuerpo, Paint()
        ..color = color.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    }
  }

  /// Genera un Path de caballero en pose de reposo (Espada apoyada).
  Path _generarPathGuerrero(Offset centro, double radio) {
    final Path path = Path();
    final double r = radio;
    
    // --- Cabeza y Casco (Frontal) ---
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: centro - Offset(0, r * 1.3), width: r * 0.45, height: r * 0.5),
      const Radius.circular(6),
    ));
    
    // --- Cuerpo Principal (Torso Robusto) ---
    path.moveTo(centro.dx - r * 0.4, centro.dy - r * 1.1);
    path.lineTo(centro.dx + r * 0.4, centro.dy - r * 1.1);
    path.lineTo(centro.dx + r * 0.3, centro.dy + r * 0.8);
    path.lineTo(centro.dx - r * 0.3, centro.dy + r * 0.8);
    path.close();

    // --- Capa que envuelve el cuerpo ---
    path.moveTo(centro.dx - r * 0.4, centro.dy - r * 1.1);
    path.quadraticBezierTo(centro.dx - r * 0.8, centro.dy, centro.dx - r * 0.5, centro.dy + r * 0.9);
    path.lineTo(centro.dx + r * 0.5, centro.dy + r * 0.9);
    path.quadraticBezierTo(centro.dx + r * 0.8, centro.dy, centro.dx + r * 0.4, centro.dy - r * 1.1);
    path.close();

    // --- Espada de Reposo (Vertical, apoyada en el suelo) ---
    // Hoja
    path.addRect(Rect.fromLTWH(centro.dx + r * 0.4, centro.dy - r * 0.2, r * 0.1, r * 1.1));
    // Guarda (Cruz)
    path.addRect(Rect.fromCenter(center: centro + Offset(r * 0.45, -r * 0.25), width: r * 0.35, height: r * 0.08));
    // Pomo
    path.addOval(Rect.fromCenter(center: centro + Offset(r * 0.45, -r * 0.4), width: r * 0.15, height: r * 0.15));

    // --- Escudo de Lado (Descansando en el brazo izq) ---
    path.moveTo(centro.dx - r * 0.35, centro.dy - r * 0.2);
    path.lineTo(centro.dx - r * 0.65, centro.dy + r * 0.1);
    path.lineTo(centro.dx - r * 0.5, centro.dy + r * 0.8);
    path.lineTo(centro.dx - r * 0.35, centro.dy + r * 0.7);
    path.close();

    return path;
  }


  /// Dibuja el indicador de costo (PM) o una 'X' de error en el origen del arrastre [Fase 4D]
  void _dibujarIndicadorCosto(Canvas canvas, Offset centro) {
    if (!esRutaValida && costoArrastre == null && !estaArrastrando) return;

    // Escala reducida para un HUD más minimalista [v4D.2]
    final double iconSize = tamanoHex * 0.45;
    final double textSize = tamanoHex * 0.38; 
    final Color colorPrincipal = esRutaValida ? AppColors.dorado : Colors.redAccent;

    // 1. Preparar el Icono (directions_run)
    const iconData = Icons.directions_run;
    final TextPainter iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: colorPrincipal,
        shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
      ),
    );
    iconPainter.layout();

    // 2. Preparar el Texto (Número o X)
    final String label = esRutaValida ? (costoArrastre?.toString() ?? '0') : '✕';
    final TextPainter labelPainter = TextPainter(textDirection: TextDirection.ltr);
    labelPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: textSize,
        color: esRutaValida ? Colors.white : Colors.redAccent,
        fontWeight: FontWeight.bold,
        shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
      ),
    );
    labelPainter.layout();

    // 3. Dibujar Marco CIRCULAR
    final double radioCirculo = tamanoHex * 0.55;
    
    // Fondo más traslúcido (0.35 opacidad)
    canvas.drawCircle(
      centro,
      radioCirculo,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35) 
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    
    canvas.drawCircle(
      centro,
      radioCirculo,
      Paint()
        ..color = colorPrincipal.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 4. Pintar Icono y Etiqueta (Fijados verticalmente para evitar saltos)
    final double spacing = 1.0;
    final double totalContentHeight = iconSize + textSize + spacing;
    final double yIcon = centro.dy - (totalContentHeight / 2);
    final double yLabel = yIcon + iconSize + spacing;

    iconPainter.paint(canvas, Offset(centro.dx - iconPainter.width / 2, yIcon));
    labelPainter.paint(canvas, Offset(centro.dx - labelPainter.width / 2, yLabel));
  }

  void _dibujarFantasma(Canvas canvas, int q, int r) {
    final centro = axialAPixel(q, r);
    final vertices = calcularVertices(centro);
    final path = Path()..addPolygon(vertices, true);

    canvas.drawPath(path, Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.1));
    canvas.drawPath(path, Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0);
    _dibujarTexto(canvas, centro, '+', tamanoHex * 0.5, color: const Color(0xFF00E5FF).withValues(alpha: 0.8));
  }

  void _dibujarTexto(Canvas canvas, Offset posicion, String texto, double fontSize, {
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.normal,
    bool conBorde = false,
  }) {
    if (conBorde) {
      final tpBorde = TextPainter(
        text: TextSpan(text: texto, style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, 
            foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=3..color=Colors.black)),
        textDirection: TextDirection.ltr)..layout();
      tpBorde.paint(canvas, posicion - Offset(tpBorde.width/2, tpBorde.height/2));
    }

    final tp = TextPainter(
      text: TextSpan(text: texto, style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight, 
          shadows: conBorde ? [] : [const Shadow(color: Colors.black, blurRadius: 4)])),
      textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, posicion - Offset(tp.width/2, tp.height/2));
  }

  @override
  bool shouldRepaint(MapaHexPainter oldDelegate) {
    // [Optimización de Rendimiento] Evitar redibujos masivos.
    // Solo repintar si alguna de las propiedades que afectan la visualización cambia gráficamente.
    return oldDelegate.celdas != celdas ||
           oldDelegate.heroe != heroe ||
           oldDelegate.claveSeleccionada != claveSeleccionada ||
           oldDelegate.posicionArrastreHeroe != posicionArrastreHeroe ||
           oldDelegate.estaArrastrando != estaArrastrando ||
           oldDelegate.posicionOrigenArrastre != posicionOrigenArrastre ||
           oldDelegate.posicionAterrizaje != posicionAterrizaje ||
           oldDelegate.progresoChoque != progresoChoque ||
           oldDelegate.heroeImage != heroeImage ||
           oldDelegate.offset != offset ||
           oldDelegate.costoArrastre != costoArrastre ||
           oldDelegate.esRutaValida != esRutaValida;
  }

  // -------------------------------------------------------------------------
  // Hit testing — identificar qué hexágono tocó el usuario
  // -------------------------------------------------------------------------

  (int, int)? pixelAAxial(Offset posicion) {
    final x = posicion.dx - offset.dx;
    final y = posicion.dy - offset.dy;
    final q = (2.0 / 3.0 * x) / tamanoHex;
    final r = (-1.0 / 3.0 * x + sqrt(3) / 3.0 * y) / tamanoHex;
    return _redondearHex(q, r);
  }

  (int, int) _redondearHex(double q, double r) {
    final s = -q - r;
    var rq = q.round();
    var rr = r.round();
    var rs = s.round();
    final dq = (rq - q).abs();
    final dr = (rr - r).abs();
    final ds = (rs - s).abs();
    if (dq > dr && dq > ds) {
      rq = -rr - rs;
    } else if (dr > ds) {
      rr = -rq - rs;
    }
    return (rq, rr);
  }
}
