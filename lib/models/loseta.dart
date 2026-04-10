import 'package:flutter/material.dart'; // Necesario para Color [Fase 2A]
import 'hexagono.dart';
import 'heroe.dart';

/// Representa una loseta del juego de mesa Mage Knight.
/// Una loseta es un grupo de 7 hexágonos en patrón hexagonal:
/// 1 celda central + 6 celdas en anillo.
///
/// En el juego físico son piezas de cartón que se voltean y colocan
/// en el mapa durante la exploración.
class Loseta {
  /// Identificador único de esta loseta
  final int id;

  /// Nombre descriptivo de la loseta (para logs y debug)
  final String nombre;

  /// Lista de los 7 hexágonos que componen esta loseta.
  /// Las coordenadas son RELATIVAS al hexágono central (offset 0,0).
  /// Se usan offsets estándar del sistema axial para un anillo de radio 1.
  /// Lista de los 7 hexágonos que componen esta loseta.
  final List<({int q, int r, TipoTerreno tipo, TipoSitio? sitio, ColorMana? colorMana})> definicion;

  /// Clasificación de la loseta para la interfaz
  final TipoLoseta tipo;

  const Loseta({
    required this.id,
    required this.nombre,
    required this.definicion,
    required this.tipo,
  });

  /// Genera la lista de [Hexagono] posicionados en el mapa real,
  /// aplicando el offset (qOrigen, rOrigen) al centro de la loseta
  /// y rotando la loseta si se especifica.
  ///
  /// [qOrigen], [rOrigen] — coordenadas axiales del centro de la loseta en el mapa
  /// [rotacion] — número de rotaciones de 60° (0-5), aplica rotación axial
  List<Hexagono> generarHexagonos({
    required int qOrigen,
    required int rOrigen,
    int rotacion = 0,
  }) {
    return definicion.map((def) {
      // Aplicar rotación axial. La rotación en hex coords se hace con
      // la siguiente transformación: (q,r) → (-r, q+r) por cada 60°
      var qR = def.q;
      var rR = def.r;
      for (var i = 0; i < rotacion % 6; i++) {
        final temp = qR;
        qR = -rR;
        rR = temp + rR;
      }
      return Hexagono(
        q: qR + qOrigen,
        r: rR + rOrigen,
        tipo: def.tipo,
        sitio: def.sitio,
        idLoseta: id,
        esExplorado: true,
        esCentroLoseta: def.q == 0 && def.r == 0,
        rotacion: rotacion,
        tipoLoseta: tipo,
        colorMana: def.colorMana,
      );
    }).toList();
  }
}

/// Formas en las que el mapa puede expandirse
enum FormaMapa {
  libre, // Expansión en cualquier dirección (360 grados)
  cuna,  // Expansión cónica (Wedge) como en la primera exploración
}

/// Generador de un mapa de Mage Knight usando el sistema de losetas.
/// Gestiona el mazo de losetas pendientes y la lógica de expansión.
class MapaJuego {
  /// Forma arquitectónica que restringe el crecimiento de la exploración
  FormaMapa formaMapa = FormaMapa.cuna;

  /// Celdas ya colocadas en el mapa. La clave es "q,r".
  final Map<String, Hexagono> celdas = {};

  /// Mazo de losetas pendientes por revelar (orden aleatorio)
  final List<Loseta> _mazo = [];

  /// Número de losetas reveladas hasta ahora
  int get losetasReveladas => _losetasReveladas;
  int _losetasReveladas = 0;

  /// Número de losetas restantes en el mazo
  int get losetasRestantes => _mazo.length;

  /// Indica si el mazo está agotado
  bool get mazoAgotado => _mazo.isEmpty;

  /// Héroe controlado por el jugador (instanciado en inicializar)
  Heroe? _heroe;
  Heroe? get heroe => _heroe;
  /// Permite reemplazar el héroe activo en tiempo real (cambio de personaje) [Fase 2A]
  set heroe(Heroe? value) => _heroe = value;

  /// Inicializa el mapa con la loseta de inicio y el mazo dado.
  /// [losetaInicio] se coloca siempre en el centro (0,0), explorada.
  /// [mazo] es el resto de losetas, ya mezcladas.
  /// [heroeInicial] — [Fase 4] Héroe inyectado desde el exterior (SesionJuego).
  ///   Si es null, se usa el héroe por defecto (Tovak) para retrocompatibilidad.
  void inicializar({
    required Loseta losetaInicio,
    required List<Loseta> mazo,
    int semillaAleatoria = 0,
    Heroe? heroeInicial,
  }) {
    celdas.clear();
    _mazo.clear();
    _losetasReveladas = 0;

    // Colocar loseta inicial en coordenadas (0,0)
    _colocarLoseta(losetaInicio, qOrigen: 0, rOrigen: 0, rotacion: 0);
    _losetasReveladas = 1;

    // [Fase 4] Si se inyecta el héroe, usarlo. Si no, crear el Tovak por defecto.
    // Esto conserva el comportamiento anterior cuando no se usa SesionJuego.
    _heroe = heroeInicial ?? Heroe(
      nombre: 'Tovak',
      imageName: 'heroe1',
      q: 0,
      r: 0,
      puntosMovimiento: 26,
      puntosInfluencia: 4, 
      puntosAtaque: 8,
      puntosBloqueo: 5,
      puntosCuracion: 2,
      color: const Color(0xFFFFD700),
      colorRastro: const Color(0xFFFFAA00),
    );

    // Cargar el mazo (ya mezclado desde el exterior)
    _mazo.addAll(mazo);

    // Calcular celdas de borde iniciales
    _actualizarBordes();
  }

  /// Calcula la distancia axial entre dos puntos.
  int distancia(int q1, int r1, int q2, int r2) {
    return ((q1 - q2).abs() + (q1 + r1 - q2 - r2).abs() + (r1 - r2).abs()) ~/ 2;
  }

  /// Verifica si dos coordenadas están en línea recta en el grid hexagonal.
  /// En coordenadas axiales (q, r), esto ocurre si dq=0, dr=0 o dq+dr=0 (ds=0).
  bool esLineaRecta(int q1, int r1, int q2, int r2) {
    final dq = q2 - q1;
    final dr = r2 - r1;
    return dq == 0 || dr == 0 || (dq + dr) == 0;
  }

  /// Retorna la lista de hexágonos intermedios (incluyendo destino, excluyendo origen)
  /// siguiendo una línea recta. Si no es línea recta, retorna lista vacía.
  List<Hexagono> obtenerRutaRecta(int q1, int r1, int q2, int r2) {
    if (!esLineaRecta(q1, r1, q2, r2)) return [];
    
    final d = distancia(q1, r1, q2, r2);
    if (d == 0) return [];

    final ruta = <Hexagono>[];
    for (int i = 1; i <= d; i++) {
      // Interpolación lineal en coordenadas axiales
      final double t = i / d;
      final double qf = q1 + (q2 - q1) * t;
      final double rf = r1 + (r2 - r1) * t;
      
      // Redondeo a la celda hexagonal más cercana
      final coords = _redondearHex(qf, rf);
      final hex = celdas['${coords.$1},${coords.$2}'];
      if (hex != null) {
        ruta.add(hex);
      }
    }
    return ruta;
  }

  /// Ayudante para redondear coordenadas fraccionales a la celda hexagonal más cercana.
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

  /// Calcula el costo total de PM para una ruta en línea recta.
  /// Retorna 999 si la ruta es inválida (obstruida o no explorada).
  int calcularCostoRuta(int q1, int r1, int q2, int r2) {
    final ruta = obtenerRutaRecta(q1, r1, q2, r2);
    if (ruta.isEmpty || ruta.length != distancia(q1, r1, q2, r2)) return 999;
    
    int costoTotal = 0;
    for (final hex in ruta) {
      if (!hex.esExplorado || !hex.esTransitable) return 999;
      costoTotal += hex.costo;
    }
    return costoTotal;
  }

  /// Verifica si el héroe puede moverse a la posición indicada (Línea Recta).
  bool puedeMoverseA(int destinoQ, int destinoR) {
    if (_heroe == null) return false;
    
    // Si es la misma celda, no hay movimiento
    if (_heroe!.q == destinoQ && _heroe!.r == destinoR) return false;

    // 1. Debe ser línea recta
    if (!esLineaRecta(_heroe!.q, _heroe!.r, destinoQ, destinoR)) return false;

    // 2. Calcular costo y validar viabilidad física (transitable/explorado)
    final costoTotal = calcularCostoRuta(_heroe!.q, _heroe!.r, destinoQ, destinoR);
    if (costoTotal > 900) return false;

    // 3. Debe tener PM suficientes
    if (_heroe!.puntosMovimiento < costoTotal) return false;

    return true;
  }

  /// Ejecuta el movimiento si es válido (Línea Recta).
  bool moverHeroe(int destinoQ, int destinoR) {
    if (!puedeMoverseA(destinoQ, destinoR)) return false;

    final costoTotal = calcularCostoRuta(_heroe!.q, _heroe!.r, destinoQ, destinoR);
    _heroe!.moverA(destinoQ, destinoR);
    _heroe!.consumirMovimiento(costoTotal);
    return true;
  }

  /// Coloca una loseta en el mapa con el centro en (qOrigen, rOrigen).
  /// Devuelve la lista de claves de las celdas añadidas para auditoría.
  List<String> _colocarLoseta(Loseta loseta, {
    required int qOrigen,
    required int rOrigen,
    required int rotacion,
  }) {
    final hexagonos = loseta.generarHexagonos(
      qOrigen: qOrigen,
      rOrigen: rOrigen,
      rotacion: rotacion,
    );
    final clavesAnadidas = <String>[];
    for (final hex in hexagonos) {
      if (!celdas.containsKey(hex.clave)) {
        celdas[hex.clave] = hex;
        clavesAnadidas.add(hex.clave);
      }
    }
    return clavesAnadidas;
  }

  /// Retorna las coordenadas del centro geométrico de la loseta a la que
  /// pertenece el hexágono (q, r) en la malla de 7-hex tessellation.
  (int, int) obtenerCentroLoseta(int q, int r) {
    final iFrac = (3 * q + r) / 7.0;
    final jFrac = (-q + 2 * r) / 7.0;
    final i = iFrac.round();
    final j = jFrac.round();
    final cQ = i * 2 + j * (-1);
    final cR = i * 1 + j * 3;
    return (cQ, cR);
  }

  /// Retorna los centros exactos de las losetas adyacentes vacías.
  /// Usar la teselación correcta de 7-hex para encajar el mapa sin solapamientos.
  Set<String> get posicionesFantasma {
    if (mazoAgotado) return {};
    
    // Identificar qué centros de losetas ya existen en el mapa
    final centrosExistentes = <String>{};
    for (final hex in celdas.values) {
      if (!hex.esExplorado) continue;
      final centro = obtenerCentroLoseta(hex.q, hex.r);
      centrosExistentes.add('${centro.$1},${centro.$2}');
    }

    // Los 6 vectores de centro-a-centro en un teselado de losetas hexagonales de 7 celdas
    final direccionesLoseta = [
      (2, 1), (-1, 3), (-3, 2),
      (-2, -1), (1, -3), (3, -2),
    ];

    final fantasmas = <String>{};
    for (final cClave in centrosExistentes) {
      final partes = cClave.split(',');
      final cQ = int.parse(partes[0]);
      final cR = int.parse(partes[1]);

      for (final dir in direccionesLoseta) {
        final nQ = cQ + dir.$1;
        final nR = cR + dir.$2;
        
        // Limitar la forma del mapa a un Cono (Wedge) matemático
        if (formaMapa == FormaMapa.cuna) {
          final int u7 = 3 * nQ + nR;
          final int v7 = -2 * nQ - 3 * nR;
          if (u7 < 0 || v7 < 0) continue; 
        }

        final nClave = '$nQ,$nR';
        if (!centrosExistentes.contains(nClave)) {
          // [REGLA Mage Knight] Solo mostrar fantasmas si el héroe está 
          // en un borde adyacente a ese territorio.
          if (esHeroeAdyacenteALoseta(nQ, nR)) {
            fantasmas.add(nClave);
          }
        }
      }
    }
    return fantasmas;
  }

  /// Verifica si el héroe está en una posición desde la que puede descubrir
  /// la loseta que se centraría en [targetQ],[targetR].
  bool esHeroeAdyacenteALoseta(int targetQ, int targetR) {
    if (_heroe == null) return false;
    
    // Una loseta tiene 7 hexágonos. 
    // Basta que el héroe sea vecino de cualquiera de ellos.
    final offsetsLoseta = [
      (0, 0), (1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)
    ];

    for (final off in offsetsLoseta) {
      final hQ = targetQ + off.$1;
      final hR = targetR + off.$2;
      if (distancia(_heroe!.q, _heroe!.r, hQ, hR) == 1) {
        return true;
      }
    }
    return false;
  }

  /// Expande el mapa colocando la siguiente loseta del mazo con su CENTRO
  /// exactamente en [q],[r] (la posición del hexágono fantasma tocado).
  /// Retorna la Loseta revelada, o null si falló o no fue posible.
  Loseta? expandirEn(int q, int r) {
    if (mazoAgotado) return null;
    
    // Validación de adyacencia según reglas
    if (!esHeroeAdyacenteALoseta(q, r)) return null;

    final loseta = _mazo.removeAt(0);
    const rotacion = 0; 
    
    _colocarLoseta(loseta, qOrigen: q, rOrigen: r, rotacion: rotacion);
    _losetasReveladas++;
    _actualizarBordes();
    return loseta;
  }

  /// Revierte la expansión de una loseta (Undo).
  void revertirExpansion(Loseta loseta, int q, int r) {
    // 1. Identificar hexágonos de esta loseta y eliminarlos
    final hexagonos = loseta.generarHexagonos(qOrigen: q, rOrigen: r, rotacion: 0);
    for (final hex in hexagonos) {
      celdas.remove(hex.clave);
    }

    // 2. Devolver loseta al inicio del mazo
    _mazo.insert(0, loseta);
    _losetasReveladas--;

    // 3. Recalcular bordes
    _actualizarBordes();
  }

  /// Recalcula qué celdas son "borde explorable".
  /// Una celda es borde si es explorada y tiene al menos un vecino que
  /// no está en el mapa (i.e., hay espacio para expandir).
  void _actualizarBordes() {
    final direcciones = [
      (1, 0), (1, -1), (0, -1),
      (-1, 0), (-1, 1), (0, 1),
    ];

    for (final hex in celdas.values) {
      // Solo las celdas exploradas y transitables pueden ser borde
      if (!hex.esExplorado || !hex.esTransitable) {
        hex.esBorde = false;
        continue;
      }

      bool tieneLadoLibre = false;
      for (final dir in direcciones) {
        final qVec = hex.q + dir.$1;
        final rVec = hex.r + dir.$2;
        if (!celdas.containsKey('$qVec,$rVec')) {
          tieneLadoLibre = true;
          break;
        }
      }
      hex.esBorde = tieneLadoLibre && !mazoAgotado;
    }
  }

  /// Retorna la lista de todos los hexágonos de borde
  List<Hexagono> get bordes =>
      celdas.values.where((h) => h.esBorde).toList();

  /// Retorna un hexágono por clave "q,r", o null si no existe
  Hexagono? obtener(int q, int r) => celdas['$q,$r'];
}
