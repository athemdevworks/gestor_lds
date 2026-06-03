import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/communications/services/citation_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/core/widgets/user_autocomplete_field.dart';

class DocumentGeneratorScreen extends StatefulWidget {
  // 🚀 MANDOS DEL MULTIVERSO
  final bool isStakeMode;
  final UserModel currentUser;

  const DocumentGeneratorScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser,
  });

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
  late String _selectedLeader;

  // Estado
  bool _isMale = false;
  late String _jurisdiction; // 🚀 El DNI Geográfico

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dateController.text = DateFormat('yyyy-MM-dd').format(_nextSunday());
    _timeController.text = "10:30 de la mañana";

    // 🚀 LÓGICA MULTIVERSO INICIAL
    _jurisdiction = widget.isStakeMode ? 'Estaca Jerusalén' : widget.currentUser.ward;
    _selectedLeader = widget.isStakeMode ? 'PRESIDENTE DE ESTACA' : 'OBISPO';
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
        title: Text(widget.isStakeMode ? 'Comunicaciones de Estaca' : 'Comunicaciones'),
        backgroundColor: const Color(0xFF22539A),
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

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyAssignmentToWhatsApp,
                  icon: const Icon(Icons.copy, color: Color(0xFF25D366)),
                  label: const Text('Copiar WA', style: TextStyle(color: Color(0xFF25D366))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF25D366)),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateAssignmentPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF Formal'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22539A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
            // 🚀 LISTA INTELIGENTE SEGÚN EL MODO
            items: (widget.isStakeMode
                ? ['PRESIDENTE DE ESTACA', 'PRIMER CONSEJERO', 'SEGUNDO CONSEJERO', 'MIEMBRO DEL SUMO CONSEJO']
                : ['OBISPO', 'PRIMER CONSEJERO', 'SEGUNDO CONSEJERO']
            ).map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _selectedLeader = v!),
          ),

          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyInterviewToWhatsApp,
                  icon: const Icon(Icons.copy, color: Color(0xFF25D366)),
                  label: const Text('Copiar WA', style: TextStyle(color: Color(0xFF25D366))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF25D366)),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateInterviewPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF Formal'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommonFields() {
    return Column(
      children: [
        UserAutocompleteField(
          label: 'Nombre del Miembro',
          controller: _nameController,
          icon: Icons.person_search,
          onUserSelected: (user) {
            setState(() {
              _isMale = user.gender == 'M';
            });
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Seleccionado: ${user.firstName} ${user.lastName}'),
              duration: const Duration(seconds: 1),
            ));
          },
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
                  DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.parse(_dateController.text), firstDate: DateTime.now(), lastDate: DateTime(2030));
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

  void _copyAssignmentToWhatsApp() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta el nombre')));
      return;
    }

    final date = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(DateTime.parse(_dateController.text));
    final isTalk = _selectedAssignmentType.contains('DISCURSO');
    final prefix = _isMale ? 'Estimado Hermano' : 'Estimada Hermana';
    final articulo = (_selectedAssignmentType.toUpperCase().contains('ORACION') || _selectedAssignmentType.toUpperCase().contains('ORACIÓN')) ? 'la ' : 'el ';

    final String leadershipTitle = widget.isStakeMode ? 'Presidencia de la Estaca Jerusalén' : 'Obispado del $_jurisdiction';
    final String signatureTitle = widget.isStakeMode ? 'Presidencia de Estaca' : 'Obispado de $_jurisdiction';

    String message = "*$prefix: ${_nameController.text.trim()}*\n\n";
    message += "Le extendemos un cordial saludo como $leadershipTitle, esperando que se encuentre gozando de las bendiciones y oportunidades que nuestro Padre Celestial derrama sobre las familias de todos sus hijos e hijas fieles a Su Obra. 👋\n\n";

    message += "En esta ocasión nos complace extenderle una cordial invitación para participar en nuestra reunión general con $articulo *${_selectedAssignmentType.toUpperCase()}* el día *$date* a las *${_timeController.text}* en nuestro centro de reuniones.\n\n";

    if (isTalk) {
      message += "📖 El tema asignado para esta ocasión es: *${_topicController.text.trim()}*.\n";
      message += "⏳ Tendrá un tiempo estimado no mayor a *${_durationController.text} min*.\n\n";
    }

    message += "Le pedimos estar 10 minutos antes del inicio de la reunión para sentarse en el estrado.\n\n";

    if (isTalk) {
      message += "Rogamos que el espíritu del Señor le inspire en la preparación de su mensaje y así todos podamos ser edificados en la casa de Dios. El prepararse diligentemente le traerá muchas bendiciones al esforzarse por vivir lo que aprenda.\n\n";
    }

    message += "Le agradecemos profundamente por su dedicado y genuino servicio al Salvador. Le recordamos y le admiramos por su fe y sus humildes oraciones. 🙏\n\n";
    message += "Con Amor,\n*$signatureTitle*";

    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Mensaje copiado al portapapeles'), backgroundColor: Colors.green));
  }

  void _copyInterviewToWhatsApp() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta el nombre')));
      return;
    }

    final date = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(DateTime.parse(_dateController.text));
    final prefix = _isMale ? 'Estimado Hermano' : 'Estimada Hermana';

    final String leadershipTitle = widget.isStakeMode ? 'Presidencia de la Estaca Jerusalén' : 'Obispado del $_jurisdiction';
    final String signatureTitle = widget.isStakeMode ? 'Presidencia de Estaca' : 'Obispado de $_jurisdiction';

    String message = "*$prefix: ${_nameController.text.trim()}*\n\n";
    message += "Le extendemos un cordial saludo como $leadershipTitle, esperando que se encuentre gozando de las bendiciones y oportunidades que nuestro Padre Celestial derrama sobre las familias de todos sus hijos e hijas fieles a Su Obra. 👋\n\n";

    message += "Por medio de la presente deseamos invitarle a una entrevista con el *$_selectedLeader*, la cual se llevará a cabo el día *$date* a las *${_timeController.text}* en nuestro centro de reuniones (Oficina de liderazgo).\n\n";

    message += "Agradecemos de antemano su puntualidad y disposición. Si tiene algún inconveniente con el horario, por favor avísenos.\n\n";

    message += "Le agradecemos profundamente por su dedicado y genuino servicio al Salvador. Le recordamos y le admiramos por su fe y sus humildes oraciones. 🙏\n\n";
    message += "Con Amor,\n*$signatureTitle*";

    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Mensaje copiado al portapapeles'), backgroundColor: Colors.green));
  }

  void _generateAssignmentPdf() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta el nombre')));
      return;
    }
    await _citationService.generateSacramentAssignment(
      name: _nameController.text,
      isMale: _isMale,
      assignmentType: _selectedAssignmentType,
      assignmentDate: DateTime.parse(_dateController.text),
      time: _timeController.text,
      topic: _selectedAssignmentType.contains('DISCURSO') ? _topicController.text : null,
      duration: _durationController.text,
      jurisdiction: _jurisdiction, // 🚀 MANDO AÑADIDO
      isStakeMode: widget.isStakeMode, // 🚀 MANDO AÑADIDO
    );
  }

  void _generateInterviewPdf() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta el nombre')));
      return;
    }
    await _citationService.generateInterviewCitation(
      name: _nameController.text,
      isMale: _isMale,
      leaderRole: _selectedLeader,
      date: DateTime.parse(_dateController.text),
      time: _timeController.text,
      jurisdiction: _jurisdiction, // 🚀 MANDO AÑADIDO
      isStakeMode: widget.isStakeMode, // 🚀 MANDO AÑADIDO
    );
  }
}