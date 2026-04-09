import 'package:flutter/material.dart';

enum TipoCarta { accion, hechizo, artefacto, herida }

/// Representa el color básico de maná al que está asociada una carta o dado.
enum ColorMana {
  blanco(Colors.white),
  azul(Colors.blue),
  rojo(Colors.red),
  verde(Colors.green),
  dorado(Colors.amber),
  negro(Colors.black);

  final Color colorVisual;
  const ColorMana(this.colorVisual);
}

class Carta {
  final String idInterno;     // ID técnico único (ej. "march_base")
  final String? numeroCarta;  // Número oficial (ej. "017")
  final String nombre;
  final TipoCarta tipo;
  final ColorMana? colorBase;
  final String categoria;     // CATEGORÍA: "comun", "tovak", "goldyx", etc.
  final List<String> iconosPuntos; // Iconos base (ej. '👣', '⚔️')

  final String textoBasico;
  final String textoPotenciado;

  /// Nombre del archivo de imagen (sin extensión) para el arte de la carta.
  /// Se buscará en assets/images/cards/${imagenNombre}.png
  final String? imagenNombre;

  const Carta({
    required this.idInterno,
    this.numeroCarta,
    required this.nombre,
    required this.tipo,
    this.colorBase,
    required this.categoria,
    this.iconosPuntos = const [],
    required this.textoBasico,
    required this.textoPotenciado,
    this.imagenNombre,
  });

  /// Método para clonar una carta con un número oficial específico preservando el arte.
  /// Genera un nuevo idInterno compuesto: "PrefijoTemplate_###" para garantizar unicidad.
  Carta copiarConNumero(String numero) {
    return Carta(
      idInterno: '${idInterno}_$numero',
      numeroCarta: numero,
      nombre: nombre,
      tipo: tipo,
      colorBase: colorBase,
      categoria: categoria,
      iconosPuntos: iconosPuntos,
      textoBasico: textoBasico,
      textoPotenciado: textoPotenciado,
      imagenNombre: imagenNombre,
    );
  }
}
