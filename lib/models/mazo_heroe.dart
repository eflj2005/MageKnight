import 'package:flutter/foundation.dart';
import 'carta.dart';
import '../data/catalogo_cartas.dart'; // [Fase 5A] Diccionario real de cartas

class MazoHeroe extends ChangeNotifier {
  List<Carta> mazo = [];
  List<Carta> mano = [];
  List<Carta> descarte = [];

  MazoHeroe({String heroeNombre = 'Tovak'}) {
    _generarMazoInicialPrueba(heroeNombre);
  }

  void _generarMazoInicialPrueba(String heroeNombre) {
    // 1. Obtener el mazo estructurado desde el diccionario según el nombre del héroe
    switch (heroeNombre.toLowerCase()) {
      case 'goldyx':
        mazo = CatalogoCartas.obtenerMazoGoldyx();
        break;
      case 'arythea':
        mazo = CatalogoCartas.obtenerMazoArythea();
        break;
      case 'norowas':
        mazo = CatalogoCartas.obtenerMazoNorowas();
        break;
      case 'tovak':
      default:
        mazo = CatalogoCartas.obtenerMazoTovak();
        break;
    }

    // 2. Barajar el mazo (simulación simple)
    mazo.shuffle();

    // 3. Robar las primeras 8 cartas hacia la mano para verlas en el UI (Prueba 5B)
    mano = mazo.take(8).toList();
    mazo.removeRange(0, 8);

    notifyListeners();
  }

  /// Método temporal para jugar una carta de la mano al descarte
  void jugarCarta(Carta carta) {
    if (mano.contains(carta)) {
      mano.remove(carta);
      descarte.add(carta);
      notifyListeners();
    }
  }
}
