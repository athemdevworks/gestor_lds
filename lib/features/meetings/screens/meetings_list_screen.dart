import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/meetings/screens/meeting_form_screen.dart';
import 'package:gestor_lds/features/meetings/screens/meeting_detail_screen.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/empty_state_widget.dart';

class MeetingsListScreen extends StatefulWidget {
  final UserModel currentUser;

  const MeetingsListScreen({super.key, required this.currentUser});

  @override
  State<MeetingsListScreen> createState() => _MeetingsListScreenState();
}

class _MeetingsListScreenState extends State<MeetingsListScreen> with SingleTickerProviderStateMixin {
  final MeetingService _meetingService = MeetingService();
  late TabController _tabController;

  // Filtros de Historial
  DateTime _historyFilterDate = DateTime.now().subtract(const Duration(days: 30));
  String _filterLabel = "Último Mes";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Menú para cambiar el rango del historial
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_view_month),
              title: const Text('Último Mes'),
              onTap: () {
                setState(() {
                  _historyFilterDate = DateTime.now().subtract(const Duration(days: 30));
                  _filterLabel = "Último Mes";
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: const Text('Últimos 3 Meses'),
              onTap: () {
                setState(() {
                  _historyFilterDate = DateTime.now().subtract(const Duration(days: 90));
                  _filterLabel = "Últimos 3 Meses";
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Este Año'),
              onTap: () {
                setState(() {
                  _historyFilterDate = DateTime(DateTime.now().year, 1, 1);
                  _filterLabel = "Este Año";
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Color corporativo
    const brandBlue = Color(0xFF164772);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda de Reuniones'),
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'PRÓXIMAS', icon: Icon(Icons.event_available)),
            Tab(text: 'HISTORIAL', icon: Icon(Icons.history)),
          ],
        ),
      ),
      // Solo Obispado/Líder pueden crear
      floatingActionButton: widget.currentUser.role != UserRole.miembro
          ? FloatingActionButton(
        backgroundColor: brandBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const MeetingFormScreen(),
              // 👇 AGREGADO: Ruta web para crear una nueva reunión
              settings: const RouteSettings(name: '/meeting-create'),
            ),
          );
        },
      )
          : null,

      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: PRÓXIMAS (Sin filtro de fecha, solo roles)
          _buildFilteredList(
            stream: _meetingService.getUpcomingMeetings(),
            emptyMsg: 'No hay reuniones próximas.',
          ),

          // PESTAÑA 2: HISTORIAL (Con barra de filtro y roles)
          Column(
            children: [
              // Barra Gris de Filtro
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Viendo: $_filterLabel", style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text("Cambiar"),
                      onPressed: _showFilterOptions,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildFilteredList(
                  stream: _meetingService.getHistoryMeetings(_historyFilterDate),
                  emptyMsg: 'No hay historial en este rango.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MÉTODO REUTILIZABLE CON TU LÓGICA DE ROLES ---
  Widget _buildFilteredList({required Stream<List<MeetingModel>> stream, required String emptyMsg}) {
    return StreamBuilder<List<MeetingModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allMeetings = snapshot.data ?? [];

        // -----------------------------------------------------------
        // 🧠 LÓGICA DE FILTRADO POR ROL Y ORGANIZACIÓN
        // -----------------------------------------------------------
        final filteredMeetings = allMeetings.where((meeting) {
          // CASO 1: Obispado y Admin ven TODO
          if (widget.currentUser.role == UserRole.obispado ||
              widget.currentUser.role == UserRole.admin) {
            return true;
          }
          // CASO 2: Líder de Organización
          if (widget.currentUser.role == UserRole.lider) {
            if (meeting.type == MeetingType.wardCouncil) return true;
            if (meeting.organization == widget.currentUser.organization) return true;
          }
          // CASO 3: Miembro (Solo ve las Sacramentales)
          if (widget.currentUser.role == UserRole.miembro) {
            if (meeting.type == MeetingType.sacramental) return true;
          }
          return false;
        }).toList();
        // -----------------------------------------------------------

        if (filteredMeetings.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.event_busy,
            title: 'Sin Agenda',
            message: emptyMsg,
          );
        }

        // TU DISEÑO DE TARJETA ORIGINAL
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80), // Espacio extra abajo para el FAB
          itemCount: filteredMeetings.length,
          itemBuilder: (context, index) {
            final meeting = filteredMeetings[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getColorForType(meeting.type),
                  child: Icon(_getIconForType(meeting.type), color: Colors.white),
                ),
                title: Text(meeting.type.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meeting.organization != null)
                      Text(meeting.organization!, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w500)),

                    Text('${DateFormat('dd/MM/yyyy').format(meeting.date)} - ${meeting.time}'),
                    Text('Preside: ${meeting.presidedBy}'),
                  ],
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MeetingDetailScreen(meeting: meeting),
                      // 👇 AGREGADO: Ruta web para ver el detalle de la reunión
                      settings: const RouteSettings(name: '/meeting-detail'),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Helpers visuales
  Color _getColorForType(MeetingType type) {
    switch (type) {
      case MeetingType.bishopric: return const Color(0xFF164772);
      case MeetingType.wardCouncil: return Colors.orange.shade800;
      case MeetingType.presidency: return Colors.green.shade700;
      case MeetingType.sacramental: return Colors.purple.shade700;
      default: return Colors.grey;
    }
  }

  IconData _getIconForType(MeetingType type) {
    switch (type) {
      case MeetingType.bishopric: return Icons.security;
      case MeetingType.wardCouncil: return Icons.groups;
      case MeetingType.presidency: return Icons.assignment_ind;
      case MeetingType.sacramental: return Icons.home;
      default: return Icons.event;
    }
  }
}