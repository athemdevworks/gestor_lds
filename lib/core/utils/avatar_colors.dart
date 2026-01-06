import 'package:flutter/material.dart';

class AvatarColors {
  // Paleta de colores estilo Material "moderno" (menos chillones)
  static final List<Color> _palette = [
    Colors.red.shade400,
    Colors.pink.shade400,
    Colors.purple.shade400,
    Colors.deepPurple.shade400,
    Colors.indigo.shade400,
    Colors.blue.shade400,
    Colors.lightBlue.shade400,
    Colors.cyan.shade600,
    Colors.teal.shade400,
    Colors.green.shade600,
    Colors.lightGreen.shade600,
    Colors.orange.shade700,
    Colors.deepOrange.shade400,
    Colors.brown.shade400,
    Colors.blueGrey.shade500,
  ];

  static Color getColor(String text) {
    if (text.isEmpty) return Colors.grey;

    // Magia matemática: Sumamos el código de cada letra
    // para obtener un número único para ese nombre.
    int hash = 0;
    for (int i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Usamos el número para elegir un color de la lista
    int index = hash.abs() % _palette.length;
    return _palette[index];
  }
}