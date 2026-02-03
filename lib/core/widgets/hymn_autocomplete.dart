import 'package:flutter/material.dart';

import '../constants/hymns_data.dart';

class HymnAutocomplete extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;

  const HymnAutocomplete({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      // 1. Configuración inicial
      initialValue: TextEditingValue(text: controller.text),

      // 2. Lógica de Búsqueda
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        // Busca por número o por nombre (ignora mayúsculas/minúsculas y acentos básicos)
        return HymnsData.allHymns.where((String option) {
          final query = textEditingValue.text.toLowerCase();
          final item = option.toLowerCase();
          return item.contains(query);
        });
      },

      // 3. Cuando selecciona una opción
      onSelected: (String selection) {
        controller.text = selection;
      },

      // 4. Cómo se ve el campo de texto (Input)
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // Sincronizamos el controlador interno del Autocomplete con el externo
        if (controller.text != textController.text) {
          textController.text = controller.text;
        }

        // Listener para actualizar el controlador padre si el usuario escribe manual
        textController.addListener(() {
          controller.text = textController.text;
        });

        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                textController.clear();
                controller.clear();
              },
            ),
          ),
        );
      },

      // 5. Cómo se ven las opciones (Lista desplegable)
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              height: 250.0, // Altura máxima de la lista
              width: 300.0, // Ojo: Ajustar ancho según necesidad o usar LayoutBuilder
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    leading: const Icon(Icons.music_note, size: 16, color: Colors.indigo),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}