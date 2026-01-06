import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/communications/services/citation_service.dart';

class DocumentGeneratorScreen extends StatefulWidget {
  const DocumentGeneratorScreen({super.key});

  @override
  State<DocumentGeneratorScreen> createState() => _DocumentGeneratorScreenState();
}

class _DocumentGeneratorScreenState extends State<DocumentGeneratorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CitationService _citationService = CitationService();

  // Controladores Comunes
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // Controladores Asignación
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: "8");
  String _selectedAssignmentType = 'TERCER DISCURSO';

  // Controladores Entrevista
  String _selectedLeader = 'OBISPO';

  // Estado
  bool _isMale = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fecha por defecto: Próximo Domingo
    _dateController.text = DateFormat('yyyy-MM-dd').format(_nextSunday());
    _timeController.text = "10:30 de la mañana";
  }

  DateTime _nextSunday() {
    final now = DateTime.now();
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) daysUntilSunday += 7;
    return now.add(Duration(days: daysUntilSunday));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Documentos'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(text: 'ASIGNACIONES', icon: Icon(Icons.assignment)),
            Tab(text: 'CITACIONES', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentForm(),
          _buildInterviewForm(),
        ],
      ),
    );
  }

  // --- FORMULARIO DE ASIGNACIONES (Discursos/Oraciones) ---
  Widget _buildAssignmentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCommonFields(),
          const SizedBox(height: 20),

          const Text('Detalles de Asignación', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
            value: _selectedAssignmentType,
            items: [
              'PRIMERA ORACION', 'ULTIMA ORACION',
              'PRIMER DISCURSO', 'SEGUNDO DISCURSO', 'TERCER DISCURSO'
            ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedAssignmentType = v!),
          ),
          const SizedBox(height: 15),

          if (_selectedAssignmentType.contains('DISCURSO')) ...[
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(labelText: 'Tema Asignado', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Tiempo (minutos)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],

          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _generateAssignmentPdf(),
            icon: const Icon(Icons.print),
            label: const Text('GENERAR ASIGNACIÓN'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF164772), foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }

  // --- FORMULARIO DE ENTREVISTAS ---
  Widget _buildInterviewForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCommonFields(),
          const SizedBox(height: 20),

          const Text('Detalles de Entrevista', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Entrevistador', border: OutlineInputBorder()),
            value: _selectedLeader,
            items: ['OBISPO', 'PRIMER CONSEJERO', 'SEGUNDO CONSEJERO']
                .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedLeader = v!),
          ),

          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _generateInterviewPdf(),
            icon: const Icon(Icons.print),
            label: const Text('GENERAR CITACIÓN'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }

  // --- CAMPOS COMUNES (Nombre, Género, Fecha, Hora) ---
  Widget _buildCommonFields() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nombre del Miembro', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
        ),
        const SizedBox(height: 15),

        Row(
          children: [
            const Text('Género: ', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            ToggleButtons(
              isSelected: [!_isMale, _isMale],
              onPressed: (index) => setState(() => _isMale = index == 1),
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('HERMANA')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('HERMANO')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _dateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_month)),
                onTap: () async {
                  DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _dateController.text = DateFormat('yyyy-MM-dd').format(picked));
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'Hora (Texto)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time), hintText: "10:30 AM"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _generateAssignmentPdf() async {
    if (_nameController.text.isEmpty) return;
    await _citationService.generateSacramentAssignment(
      name: _nameController.text,
      isMale: _isMale,
      assignmentType: _selectedAssignmentType,
      assignmentDate: DateTime.parse(_dateController.text),
      time: _timeController.text,
      topic: _selectedAssignmentType.contains('DISCURSO') ? _topicController.text : null,
      duration: _durationController.text,
    );
  }

  void _generateInterviewPdf() async {
    if (_nameController.text.isEmpty) return;
    await _citationService.generateInterviewCitation(
      name: _nameController.text,
      isMale: _isMale,
      leaderRole: _selectedLeader,
      date: DateTime.parse(_dateController.text),
      time: _timeController.text,
    );
  }
}