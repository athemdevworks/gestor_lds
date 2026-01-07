import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para Clipboard
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart'; // Para detectar kIsWeb
import 'package:url_launcher/url_launcher.dart'; // Para abrir enlaces en Web
import 'package:gestor_lds/features/activities/models/activity_model.dart';
import 'package:gestor_lds/features/activities/services/activity_service.dart';
import 'package:gestor_lds/features/activities/screens/activity_form_screen.dart';

import '../../auth/models/user_model.dart';

class ActivitiesScreen extends StatefulWidget {
  final UserModel currentUser;
  const ActivitiesScreen({super.key, required this.currentUser});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> with SingleTickerProviderStateMixin {
  final ActivityService _activityService = ActivityService();
  late TabController _tabController;

  // Filtros Historial
  DateTime _historyFilterDate = DateTime.now().subtract(const Duration(days: 30));
  String _filterLabel = "Último Mes";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF164772);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades del Barrio'),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'PRÓXIMAS', icon: Icon(Icons.celebration)),
            Tab(text: 'HISTORIAL', icon: Icon(Icons.history)),
          ],
        ),
      ),
      // Si es miembro, ponemos null (no hay botón). Si es líder/obispado, mostramos el botón.
      floatingActionButton: widget.currentUser.role == UserRole.miembro
          ? null
          : FloatingActionButton(
        backgroundColor: brandBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityFormScreen()));
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: PRÓXIMAS
          _buildActivityList(
            stream: _activityService.getUpcomingActivities(),
            emptyMsg: "No hay actividades programadas.\n¡Es hora de planear algo divertido!",
            isHistory: false,
          ),

          // PESTAÑA 2: HISTORIAL
          Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: _buildActivityList(
                  stream: _activityService.getHistoryActivities(_historyFilterDate),
                  emptyMsg: "No hay actividades pasadas en este rango.",
                  isHistory: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // BARRA DE FILTRO (Igual que en Reuniones)
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Viendo: $_filterLabel", style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
          TextButton.icon(
            icon: const Icon(Icons.filter_list, size: 18),
            label: const Text("Filtrar"),
            onPressed: () {
              showModalBottomSheet(context: context, builder: (ctx) => Wrap(
                children: [
                  _filterOption(ctx, 'Último Mes', 30),
                  _filterOption(ctx, 'Últimos 3 Meses', 90),
                  _filterOption(ctx, 'Este Año', 365), // Simplificado
                ],
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _filterOption(BuildContext ctx, String label, int days) {
    return ListTile(
      title: Text(label),
      onTap: () {
        setState(() {
          _historyFilterDate = DateTime.now().subtract(Duration(days: days));
          _filterLabel = label;
        });
        Navigator.pop(ctx);
      },
    );
  }

  // LISTA DE ACTIVIDADES
  Widget _buildActivityList({required Stream<List<ActivityModel>> stream, required String emptyMsg, required bool isHistory}) {
    return StreamBuilder<List<ActivityModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text(emptyMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: activities.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityCard(activity, isHistory);
          },
        );
      },
    );
  }

  // TARJETA DE ACTIVIDAD MEJORADA
  Widget _buildActivityCard(ActivityModel activity, bool isHistory) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // 1. Cabecera (Icono y Título)
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            leading: CircleAvatar(
              backgroundColor: isHistory ? Colors.grey : _getColorForOrg(activity.organization),
              child: Icon(_getIconForOrg(activity.organization), color: Colors.white),
            ),
            title: Text(
              activity.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isHistory ? Colors.grey : Colors.black87,
                decoration: isHistory ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              activity.organization,
              style: TextStyle(color: isHistory ? Colors.grey : _getColorForOrg(activity.organization), fontWeight: FontWeight.bold),
            ),
            // Si es historial O si es un miembro, no mostramos el menú de opciones
            trailing: (isHistory || widget.currentUser.role == UserRole.miembro)
                ? null
                : IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptions(activity),
            ),
          ),

          // 2. Detalles (Fecha, Hora, Lugar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(Icons.calendar_today, DateFormat('EEEE d MMMM', 'es').format(activity.date)),
                      const SizedBox(height: 4),
                      _infoRow(Icons.access_time, activity.time),
                      const SizedBox(height: 4),
                      _infoRow(Icons.location_on, activity.location),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Descripción (si existe)
          if (activity.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  activity.description,
                  style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          const Divider(),

          // 4. BARRA DE ACCIONES RÁPIDAS (Solo si no es historial)
          if (!isHistory)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // BOTÓN AGENDAR
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 20),
                    label: const Text("Agendar"),
                    onPressed: () => _addToCalendar(activity),
                  ),
                  // BOTÓN COPIAR INVITACIÓN
                  TextButton.icon(
                    icon: const Icon(Icons.copy, size: 20),
                    label: const Text("Copiar Info"),
                    onPressed: () => _copyInvite(activity),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ---

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }

  void _showOptions(ActivityModel activity) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Editar Actividad'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityFormScreen(activityToEdit: activity)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Eliminar Actividad'),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(activity);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ActivityModel activity) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar'),
        content: const Text('¿Estás seguro de eliminar esta actividad?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _activityService.deleteActivity(activity.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Lógica de Calendario
  void _addToCalendar(ActivityModel activity) async {
    DateTime startDate = activity.date;
    try {
      final timeParts = DateFormat.jm().parse(activity.time); // Intenta "10:00 AM"
      startDate = DateTime(activity.date.year, activity.date.month, activity.date.day, timeParts.hour, timeParts.minute);
    } catch (_) {
      // Si falla, hora por defecto 7 PM
      startDate = DateTime(activity.date.year, activity.date.month, activity.date.day, 19, 0);
    }

    // Duración por defecto 2 horas
    final DateTime endDate = startDate.add(const Duration(hours: 2));

    // ---------------------------------------------
    // 🌐 LÓGICA WEB: Abrir Google Calendar en pestaña
    // ---------------------------------------------
    if (kIsWeb) {
      final String googleUrl = 'https://www.google.com/calendar/render?action=TEMPLATE'
          '&text=${Uri.encodeComponent(activity.title)}'
          '&details=${Uri.encodeComponent(activity.description)}'
          '&location=${Uri.encodeComponent(activity.location)}'
          '&dates=${DateFormat("yyyyMMdd'T'HHmmss").format(startDate)}/${DateFormat("yyyyMMdd'T'HHmmss").format(endDate)}';

      final Uri uri = Uri.parse(googleUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir el calendario web")));
      }
      return; // ¡Importante! Salimos aquí para no ejecutar código móvil
    }

    // ---------------------------------------------
    // 📱 LÓGICA MÓVIL (Android/iOS): Usar app nativa
    // ---------------------------------------------
    final Event event = Event(
      title: activity.title,
      description: activity.description,
      location: activity.location,
      startDate: startDate,
      endDate: endDate,
    );
    Add2Calendar.addEvent2Cal(event);
  }

  // Lógica de WhatsApp (Copiar texto)
  void _copyInvite(ActivityModel activity) {
    final text = """
🎉 *INVITACIÓN DE BARRIO* 🎉
*${activity.title}*

📅 *Fecha:* ${DateFormat('EEEE d MMMM', 'es').format(activity.date)}
⏰ *Hora:* ${activity.time}
📍 *Lugar:* ${activity.location}

_${activity.description}_

¡Te esperamos!
Organiza: ${activity.organization}
""";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invitación copiada al portapapeles 📋")));
  }

  Color _getColorForOrg(String org) {
    if (org.toLowerCase().contains('primaria')) return Colors.yellow.shade800;
    if (org.toLowerCase().contains('sociedad')) return Colors.amber.shade600;
    if (org.toLowerCase().contains('jóvenes') || org.toLowerCase().contains('hombres')) return Colors.green.shade600;
    if (org.toLowerCase().contains('mujeres')) return Colors.pink.shade400;
    if (org.toLowerCase().contains('barrio')) return Colors.blue.shade800;
    return Colors.indigo;
  }

  IconData _getIconForOrg(String org) {
    if (org.toLowerCase().contains('primaria')) return Icons.child_care;
    if (org.toLowerCase().contains('sociedad')) return Icons.volunteer_activism;
    if (org.toLowerCase().contains('jóvenes')) return Icons.sports_basketball;
    return Icons.event;
  }
}