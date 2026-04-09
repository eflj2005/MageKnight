import 'dart:math';
import 'package:flutter/material.dart';
import 'mana.dart';
import '../core/reglas/reglas_base.dart'; // [Fase 4] Soporte de reglas parametrizables

/// Control global del tiempo táctico en Mage Knight
enum CicloMundo { dia, noche }

/// Engine de probabilidad y almacenamiento de los "Dados Interactivos" de Mage Knight
class FuenteMagia extends ChangeNotifier {
  /// Lista oficial de dados disponibles en el tablero (La Fuente "The Source").
  final List<DadoMana> dadosActivos = [];

  CicloMundo cicloActual = CicloMundo.dia;

  /// Indica si los dados están en proceso de animación de lanzamiento
  bool estaRodando = false;

  final Random _rnd = Random();

  /// [Fase 4] Reglas del escenario activo (opcional). Si es null, se usan las reglas oficiales.
  final ReglaJuego? reglas;

  /// Número de dados: si hay reglas, lo define el escenario; si no, el default es 3.
  int get limiteDados => reglas?.numeroDados ?? 3;

  FuenteMagia({this.reglas}) {
    _inicializarFuente();
  }

  void _inicializarFuente() {
    dadosActivos.clear();
    for (int i = 0; i < limiteDados; i++) {
        dadosActivos.add(DadoMana(tipo: TipoMana.blanco)); 
    }
    lanzarDados(); // Roll inicial
  }

  /// Efectúa un lanzamiento asíncrono con animación visual de rodado.
  /// [Refinamiento] Solo se lanzan dados agotados y NO incompatibles.
  Future<void> lanzarDados({bool rerollAgotados = false}) async {
    if (estaRodando) return;
    
    estaRodando = true;
    notifyListeners();

    // Animación de rodado: Cambiar colores aleatoriamente durante un tiempo
    const int pasos = 8;
    for (int p = 0; p < pasos; p++) {
        for (var dado in dadosActivos) {
            // [Regla 1.3] Los dados anulados NO se pueden relanzar
            if (!dado.esIncompatible) {
               if (!rerollAgotados || (rerollAgotados && dado.estaAgotado)) {
                  dado.tipo = AtributosMana.desdeCaraD6(_rnd.nextInt(6));
               }
            }
        }
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 100)); // Cadencia de rodado
    }

    // Resultado final y limpieza
    estaRodando = false;
    for (var dado in dadosActivos) {
       if (!dado.esIncompatible) {
          if (!rerollAgotados || (rerollAgotados && dado.estaAgotado)) {
             dado.tipo = AtributosMana.desdeCaraD6(_rnd.nextInt(6));
             dado.reactivar();
          }
       }
    }
    
    _aplicarReglaMataMagiaIncompatible();
    notifyListeners();
  }

  /// [Regla Táctica] En Mage Knight, los Maná opuestos a la franja horaria se anulan.
  /// [Fase 4] Si hay reglas del escenario, delega en ellas. Si no, usa la regla oficial.
  void _aplicarReglaMataMagiaIncompatible() {
     for (var dado in dadosActivos) {
        // Reset del estado para volver a evaluar tras el roll o cambio de ciclo
        dado.esIncompatible = false;

        if (reglas != null) {
          // Delegar la decisión al escenario activo
          dado.esIncompatible = reglas!.dadoEsIncompatible(dado.tipo, cicloActual);
        } else {
          // Regla oficial por defecto (retrocompatibilidad)
          if (cicloActual == CicloMundo.dia && dado.tipo == TipoMana.negro) {
              dado.esIncompatible = true; 
          } else if (cicloActual == CicloMundo.noche && dado.tipo == TipoMana.dorado) {
              dado.esIncompatible = true;
          }
        }
     }
  }

  /// [Fase 4] Método público para que SesionJuego pueda re-evaluar
  /// las reglas de compatibilidad tras un undo/redo de cambio de ciclo.
  void aplicarReglaIncompatible() => _aplicarReglaMataMagiaIncompatible();

  /// Cambio global de Fase. Afecta drásticamente las reglas de supervivencia de los dados
  void alternarCiclo() {
    cicloActual = cicloActual == CicloMundo.dia ? CicloMundo.noche : CicloMundo.dia;
    _aplicarReglaMataMagiaIncompatible(); // Purga dados vivos incompatibles tras el cambio temporal
    notifyListeners();
  }

  /// [Refinado v3.0.4] Consume o Des-selecciona un dado (Toggle).
  bool consumirDado(int indice) {
    if (indice >= 0 && indice < dadosActivos.length) {
      final dado = dadosActivos[indice];
      if (!dado.esIncompatible) {
         dado.estaAgotado = !dado.estaAgotado;
         notifyListeners();
         return true;
      }
    }
    return false;
  }
}
