import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/fuente_magia.dart';
import 'widget_dado_mana.dart';

class WidgetFuenteMana extends StatelessWidget {
  final FuenteMagia fuente;
  
  /// [Fase 4C] Callback para que la sesión registre el cambio de ciclo en el historial
  final VoidCallback? onCicloTap;

  const WidgetFuenteMana({
    super.key, 
    required this.fuente,
    this.onCicloTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: fuente,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: fuente.estaRodando ? 15 : 10, 
              sigmaY: fuente.estaRodando ? 15 : 10
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0), // [Fase 4F.6] Reducido
              decoration: BoxDecoration(
                color: fuente.estaRodando 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: fuente.estaRodando ? Colors.white70 : Colors.white24, 
                  width: 1.5
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título dinámico según ciclo impulsado por toque
                  GestureDetector(
                    onTap: onCicloTap ?? () => fuente.alternarCiclo(),
                    child: SizedBox(
                      width: 42, // [Fase 4F.6] Reducido de 50
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            fuente.cicloActual == CicloMundo.dia ? Icons.wb_sunny : Icons.nights_stay,
                            color: fuente.cicloActual == CicloMundo.dia ? Colors.amber : Colors.blueGrey,
                            size: 18, // [Fase 4F.6] Reducido de 20
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              fuente.cicloActual == CicloMundo.dia ? 'DÍA' : 'NOCHE',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6), // [Fase 4F.6] Reducido de 8
                  // Renderizar los dados
                  ...List.generate(fuente.dadosActivos.length, (index) {
                    final dado = fuente.dadosActivos[index];
                    return WidgetDadoMana(
                      dado: dado,
                      onTap: () {
                        // Consumir visualmente el dado
                        bool consumido = fuente.consumirDado(index);
                        if (consumido) {
                           // [Efecto Futuro] Partículas hacia el héroe
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
