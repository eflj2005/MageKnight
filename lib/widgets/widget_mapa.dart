import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/hexagono.dart';
import '../models/heroe.dart';
import 'mapa_hex_painter.dart';

/// Widget interactivo del mapa hexagonal.
///
/// Combina [InteractiveViewer] (zoom/pan) con [GestureDetector] (tap)
/// para permitir explorar el mapa y seleccionar o expandir hexágonos.
///
/// Expone callbacks:
///   [onHexSeleccionado] — cuando el usuario toca un hex explorado
///   [onExpandir]        — cuando el usuario toca un hex de borde
class WidgetMapa extends StatefulWidget {
  /// Celdas del mapa (clave "q,r" → Hexágono)
  final Map<String, Hexagono> celdas;

  /// Posiciones donde se sugiere expandir (fantasmas)
  final Set<String> posicionesFantasma;

  /// Héroe actual para dibujar su token
  final Heroe? heroe;

  /// Función para validar si el héroe puede moverse a una celda (para resaltar)
  final bool Function(int q, int r)? puedeMoverseA;

  /// Callback cuando se selecciona un hexágono normal
  final void Function(Hexagono hex)? onHexSeleccionado;

  /// Callback cuando se toca un hexágono fantasma de borde (expandir mapa)
  final void Function(int q, int r)? onExpandir;

  /// Callback cuando se suelta al héroe en un nuevo destino (Drag & Drop)
  final void Function(int q, int r)? onHeroeMovido;

  /// Callback para obtener el costo de una ruta entre dos puntos [Fase 4D]
  final int Function(int q1, int r1, int q2, int r2)? obtenerCostoRuta;

  /// Callback cuando se toca espacio vacío (deseleccionar)
  final VoidCallback? onTapVacio;

  /// Tamaño del radio del hexágono en pantalla
  final double tamanoHex;

  const WidgetMapa({
    super.key,
    required this.celdas,
    this.heroe,
    this.puedeMoverseA,
    this.obtenerCostoRuta,
    required this.posicionesFantasma,
    this.onHexSeleccionado,
    this.onExpandir,
    this.onHeroeMovido,
    this.onTapVacio,
    this.tamanoHex = 52.0,
  });

  @override
  State<WidgetMapa> createState() => WidgetMapaState();
}

class WidgetMapaState extends State<WidgetMapa> with TickerProviderStateMixin {
  /// [Fase 1H] Imagen PNG de la miniatura del héroe
  ui.Image? _heroeImage;

  /// Clave del hex actualmente seleccionado
  String? _claveSeleccionada;

  /// Estado del arrastre del héroe
  Offset? _posicionArrastreHeroe;
  bool _estaArrastrandoHeroe = false;

  /// Origen del arrastre para la estela [Fase 1E]
  Offset? _posicionOrigenArrastre;

  /// Posición para la onda de choque (aterrizaje) [Fase 1E]
  Offset? _posicionAterrizaje;

  /// Controlador para la animación de onda de choque [Fase 1E]
  late AnimationController _shockwaveController;

  /// [Fase 4D] Estado del indicador de costo durante el arrastre
  int? _costoArrastreActual;
  bool _esRutaValidaActual = true;
  String? _ultimaClaveBajoCursor;

  /// Posición inicial del foco antes de escalar/panear (se actualiza constantemente)
  late Offset _posicionInicialFoco;

  /// Último factor de escala registrado durante el gesto actual (para zoom lineal)
  double _ultimoScale = 1.0;

  /// Controlador del InteractiveViewer para zoom/pan
  final TransformationController _transformController =
      TransformationController();

  /// [Fix Centrado] Clave para medir el área real del mapa (excluye AppBar, paneles)
  final GlobalKey _mapaRenderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarImagenHeroe();
    
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() => setState(() {}));

    // [Fix Centrado Definitivo] Usar el tamaño real del área del mapa, no MediaQuery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Salto instantáneo con el tamaño real medido del widget
      recentrarMapa();
      // Ajuste de precisión tras 400ms (imagen asincrónica puede haber asentado el layout)
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) recentrarMapa();
      });
    });
  }

  @override
  void didUpdateWidget(covariant WidgetMapa oldWidget) {
    super.didUpdateWidget(oldWidget);
    // [Fase 2A] Si el héroe cambió de archivo de sprite, recargar la imagen en caliente
    final nuevoNombre = widget.heroe?.imageName;
    final anteriorNombre = oldWidget.heroe?.imageName;
    if (nuevoNombre != null && nuevoNombre != anteriorNombre) {
      _cargarImagenHeroe(imageName: nuevoNombre);
    }
  }

  /// Carga asíncrona de la imagen del héroe desde los assets.
  /// Acepta el [imageName] del héroe activo para actualizar en tiempo real [Fase 2A]
  Future<void> _cargarImagenHeroe({String? imageName}) async {
    // Usar el asset del héroe activo o el default
    final nombreArchivo = imageName ?? widget.heroe?.imageName ?? 'heroe1';
    try {
      final data = await DefaultAssetBundle.of(context).load('assets/images/$nombreArchivo.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _heroeImage = frame.image;
        });
      }
    } catch (e) {
      debugPrint('Error cargando imagen del héroe ($nombreArchivo): $e');
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    _shockwaveController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Manejo de taps
  // -------------------------------------------------------------------------

  void _alTocarVenta(Offset posicionLocal, Offset offsetCentro) {
    final painter = _crearPainter(offsetCentro);
    final coords = painter.pixelAAxial(posicionLocal);
    
    if (coords == null) {
      widget.onTapVacio?.call();
      return;
    }

    final clave = '${coords.$1},${coords.$2}';
    if (widget.posicionesFantasma.contains(clave)) {
      widget.onExpandir?.call(coords.$1, coords.$2);
      return;
    }

    final hex = widget.celdas[clave];
    if (hex == null) {
      widget.onTapVacio?.call();
      return;
    }

    setState(() => _claveSeleccionada = clave);
    widget.onHexSeleccionado?.call(hex);
  }

  MapaHexPainter _crearPainter(Offset offsetCentro) {
    return MapaHexPainter(
      celdas: widget.celdas,
      heroe: widget.heroe,
      posicionesFantasma: widget.posicionesFantasma,
      puedeMoverseA: widget.puedeMoverseA,
      tamanoHex: widget.tamanoHex,
      offset: offsetCentro,
      claveSeleccionada: _claveSeleccionada,
      posicionArrastreHeroe: _posicionArrastreHeroe,
      estaArrastrando: _estaArrastrandoHeroe,
      heroeImage: _heroeImage, // [Fase 1H]
      posicionOrigenArrastre: _posicionOrigenArrastre,
      posicionAterrizaje: _posicionAterrizaje,
      progresoChoque: _shockwaveController.value,
      costoArrastre: _costoArrastreActual,
      esRutaValida: _esRutaValidaActual,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double mapSize = 10000.0;
        const offsetCentro = Offset(mapSize / 2, mapSize / 2);

        return ClipRect(
          key: _mapaRenderKey, // [Fix Centrado] Clave para medir área real
          child: InteractiveViewer(
            transformationController: _transformController,
            constrained: false, 
            panEnabled: false, 
            scaleEnabled: true,
            minScale: 0.1,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(600.0),
            child: GestureDetector(
              // --- Lógica del Héroe (Nativa de Flutter para retención precisa) ---
              onLongPressStart: (LongPressStartDetails details) {
                if (widget.heroe != null) {
                  final painter = _crearPainter(offsetCentro);
                  final centroHeroe = painter.axialAPixel(widget.heroe!.q, widget.heroe!.r);
                  final distancia = (details.localPosition - centroHeroe).distance;

                  if (distancia < widget.tamanoHex * 1.5) {
                    setState(() {
                      _estaArrastrandoHeroe = true;
                      _posicionArrastreHeroe = details.localPosition;
                      _posicionOrigenArrastre = centroHeroe;
                      _posicionAterrizaje = null;
                    });
                  }
                }
              },
              onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
                if (_estaArrastrandoHeroe) {
                  setState(() {
                    _posicionArrastreHeroe = details.localPosition;
                  });

                  // [Fase 4D] Calcular costo en tiempo real si ha cambiado el hexágono bajo el cursor
                  final painter = _crearPainter(offsetCentro);
                  final coords = painter.pixelAAxial(details.localPosition);
                  if (coords != null) {
                    final clave = '${coords.$1},${coords.$2}';
                    if (clave != _ultimaClaveBajoCursor) {
                      _ultimaClaveBajoCursor = clave;
                      
                      if (widget.heroe != null && widget.obtenerCostoRuta != null) {
                        final costo = widget.obtenerCostoRuta!(
                          widget.heroe!.q, widget.heroe!.r, coords.$1, coords.$2
                        );
                        
                        setState(() {
                          if (costo > 900) {
                            _costoArrastreActual = null;
                            _esRutaValidaActual = false;
                          } else {
                            _costoArrastreActual = costo;
                            _esRutaValidaActual = true;
                          }
                        });
                      }
                    }
                  } else {
                    if (_esRutaValidaActual || _costoArrastreActual != null) {
                      setState(() {
                        _esRutaValidaActual = false;
                        _costoArrastreActual = null;
                        _ultimaClaveBajoCursor = null;
                      });
                    }
                  }
                }
              },
              onLongPressEnd: (LongPressEndDetails details) {
                if (_estaArrastrandoHeroe) {
                  final painter = _crearPainter(offsetCentro);
                  final coords = painter.pixelAAxial(_posicionArrastreHeroe!);
                  
                  if (coords != null) {
                    widget.onHeroeMovido?.call(coords.$1, coords.$2);
                    _posicionAterrizaje = _posicionArrastreHeroe;
                    _shockwaveController.forward(from: 0.0);
                  }

                  setState(() {
                    _estaArrastrandoHeroe = false;
                    _posicionArrastreHeroe = null;
                    _posicionOrigenArrastre = null;
                    _costoArrastreActual = null; // [Fase 4D] Resetear indicador
                    _esRutaValidaActual = true;
                    _ultimaClaveBajoCursor = null;
                  });
                }
              },

              // --- Lógica de Mapa (Zoom y Paneo a 1 o 2 dedos) ---
              onScaleStart: (ScaleStartDetails details) {
                _posicionInicialFoco = details.localFocalPoint;
                _ultimoScale = 1.0;
              },
              onScaleUpdate: (ScaleUpdateDetails details) {
                if (_estaArrastrandoHeroe) return; // Ignorar pan si se arrastra figura

                final Offset delta = details.localFocalPoint - _posicionInicialFoco;
                _posicionInicialFoco = details.localFocalPoint;

                final Matrix4 matrix = _transformController.value.clone();
                matrix.translateByDouble(delta.dx, delta.dy, 0.0, 1.0);

                if (details.scale != 1.0) {
                  final double deltaScale = details.scale / _ultimoScale;
                  _ultimoScale = details.scale;
                  final Offset focalPoint = details.localFocalPoint;
                  final Matrix4 scaleMatrix = Matrix4.identity()
                    ..translateByDouble(focalPoint.dx, focalPoint.dy, 0.0, 1.0)
                    ..scaleByDouble(deltaScale, deltaScale, 1.0, 1.0)
                    ..translateByDouble(-focalPoint.dx, -focalPoint.dy, 0.0, 1.0);
                  matrix.multiply(scaleMatrix);
                }
                _transformController.value = matrix;
              },
              onScaleEnd: (ScaleEndDetails details) {
                 // No action needed
              },
              onTapUp: (TapUpDetails details) {
                if (!_estaArrastrandoHeroe) {
                  _alTocarVenta(details.localPosition, offsetCentro);
                }
              },
              child: Container(
                width: mapSize,
                height: mapSize,
                color: Colors.transparent, 
                child: CustomPaint(
                  painter: _crearPainter(offsetCentro),
                  size: const Size(mapSize, mapSize),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Recentra la cámara para que todo el mapa o un hexágono específico sea visible [Fase 1M]
  void recentrarMapa({Size? mainSize, bool animado = true, int? targetQ, int? targetR}) {
    // [Fix] Si no recibimos el tamaño, lo intentamos obtener del área real del widget
    Size? effectiveSize = mainSize;
    if (effectiveSize == null) {
      final RenderBox? renderBox = _mapaRenderKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        effectiveSize = renderBox.size;
      }
    }

    if (widget.celdas.isEmpty || effectiveSize == null || effectiveSize.width == 0) return;

    // [Fase 1L] Limpieza de selección según requerimiento del usuario
    setState(() => _claveSeleccionada = null);

    final painter = _crearPainter(const Offset(5000, 5000));
    
    double centerX, centerY, targetScale;

    if (targetQ != null && targetR != null) {
      // [Fase 1M] Modo Enfoque en Héroe/Celda específica
      final pos = painter.axialAPixel(targetQ, targetR);
      centerX = pos.dx;
      centerY = pos.dy;
      targetScale = 1.0; // Zoom de detalle para la loseta actual
    } else {
      // [Fase 1L] Modo Enfoque Global (Bounding Box)
      double minX = double.infinity, maxX = double.negativeInfinity;
      double minY = double.infinity, maxY = double.negativeInfinity;

      for (var hex in widget.celdas.values) {
        final pos = painter.axialAPixel(hex.q, hex.r);
        if (pos.dx - widget.tamanoHex < minX) minX = pos.dx - widget.tamanoHex;
        if (pos.dx + widget.tamanoHex > maxX) maxX = pos.dx + widget.tamanoHex;
        if (pos.dy - widget.tamanoHex < minY) minY = pos.dy - widget.tamanoHex;
        if (pos.dy + widget.tamanoHex > maxY) maxY = pos.dy + widget.tamanoHex;
      }

      const double padding = 60.0;
      final double mapW = (maxX - minX) + padding * 2;
      final double mapH = (maxY - minY) + padding * 2;
      centerX = (minX + maxX) / 2;
      centerY = (minY + maxY) / 2;

      final double scaleX = effectiveSize.width / mapW;
      final double scaleY = effectiveSize.height / mapH;
      targetScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.2, 1.2);
    }

    // 3. Crear la Matriz destino
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(effectiveSize.width / 2, effectiveSize.height / 2, 0.0, 1.0)
      ..scaleByDouble(targetScale, targetScale, 1.0, 1.0)
      ..translateByDouble(-centerX, -centerY, 0.0, 1.0);

    if (!animado) {
      _transformController.value = targetMatrix;
      return;
    }

    // 4. Animación fluida usando vsync: this [Fase 1K]
    final AnimationController controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final animation = Matrix4Tween(
      begin: _transformController.value, 
      end: targetMatrix
    ).animate(CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn));

    animation.addListener(() {
      _transformController.value = animation.value;
    });

    controller.forward().then((_) => controller.dispose());
  }
}
