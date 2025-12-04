import 'package:flutter/material.dart';
import 'package:gestor_lds/features/meetings/models/agenda_item_model.dart';

class AgendaListEditor extends StatefulWidget {
  // Callback para retornar la lista de agenda a la pantalla principal
  final Function(List<AgendaItemModel>) onAgendaChanged;
  final List<AgendaItemModel> initialItems;

  const AgendaListEditor({
    super.key,
    required this.onAgendaChanged,
    this.initialItems = const [], // <--- Asignar valor por defecto
  });

  @override
  State<AgendaListEditor> createState() => _AgendaListEditorState();
}

class _AgendaListEditorState extends State<AgendaListEditor> {
  List<AgendaItemModel> _agendaItems = [];
  int _nextId = 0; // Usaremos un contador simple para los IDs temporales

  @override
  void initState() {
    super.initState();
    // Inicializar la lista de estado con los ítems que vinieron del padre (modo edición)
    _agendaItems = List.from(widget.initialItems);
    // Establecer un ID inicial seguro para nuevos ítems
    _nextId = _agendaItems.length;
  }

  void _addAgendaItem(String topic, String assignedTo) {
    if (topic.isEmpty || assignedTo.isEmpty) return;

    final newItem = AgendaItemModel(
      id: (_nextId++).toString(),
      topic: topic,
      assignedTo: assignedTo,
    );

    setState(() {
      _agendaItems.add(newItem);
    });

    // Notificar al padre (MeetingFormScreen) sobre el cambio
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
          // 1. Envolvemos el contenido en un ConstrainedBox
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500), // Ancho máximo cómodo para lectura
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),

                  TextField(
                    controller: topicController,
                    maxLines: null, // Crecimiento vertical
                    minLines: 1,
                    keyboardType: TextInputType.multiline, // Permite 'Enter'
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
        // Botón para añadir nuevo punto
        ElevatedButton.icon(
          onPressed: _showAddItemDialog,
          icon: const Icon(Icons.add),
          label: const Text('Añadir Punto de Agenda'),
        ),
        const SizedBox(height: 10),

        // Lista de Puntos Agregados
        if (_agendaItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No hay puntos de agenda. Añade el primero.'),
          ),

        ..._agendaItems.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(item.topic),
            subtitle: Text('Responsable: ${item.assignedTo}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _agendaItems.remove(item);
                });
                widget.onAgendaChanged(_agendaItems);
              },
            ),
          ),
        )).toList(),
      ],
    );
  }
}