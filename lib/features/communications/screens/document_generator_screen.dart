import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestor_lds/features/communications/services/citation_service.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/core/widgets/user_autocomplete_field.dart';

class DocumentGeneratorScreen extends StatefulWidget {
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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: "8");
  String _selectedAssignmentType = 'TERCER DISCURSO';

  late String _selectedLeader;

  bool _isMale = false;
  String? _selectedMemberPhone;
  late String _jurisdiction;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dateController.text = DateFormat('yyyy-MM-dd').format(_nextSunday());
    _timeController.text = "10:30 de la mañana";

    _jurisdiction = widget.isStakeMode
        ? (widget.currentUser.ward.toLowerCase() == 'estaca' ? 'Estaca Jerusalén' : widget.currentUser.ward)
        : widget.currentUser.ward;

    _selectedLeader = widget.isStakeMode ? 'PRESIDENTE DE ESTACA' : 'OBISPO';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _topicController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  DateTime _nextSunday() {
    final now = DateTime.now();
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) daysUntilSunday += 7;
    return now.add(Duration(days: daysUntilSunday));
  }

  String _getFormattedUnit() {
    if (widget.isStakeMode) {
      return _jurisdiction.toLowerCase().contains('estaca') ? _jurisdiction : 'Estaca $_jurisdiction';
    }
    return _jurisdiction.toLowerCase().contains('barrio') ? _jurisdiction : 'Barrio $_jurisdiction';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isStakeMode ? 'Comunicaciones de Estaca' : 'Comunicaciones Oficiales'),
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

          const Text('Detalles de la Asignación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Tipo de Asignación', border: OutlineInputBorder(), isDense: true),
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
              decoration: const InputDecoration(labelText: 'Tema Asignado', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Tiempo Estimado (minutos)', border: OutlineInputBorder(), isDense: true),
              keyboardType: TextInputType.number,
            ),
          ],

          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleWhatsAppAction(isInterview: false),
                  icon: const Icon(Icons.message, color: Color(0xFF25D366)),
                  label: Text(_selectedMemberPhone != null ? 'Enviar WA' : 'Copiar WA', style: const TextStyle(color: Color(0xFF25D366))),
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
                  label: const Text('PDF Oficial'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22539A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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

          const Text('Detalles de la Entrevista', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Líder Entrevistador', border: OutlineInputBorder(), isDense: true),
            value: _selectedLeader,
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
                  onPressed: () => _handleWhatsAppAction(isInterview: true),
                  icon: const Icon(Icons.message, color: Color(0xFF25D366)),
                  label: Text(_selectedMemberPhone != null ? 'Enviar WA' : 'Copiar WA', style: const TextStyle(color: Color(0xFF25D366))),
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
                  label: const Text('PDF Oficial'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
          wardFilter: widget.isStakeMode ? null : widget.currentUser.ward,
          onUserSelected: (user) {
            setState(() {
              _isMale = user.gender == 'M';
              _selectedMemberPhone = user.phone;
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
            const Text('Tratamiento: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_month), isDense: true),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(_dateController.text),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _dateController.text = DateFormat('yyyy-MM-dd').format(picked));
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time), hintText: '10:30 AM', isDense: true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _buildAssignmentMessage() {
    final parsedDate = DateTime.parse(_dateController.text);
    final rawDate = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(parsedDate);
    final date = rawDate.isNotEmpty ? "${rawDate[0].toUpperCase()}${rawDate.substring(1)}" : rawDate;

    final isTalk = _selectedAssignmentType.contains('DISCURSO');
    final prefix = _isMale ? 'Estimado Hermano' : 'Estimada Hermana';
    final articulo = (_selectedAssignmentType.toUpperCase().contains('ORACION') || _selectedAssignmentType.toUpperCase().contains('ORACIÓN')) ? 'la ' : 'el ';

    final unitLabel = _getFormattedUnit();
    final leadershipTitle = widget.isStakeMode ? 'Presidencia de la $unitLabel' : 'Obispado del $unitLabel';
    final signatureTitle = widget.isStakeMode ? 'Presidencia de Estaca' : 'Obispado del $unitLabel';

    String message = "*$prefix: ${_nameController.text.trim()}*\n\n";
    message += "Le extendemos un cordial saludo como $leadershipTitle, esperando que se encuentre gozando de las bendiciones de nuestro Padre Celestial. 👋\n\n";
    message += "En esta ocasión nos complace extenderle una cordial invitación para participar en nuestra reunión general con $articulo *${_selectedAssignmentType.toUpperCase()}* el día *$date* a las *${_timeController.text}* en nuestro centro de reuniones.\n\n";

    if (isTalk) {
      message += "📖 Tema asignado: *${_topicController.text.trim()}*\n";
      message += "⏳ Tiempo sugerido: *${_durationController.text} minutos*\n\n";
    }

    message += "Le solicitamos estar 10 minutos antes del inicio de la reunión para sentarse en el estrado.\n\n";

    if (isTalk) {
      message += "Rogamos que el Espíritu del Señor le inspire en la preparación de su mensaje para edificación mutua en la casa de Dios.\n\n";
    }

    message += "Agradecemos profundamente su servicio y devoción al Salvador. 🙏\n\n";
    message += "Con aprecio fraternal,\n*$signatureTitle*";
    return message;
  }

  String _buildInterviewMessage() {
    final parsedDate = DateTime.parse(_dateController.text);
    final rawDate = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(parsedDate);
    final date = rawDate.isNotEmpty ? "${rawDate[0].toUpperCase()}${rawDate.substring(1)}" : rawDate;

    final prefix = _isMale ? 'Estimado Hermano' : 'Estimada Hermana';
    final unitLabel = _getFormattedUnit();
    final leadershipTitle = widget.isStakeMode ? 'Presidencia de la $unitLabel' : 'Obispado del $unitLabel';
    final signatureTitle = widget.isStakeMode ? 'Presidencia de Estaca' : 'Obispado del $unitLabel';

    String message = "*$prefix: ${_nameController.text.trim()}*\n\n";
    message += "Le extendemos un cordial saludo como $leadershipTitle, esperando que las bendiciones del Señor acompañen a usted y su hogar. 👋\n\n";
    message += "Por medio de la presente deseamos invitarle a una entrevista con el *$_selectedLeader*, la cual se llevará a cabo el día *$date* a las *${_timeController.text}* en nuestro centro de reuniones (Oficina de liderazgo).\n\n";
    message += "Agradecemos de antemano su puntualidad y disposición. Si tuviera algún inconveniente con el horario, por favor comuníquese con nosotros.\n\n";
    message += "Con aprecio fraternal,\n*$signatureTitle*";
    return message;
  }

  Future<void> _handleWhatsAppAction({required bool isInterview}) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona o ingresa el nombre del miembro')));
      return;
    }

    final message = isInterview ? _buildInterviewMessage() : _buildAssignmentMessage();
    Clipboard.setData(ClipboardData(text: message));

    if (_selectedMemberPhone != null && _selectedMemberPhone!.trim().isNotEmpty) {
      String cleanPhone = _selectedMemberPhone!.replaceAll(RegExp(r'[^0-9]'), '');
      if (!cleanPhone.startsWith('51') && cleanPhone.length == 9) {
        cleanPhone = '51$cleanPhone';
      }

      final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Mensaje copiado al portapapeles'), backgroundColor: Colors.green),
      );
    }
  }

  void _generateAssignmentPdf() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa el nombre del miembro')));
      return;
    }
    await _citationService.generateSacramentAssignment(
      name: _nameController.text.trim(),
      isMale: _isMale,
      assignmentType: _selectedAssignmentType,
      assignmentDate: DateTime.parse(_dateController.text),
      time: _timeController.text.trim(),
      topic: _selectedAssignmentType.contains('DISCURSO') ? _topicController.text.trim() : null,
      duration: _durationController.text.trim(),
      jurisdiction: _jurisdiction,
      isStakeMode: widget.isStakeMode,
    );
  }

  void _generateInterviewPdf() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa el nombre del miembro')));
      return;
    }
    await _citationService.generateInterviewCitation(
      name: _nameController.text.trim(),
      isMale: _isMale,
      leaderRole: _selectedLeader,
      date: DateTime.parse(_dateController.text),
      time: _timeController.text.trim(),
      jurisdiction: _jurisdiction,
      isStakeMode: widget.isStakeMode,
    );
  }
}