import 'package:flutter/material.dart';
import 'package:gestor_lds/features/meetings/models/agenda_item_model.dart';

class AgendaListEditor extends StatefulWidget {
  final Function(List<AgendaItemModel>) onAgendaChanged;
  final List<AgendaItemModel> initialItems;

  const AgendaListEditor({
    super.key,
    required this.onAgendaChanged,
    this.initialItems = const [],
  });

  @override
  State<AgendaListEditor> createState() => _AgendaListEditorState();
}

class _AgendaListEditorState extends State<AgendaListEditor> {
  List<AgendaItemModel> _agendaItems = [];

  @override
  void initState() {
    super.initState();
    // 🚀 Sincronizamos la lista inicial que viene del padre
    _agendaItems = List.from(widget.initialItems);
  }

  void _addAgendaItem(String topic, String assignedTo) {
    if (topic.isEmpty || assignedTo.isEmpty) return;

    // 🚀 ID ÚNICO BLINDADO: Adiós al contador _nextId++, hola a los milisegundos exactos
    final newItem = AgendaItemModel(
      topic: topic,
      assignedTo: assignedTo,
      order: _agendaItems.length, // Hereda la posición actual como orden inicial
    );

    setState(() {
      _agendaItems.add(newItem);
    });

    widget.onAgendaChanged(_agendaItems);
  }

  void _showAddItemDialog() {
    final topicController = TextEditingController();
    final assignedController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Punto de Agenda'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  TextField(
                    controller: topicController,
                    maxLines: null,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      labelText: 'Asunto / Tema',
                      border: OutlineInputBorder(),
                      hintText: 'Escribe el tema a tratar...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: assignedController,
                    decoration: const InputDecoration(
                      labelText: 'Responsable',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Hna. García',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _addAgendaItem(topicController.text, assignedController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _showAddItemDialog,
          icon: const Icon(Icons.add),
          label: const Text('Añadir Punto de Agenda'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: const Color(0xFF22539A),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 15),

        if (_agendaItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'No hay puntos de agenda. Añade el primero.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          )
        else
        // 🚀 LISTA REORDENABLE: Permite arrastrar y soltar elementos fluidamente
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Evita conflictos de scroll con la pantalla principal
            itemCount: _agendaItems.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _agendaItems.removeAt(oldIndex);
                _agendaItems.insert(newIndex, item);

                // Actualizamos los índices de orden internamente
                for (int i = 0; i < _agendaItems.length; i++) {
                  _agendaItems[i] = _agendaItems[i].copyWith(order: i);
                }
              });
              widget.onAgendaChanged(_agendaItems);
            },
            itemBuilder: (context, index) {
              final item = _agendaItems[index];
              return Card(
                key: ValueKey(item.id), // Clave vital para que Flutter reconozca el ID único al reordenar
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.drag_indicator, color: Colors.grey), // Indicador visual de que se puede arrastrar
                  title: Text(item.topic, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Responsable: ${item.assignedTo}', style: TextStyle(color: Colors.grey.shade700)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _agendaItems.removeAt(index);
                      });
                      widget.onAgendaChanged(_agendaItems);
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}