import 'package:flutter/material.dart';
import 'package:gestor_lds/features/members/models/member_model.dart';
import 'package:gestor_lds/features/members/services/member_service.dart';

class MemberAutocompleteField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;

  // 1. CAMBIO: Agregamos este parámetro para devolver el objeto completo
  final Function(MemberModel)? onMemberSelected;

  const MemberAutocompleteField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.onMemberSelected, // <--- Agregado al constructor
  });

  @override
  State<MemberAutocompleteField> createState() => _MemberAutocompleteFieldState();
}

class _MemberAutocompleteFieldState extends State<MemberAutocompleteField> {
  final MemberService _memberService = MemberService();

  // Cache local para no llamar a Firebase en cada letra si la lista es pequeña
  List<MemberModel>? _cachedMembers;

  Future<List<MemberModel>> _getSuggestions(String query) async {
    if (query.isEmpty) return [];

    // Si no hemos cargado la lista, la traemos toda una vez (optimización para < 500 miembros)
    if (_cachedMembers == null) {
      final snapshot = await _memberService.getMembers().first; // Trae la lista actual
      _cachedMembers = snapshot;
    }

    final lowerQuery = query.toLowerCase();
    return _cachedMembers!.where((member) {
      return member.fullName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<MemberModel>(
      // 1. Qué mostramos en el campo de texto cuando se selecciona alguien
      displayStringForOption: (MemberModel option) => option.fullName,

      // 2. Lógica de búsqueda
      optionsBuilder: (TextEditingValue textEditingValue) {
        return _getSuggestions(textEditingValue.text);
      },

      // 3. Qué hacer cuando se selecciona
      onSelected: (MemberModel selection) {
        widget.controller.text = selection.fullName;

        // 2. CAMBIO: Si nos pasaron una función, la ejecutamos y le damos el miembro
        if (widget.onMemberSelected != null) {
          widget.onMemberSelected!(selection);
        }
      },

      // 4. Personalización del Campo de Texto (Input)
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // Sincronizamos con el controlador externo si ya tiene texto (ej: al editar)
        if (widget.controller.text.isNotEmpty && textController.text.isEmpty) {
          textController.text = widget.controller.text;
        }

        // Listener para que si el usuario escribe a mano, también se guarde en tu controller
        textController.addListener(() {
          widget.controller.text = textController.text;
        });

        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
          },
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 18, color: Colors.grey),
          ),
          validator: (val) => val != null && val.isEmpty ? 'Requerido' : null,
        );
      },

      // 5. Personalización de la Lista de Sugerencias (Dropdown)
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final MemberModel option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                        option.gender == 'M' ? Icons.face : Icons.face_3,
                        color: option.gender == 'M' ? Colors.indigo : Colors.pink
                    ),
                    title: Text(option.fullName),
                    subtitle: Text(option.organization, style: const TextStyle(fontSize: 10)),
                    onTap: () => onSelected(option),
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