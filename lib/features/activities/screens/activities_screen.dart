import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gestor_lds/features/activities/models/activity_model.dart';
import 'package:gestor_lds/features/activities/services/activity_service.dart';
import 'package:gestor_lds/features/activities/screens/activity_form_screen.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class ActivitiesScreen extends StatefulWidget {
  final UserModel currentUser;
  const ActivitiesScreen({super.key, required this.currentUser});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> with SingleTickerProviderStateMixin {
  final ActivityService _activityService = ActivityService();
  late TabController _tabController;

  // Filtro de alcance rápido
  String _selectedScopeFilter = 'Todas'; // 'Todas', 'Mi Barrio', 'Estaca', 'Liderazgo'

  // Filtros Historial
  DateTime _historyFilterDate = DateTime.now().subtract(const Duration(days: 30));
  String _filterLabel = "Último Mes";

  // 🛡️ Permisos para gestionar actividades (crear/editar/eliminar)
  bool get _canManageActivities =>
      widget.currentUser.role == UserRole.admin ||
          widget.currentUser.role == UserRole.presidencia_estaca ||
          widget.currentUser.role == UserRole.obispado ||
          widget.currentUser.role == UserRole.lider_estaca ||
          widget.currentUser.role == UserRole.lider_barrio;

  // 🛡️ Reconocimiento de líderes para ver actividades privadas de liderazgo
  bool get _isLeader {
    final role = widget.currentUser.role;
    if (role == UserRole.admin ||
        role == UserRole.presidencia_estaca ||
        role == UserRole.obispado ||
        role == UserRole.lider_estaca ||
        role == UserRole.lider_barrio) {
      return true;
    }

    return widget.currentUser.callings?.any((c) {
      final cLower = c.toLowerCase();
      return cLower.contains('secretario') ||
          cLower.contains('sumo consejo') ||
          cLower.contains('consejero');
    }) ??
        false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF22539A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades', style: TextStyle(fontWeight: FontWeight.bold)),
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
      floatingActionButton: _canManageActivities
          ? FloatingActionButton(
        backgroundColor: brandBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivityFormScreen(currentUser: widget.currentUser),
              settings: const RouteSettings(name: '/activity-create'),
            ),
          );
        },
      )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: PRÓXIMAS
          Column(
            children: [
              _buildScopeFilterBar(),
              Expanded(
                child: _buildActivityList(
                  stream: _activityService.getUpcomingActivities(
                    userWard: widget.currentUser.ward,
                    isLeader: _isLeader,
                  ),
                  emptyMsg: "No hay actividades programadas en esta categoría.",
                  isHistory: false,
                  canManage: _canManageActivities,
                ),
              ),
            ],
          ),

          // PESTAÑA 2: HISTORIAL
          Column(
            children: [
              _buildHistoryFilterBar(),
              _buildScopeFilterBar(),
              Expanded(
                child: _buildActivityList(
                  stream: _activityService.getHistoryActivities(
                    _historyFilterDate,
                    userWard: widget.currentUser.ward,
                    isLeader: _isLeader,
                  ),
                  emptyMsg: "No hay actividades pasadas en este rango.",
                  isHistory: true,
                  canManage: _canManageActivities,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- BARRA DE FILTRO POR ALCANCE (TODAS / MI BARRIO / ESTACA / LIDERAZGO) ---
  Widget _buildScopeFilterBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Alcance:  ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
            _buildScopeChip('Todas'),
            const SizedBox(width: 8),
            _buildScopeChip('Mi Barrio'),
            const SizedBox(width: 8),
            _buildScopeChip('Estaca'),
            if (_isLeader) ...[
              const SizedBox(width: 8),
              _buildScopeChip('Liderazgo'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScopeChip(String label) {
    final isSelected = _selectedScopeFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedScopeFilter = label);
      },
      selectedColor: const Color(0xFF22539A).withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF22539A) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: Colors.grey.shade100,
      visualDensity: VisualDensity.compact,
    );
  }

  // --- BARRA DE FECHA HISTÓRICA ---
  Widget _buildHistoryFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.grey.shade200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Viendo: $_filterLabel", style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
          TextButton.icon(
            icon: const Icon(Icons.filter_list, size: 16),
            label: const Text("Rango de Tiempo", style: TextStyle(fontSize: 12)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => Wrap(
                  children: [
                    _filterOption(ctx, 'Último Mes', 30),
                    _filterOption(ctx, 'Últimos 3 Meses', 90),
                    _filterOption(ctx, 'Este Año', 365),
                  ],
                ),
              );
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

  // --- LISTA DE ACTIVIDADES ---
  Widget _buildActivityList({
    required Stream<List<ActivityModel>> stream,
    required String emptyMsg,
    required bool isHistory,
    required bool canManage,
  }) {
    return StreamBuilder<List<ActivityModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allActivities = snapshot.data ?? [];

        // Filtro en memoria por Chip de alcance
        final activities = allActivities.where((a) {
          if (_selectedScopeFilter == 'Mi Barrio') {
            return a.visibility == 'ward' && (a.ward.isEmpty || a.ward == widget.currentUser.ward);
          }
          if (_selectedScopeFilter == 'Estaca') {
            return a.visibility == 'stake' || a.ward.toLowerCase() == 'estaca';
          }
          if (_selectedScopeFilter == 'Liderazgo') {
            return a.visibility == 'leadership';
          }
          return true; // 'Todas'
        }).toList();

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
            return _buildActivityCard(activities[index], isHistory, canManage);
          },
        );
      },
    );
  }

  // --- TARJETA DE ACTIVIDAD ---
  Widget _buildActivityCard(ActivityModel activity, bool isHistory, bool canManage) {
    final bool isStake = activity.visibility == 'stake' || activity.ward.toLowerCase() == 'estaca';
    final bool isLeadership = activity.visibility == 'leadership';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA: Icono, Título, Organización y Badges
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
            subtitle: Row(
              children: [
                Text(
                  activity.organization,
                  style: TextStyle(
                    color: isHistory ? Colors.grey : _getColorForOrg(activity.organization),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _buildBadge(isStake: isStake, isLeadership: isLeadership, ward: activity.ward),
              ],
            ),
            trailing: (!isHistory && canManage)
                ? IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _showOptions(activity))
                : null,
          ),

          // DETALLES DE FECHA, HORA Y LUGAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // DESCRIPCIÓN
          if (activity.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                activity.description,
                style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const Divider(),

          // BOTONES DE ACCIÓN (AGENDAR / COPIAR)
          if (!isHistory)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 20),
                    label: const Text("Agendar"),
                    onPressed: () => _addToCalendar(activity),
                  ),
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

  // Badge indicador de visibilidad
  Widget _buildBadge({required bool isStake, required bool isLeadership, required String ward}) {
    if (isLeadership) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
        child: Text('🔒 Liderazgo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
      );
    }

    if (isStake) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(4)),
        child: Text(
          ward.isNotEmpty && ward.toLowerCase() != 'estaca' ? '🏛️ Estaca ($ward)' : '🏛️ Toda la Estaca',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade800),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
      child: Text('📍 Barrio', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.black87))),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActivityFormScreen(
                    activityToEdit: activity,
                    currentUser: widget.currentUser,
                  ),
                  settings: const RouteSettings(name: '/activity-edit'),
                ),
              );
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

  void _addToCalendar(ActivityModel activity) async {
    DateTime startDate = activity.date;
    try {
      final timeParts = DateFormat.jm().parse(activity.time);
      startDate = DateTime(activity.date.year, activity.date.month, activity.date.day, timeParts.hour, timeParts.minute);
    } catch (_) {
      startDate = DateTime(activity.date.year, activity.date.month, activity.date.day, 19, 0);
    }

    final DateTime endDate = startDate.add(const Duration(hours: 2));

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
      return;
    }

    final Event event = Event(
      title: activity.title,
      description: activity.description,
      location: activity.location,
      startDate: startDate,
      endDate: endDate,
    );
    Add2Calendar.addEvent2Cal(event);
  }

  void _copyInvite(ActivityModel activity) {
    final text = """
🎉 *INVITACIÓN* 🎉
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
    switch (org) {
      case 'Primaria': return Colors.yellow.shade800;
      case 'Sociedad de Socorro': return Colors.amber.shade600;
      case 'Mujeres Jóvenes': return Colors.pink.shade400;
      case 'Hombres Jóvenes': return Colors.green.shade600;
      case 'Cuórum de Élderes': return Colors.blue.shade700;
      case 'Escuela Dominical': return Colors.teal.shade600;
      case 'Templo e Historia Familiar': return Colors.cyan.shade700;
      case 'Obra Misional': return Colors.orange.shade700;
      case 'Obispado': return Colors.deepPurple.shade700;
      case 'Presidencia de Estaca':
      case 'Estaca': return Colors.indigo.shade700;
      case 'JAS (Jóvenes Adultos Solteros)': return Colors.purple.shade600;
      default: return const Color(0xFF22539A);
    }
  }

  IconData _getIconForOrg(String org) {
    switch (org) {
      case 'Primaria': return Icons.child_care;
      case 'Sociedad de Socorro': return Icons.volunteer_activism;
      case 'Mujeres Jóvenes': return Icons.face_3;
      case 'Hombres Jóvenes': return Icons.face;
      case 'Cuórum de Élderes': return Icons.groups;
      case 'Escuela Dominical': return Icons.menu_book;
      case 'Templo e Historia Familiar': return Icons.account_tree;
      case 'Obra Misional': return Icons.public;
      case 'Obispado': return Icons.account_balance;
      case 'Presidencia de Estaca':
      case 'Estaca': return Icons.apartment;
      case 'JAS (Jóvenes Adultos Solteros)': return Icons.diversity_3;
      default: return Icons.event;
    }
  }
}