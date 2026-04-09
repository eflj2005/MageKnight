import 'package:flutter/material.dart';
import '../models/mana.dart';

class WidgetDadoMana extends StatelessWidget {
  final DadoMana dado;
  final VoidCallback? onTap;

  const WidgetDadoMana({Key? key, required this.dado, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorActivo = dado.tipo.colorVisual;

    // Un dado es "gris" si está agotado. Si es incompatible, mantiene color pero desaturado.
    // [Refinado v3.0.1] Ya no se "apaga" el dado al seleccionarlo.
    // Solo se desatura si es incompatible con el ciclo.
    final Color colorFondo = dado.esIncompatible
        ? colorActivo.withOpacity(0.4)
        : colorActivo;

    return GestureDetector(
      onTap: dado.esIncompatible ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 36, // [Fase 4F.6] Reducido de 40
        height: 36, // [Fase 4F.6] Reducido de 40
        margin: const EdgeInsets.symmetric(horizontal: 4.0), // [Fase 4F.6] Reducido de 5.0
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: dado.esIncompatible
              ? []
              : [
                  BoxShadow(
                    color: dado.estaAgotado
                        ? Colors.pinkAccent.withOpacity(
                            0.9,
                          ) // Casi opaco para mayor impacto
                        : colorActivo.withOpacity(0.5),
                    blurRadius: dado.estaAgotado ? 14 : 8, // [Refinado v3.0.6] Aura más discreta y profesional
                    spreadRadius: dado.estaAgotado ? 4 : 1,
                  ),
                ],
          border: Border.all(
            color: dado.estaAgotado
                ? Colors.pinkAccent
                : (dado.esIncompatible ? Colors.white10 : Colors.white24),
            width: dado.estaAgotado
                ? 3.0
                : 1.5, // [Refinado v3.0.5] Menos grueso
          ),
        ),
        child: Stack(
          clipBehavior: Clip
              .none, // [Refinamiento] Permitir que el 🚫 sobresalga del cubo
          alignment: Alignment.center,
          children: [
            // 1. Icono Representativo (Símbolo de la Magia)
            // [Refinamiento v2.2.2] Contraste dinámico: Negro para activo, Blanco para Bloqueado
            Icon(
              dado.tipo.iconoVisual,
              size: 18, // [Fase 4F.6] Reducido de 22
              color: dado.esIncompatible
                  ? Colors
                        .white // Resalta en el dado bloqueado
                  : Colors.black87,
            ),

            // 2. Señal de Prohibido (🚫) — Posicionada sobre el borde superior (Sutil)
            if (dado.esIncompatible)
              const Positioned(
                top: -8, // Ajuste sutil
                child: Icon(
                  Icons.block,
                  size: 18, // [Refinamiento] Más pequeño y sutil
                  color: Color(0xFFFF1744), // Rojo puro de advertencia
                ),
              ),
          ],
        ),
      ),
    );
  }
}
