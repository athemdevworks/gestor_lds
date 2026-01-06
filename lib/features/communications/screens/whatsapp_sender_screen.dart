import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppSenderScreen extends StatefulWidget {
  const WhatsAppSenderScreen({super.key});

  @override
  State<WhatsAppSenderScreen> createState() => _WhatsAppSenderScreenState();
}

class _WhatsAppSenderScreenState extends State<WhatsAppSenderScreen> {
  // Opciones de plantillas
  final List<String> _messageTypes = [
    'Entrevista (Renovación)',
    'Entrevista (General)',
    'Asignación Discurso',
    'Asignación Oración',
    'Recordatorio Reunión',
  ];

  String _selectedType = 'Entrevista (Renovación)';

  // Controladores de Texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // --- NUEVOS CONTROLADORES PARA DISCURSO ---
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  // ------------------------------------------

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  String _previewMessage = '';
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _updatePreview();
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _topicController.dispose(); // No olvidar limpiar
    _durationController.dispose(); // No olvidar limpiar
    super.dispose();
  }

  // Genera el texto basado en la selección
  void _updatePreview() {
    final name = _nameController.text.trim().isEmpty ? '[Nombre]' : _nameController.text.trim();

    // Fecha con formato completo: "domingo 7 de enero de 2026"
    final date = DateFormat("EEEE d 'de' MMMM 'de' y", 'es_ES').format(_selectedDate);
    final time = _selectedTime.format(context);

    // Variables para discurso
    final topic = _topicController.text.trim().isEmpty ? '[Tema]' : _topicController.text.trim();
    final duration = _durationController.text.trim().isEmpty ? '[Tiempo]' : _durationController.text.trim();

    setState(() {
      switch (_selectedType) {
        case 'Entrevista (Renovación)':
          _previewMessage = "Hola $name, esperamos que estés muy bien. \n\nEl Obispado desea invitarte a una breve entrevista para la renovación de tu recomendación para el templo, el día *$date* a las *$time* en la oficina del Barrio. \n\n¿Podrías confirmarnos tu asistencia?";
          break;

        case 'Entrevista (General)':
          _previewMessage = "Hola $name. El Obispo quisiera reunirse contigo brevemente este *$date* a las *$time* en su oficina. \n\nPor favor, avísanos si este horario funciona para ti.";
          break;

        case 'Asignación Discurso':
          _previewMessage = "Estimado(a) Hermano(a): *$name*\n\n"
              "Le extendemos un cordial saludo como Obispado del Barrio Nuevo Trujillo, esperando que se encuentre gozando de las bendiciones y oportunidades que nuestro Padre Celestial derrama sobre las familias de todos sus hijos e hijas fieles a Su Obra.\n\n"
              "En esta ocasión nos complace extenderle una cordial invitación para participar en nuestra reunión sacramental con un *DISCURSO* el día *$date* en la capilla Nuevo Trujillo. El tema asignado para esta ocasión es: *“$topic”*. Tendrá un tiempo estimado no mayor a *$duration min*.\n\n"
              "Rogamos que el espíritu del Señor le inspire en la preparación de su discurso y así todos podamos ser edificados en la casa de Dios, el prepararse diligentemente le traerá muchas bendiciones al esforzarse por vivir lo que aprenda.\n\n"
              "Le agradecemos profundamente por su dedicado y genuino servicio al Salvador. Le agradecemos, le recordamos y le admiramos por su fe y sus humildes oraciones.\n\n"
              "Con Amor,\n\n"
              "Obispado Nuevo Trujillo";
          break;

        case 'Asignación Oración':
          _previewMessage = "Hola $name. Nos gustaría invitarte a ofrecer una oración en la reunión sacramental del *$date*. \n\n¿Cuentas con disponibilidad?";
          break;

        case 'Recordatorio Reunión':
          _previewMessage = "Hola $name, te recordamos nuestra reunión de Consejo este *$date* a las *$time*. ¡Te esperamos!";
          break;

        default:
          _previewMessage = "";
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updatePreview();
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _updatePreview();
      });
    }
  }

  Future<void> _sendWhatsApp() async {
    final String message = Uri.encodeComponent(_previewMessage);
    final String phone = _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    final Uri whatsappUrl = phone.isNotEmpty
        ? Uri.parse("https://wa.me/$phone?text=$message")
        : Uri.parse("https://wa.me/?text=$message");

    try {
      if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al abrir WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF164772);

    return Scaffold(
      appBar: AppBar(title: const Text('Generar Mensaje')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. CONFIGURACIÓN ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Configuración de Cita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Tipo de Mensaje', border: OutlineInputBorder()),
                      items: _messageTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedType = val!;
                          _updatePreview();
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Nombre
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre del Miembro', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                      onChanged: (_) => _updatePreview(),
                    ),
                    const SizedBox(height: 15),

                    // --- CAMPOS DINÁMICOS (SOLO PARA DISCURSOS) ---
                    if (_selectedType == 'Asignación Discurso') ...[
                      TextFormField(
                        controller: _topicController,
                        decoration: const InputDecoration(
                            labelText: 'Tema del Discurso',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.topic),
                            hintText: 'Ej: La Fe en Jesucristo'
                        ),
                        onChanged: (_) => _updatePreview(),
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                            labelText: 'Tiempo de Duración',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
                            hintText: 'Ej: 5 a 7 minutos'
                        ),
                        onChanged: (_) => _updatePreview(),
                      ),
                      const SizedBox(height: 15),
                    ],
                    // ---------------------------------------------

                    // Teléfono
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Celular (Opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                          helperText: 'Déjalo vacío para elegir contacto en WhatsApp'
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // --- 2. FECHA Y HORA ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('EEE d MMM', 'es_ES').format(_selectedDate)),
                    onPressed: () => _selectDate(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.white,
                      foregroundColor: brandBlue,
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                    onPressed: () => _selectTime(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.white,
                      foregroundColor: brandBlue,
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- 3. PREVISUALIZACIÓN ---
            const Text('Vista Previa del Mensaje:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCF8C6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
              ),
              child: Text(
                _previewMessage,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 30),

            // --- 4. BOTÓN DE ENVÍO ---
            ElevatedButton.icon(
              onPressed: _sendWhatsApp,
              icon: const Icon(Icons.send),
              label: const Text('Enviar por WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}