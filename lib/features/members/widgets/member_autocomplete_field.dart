import 'package:flutter/material.dart';
import 'package:gestor_lds/features/members/models/member_model.dart';
import 'package:gestor_lds/features/members/services/member_service.dart';

class MemberAutocompleteField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final Function(MemberModel)? onMemberSelected; // Callback para devolver todo el objeto

  const MemberAutocompleteField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.onMemberSelected,
  });

  @override
  State<MemberAutocompleteField> createState() => _MemberAutocompleteFieldState();
}

class _MemberAutocompleteFieldState extends State<MemberAutocompleteField> {
  final MemberService _memberService = MemberService();
  List<MemberModel> _allMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  // Carga inicial optimizada: Traemos la lista una vez y filtramos en memoria
  void _loadMembers() {
    _memberService.getMembers().listen((members) {
      if (mounted) {
        setState(() {
          _allMembers = members;
          _isLoading = false;
        });
      }
    });
  }

  // Lógica de filtrado local (Súper rápida)
  List<MemberModel> _getSuggestions(String query) {
    final lowerQuery = query.toLowerCase();
    return _allMembers.where((member) {
      return member.fullName.toLowerCase().contains(lowerQuery) ||
          (member.calling?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LinearProgressIndicator(minHeight: 2); // Feedback visual de carga
    }

    return LayoutBuilder(
        builder: (context, constraints) {
          return Autocomplete<MemberModel>(
            // 1. Qué mostramos en el Input tras seleccionar
            displayStringForOption: (MemberModel option) => option.fullName,

            // 2. Lógica de búsqueda
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<MemberModel>.empty();
              }
              return _getSuggestions(textEditingValue.text);
            },

            // 3. Acción al seleccionar
            onSelected: (MemberModel selection) {
              widget.controller.text = selection.fullName;
              if (widget.onMemberSelected != null) {
                widget.onMemberSelected!(selection);
              }
            },

            // 4. Input Field Personalizado
            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
              // Sincronización inicial si venimos de editar
              if (widget.controller.text.isNotEmpty && textController.text.isEmpty) {
                textController.text = widget.controller.text;
              }

              // Listener bidireccional seguro
              textController.addListener(() {
                // Solo actualizamos si es diferente para evitar loops
                if (widget.controller.text != textController.text) {
                  widget.controller.text = textController.text;
                }
              });

              return TextFormField(
                controller: textController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: widget.label,
                  prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ),
                validator: (val) => val != null && val.isEmpty ? 'Requerido' : null,
              );
            },

            // 5. Lista Desplegable Personalizada
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  color: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 250, // Altura máxima de la lista
                      maxWidth: constraints.maxWidth, // Ancho igual al del input
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final MemberModel option = options.elementAt(index);
                        final isMale = option.gender == 'M';

                        // Construimos subtítulo
                        String subText = option.primaryOrganization;
                        if (option.calling != null) {
                          subText += " • ${option.calling}";
                        }

                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: isMale ? Colors.blue.shade100 : Colors.pink.shade100,
                            child: Icon(
                              isMale ? Icons.person : Icons.person_2,
                              size: 16,
                              color: isMale ? Colors.blue.shade800 : Colors.pink.shade800,
                            ),
                          ),
                          title: Text(option.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(subText, style: const TextStyle(fontSize: 11)),
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
    );
  }
}