import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class UserAutocompleteField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final Function(UserModel)? onUserSelected;
  final String? wardFilter;

  const UserAutocompleteField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.onUserSelected,
    this.wardFilter,
  });

  @override
  State<UserAutocompleteField> createState() => _UserAutocompleteFieldState();
}

class _UserAutocompleteFieldState extends State<UserAutocompleteField> {
  List<UserModel> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // 🚀 CARGA OPTIMIZADA (Ahora trae a TODOS los miembros, usen la app o no)
  Future<void> _loadUsers() async {
    try {
      // 🚀 QUITAMOS LA RESTRICCIÓN DE isApproved
      Query query = FirebaseFirestore.instance.collection('users');

      if (widget.wardFilter != null) {
        query = query.where('ward', isEqualTo: widget.wardFilter);
      }

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          // 🚀 ESCUDO TÁCTICO: Si una ficha del JSON está incompleta, la salta en lugar de romper toda la lista
          _allUsers = snapshot.docs.map((doc) {
            try {
              return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            } catch (e) {
              debugPrint('Error parseando usuario (Ignorado): $e');
              return null;
            }
          }).whereType<UserModel>().toList(); // Filtramos los nulos

          _isLoading = false;
        });
      }
    } catch (error) {
      debugPrint('Error cargando usuarios: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Lógica de filtrado local
  List<UserModel> _getSuggestions(String query) {
    final lowerQuery = query.toLowerCase();
    return _allUsers.where((user) {
      final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
      final calling = user.primaryCalling.toLowerCase();
      return fullName.contains(lowerQuery) || calling.contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    return LayoutBuilder(
        builder: (context, constraints) {
          return Autocomplete<UserModel>(
            displayStringForOption: (UserModel option) => '${option.firstName} ${option.lastName}',

            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<UserModel>.empty();
              }
              return _getSuggestions(textEditingValue.text);
            },

            onSelected: (UserModel selection) {
              widget.controller.text = '${selection.firstName} ${selection.lastName}';
              if (widget.onUserSelected != null) {
                widget.onUserSelected!(selection);
              }
            },

            fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
              if (widget.controller.text.isNotEmpty && textController.text.isEmpty) {
                textController.text = widget.controller.text;
              }

              textController.addListener(() {
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
                  isDense: true,
                ),
                validator: (val) => val != null && val.isEmpty ? 'Requerido' : null,
              );
            },

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
                      maxHeight: 250,
                      maxWidth: constraints.maxWidth,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final UserModel option = options.elementAt(index);
                        final isMale = option.gender == 'M';

                        String subText = option.organization;
                        if (option.primaryCalling.isNotEmpty && option.primaryCalling != 'Ninguno') {
                          subText += " • ${option.primaryCalling}";
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
                          title: Text('${option.firstName} ${option.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
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