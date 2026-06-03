import 'package:flutter/material.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/meetings/services/meeting_service.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/meetings/screens/meeting_form_screen.dart';
import 'package:gestor_lds/features/meetings/screens/meeting_detail_screen.dart';
import 'package:intl/intl.dart';

// 🚀 IMPORTAMOS LAS LISTAS GLOBALES PARA LOS FILTROS
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/core/constants/organizations_list.dart';
import '../../../core/widgets/empty_state_widget.dart';

class MeetingsListScreen extends StatefulWidget {
  // 🚀 RECIBIMOS LOS MANDOS DIRECTOS DESDE EL PADRE
  final bool isStakeMode;
  final UserModel currentUser;

  const MeetingsListScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser
  });

  @override
  State<MeetingsListScreen> createState() => _MeetingsListScreenState();
}

class _MeetingsListScreenState extends State<MeetingsListScreen> with SingleTickerProviderStateMixin {
  final MeetingService _meetingService = MeetingService();
  late TabController _tabController;

  // Filtros de Historial
  DateTime _historyFilterDate = DateTime.now().subtract(const Duration(days: 30));
  String _filterLabel = "Último Mes";

  // 🚀 FILTROS DE INTERFAZ MULTIVERSO
  String _barrioFiltro = 'Todos';
  String _orgFiltro = 'Todas';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 🚀 Sincronización de sombrero al arrancar
    _barrioFiltro = widget.isStakeMode ? 'Todos' : widget.currentUser.ward;
  }

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
    const brandBlue = Color(0xFF22539A);
    final UserRole miRol = widget.currentUser.role;

    // =========================================================================
    // 🛡️ DEFENSA ESTRICTA: ¿Quién puede crear nuevas reuniones?
    // =========================================================================
    final bool esLiderEstacaReal = miRol == UserRole.lider_estaca ||
        miRol == UserRole.presidencia_estaca ||
        miRol == UserRole.admin;

    final bool esLiderBarrioReal = miRol == UserRole.lider_barrio ||
        miRol == UserRole.obispado;

    final bool tienePermisoCrear = esLiderEstacaReal || esLiderBarrioReal;
    // =========================================================================

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isStakeMode ? 'Agenda de Estaca' : 'Agenda de Reuniones'),
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
      floatingActionButton: tienePermisoCrear
          ? FloatingActionButton(
        backgroundColor: brandBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MeetingFormScreen(
                isStakeMode: widget.isStakeMode,
                currentUser: widget.currentUser,
              ),
              settings: const RouteSettings(name: '/meeting-create'),
            ),
          );
        },
      )
          : null,

      body: Column(
        children: [
          // =========================================================================
          // 🚀 BARRA DE FILTROS SUPERIOR (MULTIVERSO)
          // =========================================================================
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _barrioFiltro,
                    decoration: InputDecoration(labelText: 'Barrio / Estaca', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true, fillColor: widget.isStakeMode ? Colors.white : Colors.grey.shade100, filled: !widget.isStakeMode),
                    items: widget.isStakeMode
                    // 🚀 NOMBRE OFICIAL ESTACA JERUSALÉN
                        ? ['Todos', 'Estaca Jerusalén', ...kWardsList].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList()
                        : [widget.currentUser.ward].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: widget.isStakeMode ? (val) => setState(() => _barrioFiltro = val!) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _orgFiltro,
                    decoration: InputDecoration(labelText: 'Organización / Tipo', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                    items: ['Todas', 'Reunión Sacramental', 'Consejos', 'Obispados/Presidencias', ...kOrganizationsList]
                        .map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (val) => setState(() => _orgFiltro = val!),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // PESTAÑA 1: PRÓXIMAS
                _buildFilteredList(
                  stream: _meetingService.getUpcomingMeetings(),
                  emptyMsg: 'No hay reuniones próximas con estos filtros.',
                ),

                // PESTAÑA 2: HISTORIAL
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.grey.shade200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Rango: $_filterLabel", style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                          TextButton.icon(
                            icon: const Icon(Icons.date_range, size: 16),
                            label: const Text("Cambiar", style: TextStyle(fontSize: 13)),
                            onPressed: _showFilterOptions,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildFilteredList(
                        stream: _meetingService.getHistoryMeetings(_historyFilterDate),
                        emptyMsg: 'No hay historial en este rango con estos filtros.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MÉTODO REUTILIZABLE CON EMBUDO DOBLE (UI + ROLES) ---
  Widget _buildFilteredList({required Stream<List<MeetingModel>> stream, required String emptyMsg}) {
    return StreamBuilder<List<MeetingModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

        final allMeetings = snapshot.data ?? [];

        final filteredMeetings = allMeetings.where((meeting) {

          // =========================================================
          // 1. FILTROS DE INTERFAZ (Lo que elegiste en los Dropdowns)
          // =========================================================
          if (_barrioFiltro != 'Todos') {
            if (meeting.ward != _barrioFiltro) return false;
          } else if (!widget.isStakeMode) {
            // Si no eres estaca, el "Todos" solo muestra tu barrio y los eventos generales de la estaca
            if (meeting.ward != widget.currentUser.ward && meeting.ward != 'Estaca Jerusalén') return false;
          }

          if (_orgFiltro != 'Todas') {
            if (_orgFiltro == 'Reunión Sacramental' && meeting.type != MeetingType.sacramental) return false;
            if (_orgFiltro == 'Consejos' && meeting.type != MeetingType.wardCouncil && meeting.type != MeetingType.stakeCouncil) return false;
            if (_orgFiltro == 'Obispados/Presidencias' && meeting.type != MeetingType.bishopric && meeting.type != MeetingType.presidency && meeting.type != MeetingType.stakePresidency) return false;

            if (!['Reunión Sacramental', 'Consejos', 'Obispados/Presidencias'].contains(_orgFiltro)) {
              if (meeting.organization != _orgFiltro) return false;
            }
          }

          // =========================================================
          // 2. CANDADOS DE SEGURIDAD (Permisos de Rol Estrictos)
          // =========================================================
          final UserRole miRol = widget.currentUser.role;
          final String miOrg = widget.currentUser.organization ?? '';
          final List<String> misOrgs = widget.currentUser.callingOrganizations ?? [];

          // 🏆 CASO VIP: Obispados, Presidencias de Estaca y Admin
          if (miRol == UserRole.obispado ||
              miRol == UserRole.presidencia_estaca ||
              miRol == UserRole.admin) {
            return true;
          }

          // 🛑 BARRERA ABSOLUTA: Las reuniones confidenciales no las ve nadie más que los VIP.
          if (meeting.type == MeetingType.sacramental ||
              meeting.type == MeetingType.bishopric ||
              meeting.type == MeetingType.stakePresidency ||
              meeting.type == MeetingType.highCouncil ||
              meeting.type == MeetingType.stakeBishopsCouncil ||
              meeting.type == MeetingType.highPriestsQuorum) {
            return false;
          }

          // 🛡️ CASO LÍDERES (Barrio y Estaca)
          if (miRol == UserRole.lider_barrio || miRol == UserRole.lider_estaca) {

            // 1. Ven los Consejos Generales
            if (meeting.type == MeetingType.wardCouncil || meeting.type == MeetingType.stakeCouncil) return true;

            // 2. Consejo de Juventud / Comité Jóvenes Estaca: SOLO Hombres y Mujeres Jóvenes
            if (meeting.type == MeetingType.youthCouncil || meeting.type == MeetingType.stakeYouthLeadership) {
              if (miOrg == 'Mujeres Jóvenes' || miOrg == 'Hombres Jóvenes' ||
                  misOrgs.contains('Mujeres Jóvenes') || misOrgs.contains('Hombres Jóvenes')) {
                return true;
              }
              return false;
            }

            // 3. Comité de Adultos de Estaca: SOLO Soc. Socorro y Élderes
            if (meeting.type == MeetingType.stakeAdultLeadership) {
              if (miOrg == 'Sociedad de Socorro' || miOrg == 'Cuórum de Élderes' ||
                  misOrgs.contains('Sociedad de Socorro') || misOrgs.contains('Cuórum de Élderes')) {
                return true;
              }
              return false;
            }

            // 4. Reuniones de Presidencia u Otras de SU organización específica
            if (meeting.organization != null) {
              if (miOrg == meeting.organization || misOrgs.contains(meeting.organization)) {
                return true;
              }
            }

            // 5. Reuniones y capacitaciones masivas de liderazgo
            if (meeting.type == MeetingType.stakeLeadershipTraining ||
                meeting.type == MeetingType.stakePriesthoodLeadership) {
              return true;
            }
          }

          // 👥 CASO MIEMBROS REGULARES
          // Eventos masivos sin organización privada y Conferencia de Estaca
          if (meeting.type == MeetingType.other ||
              meeting.type == MeetingType.stakeConference ||
              meeting.type == MeetingType.stakePriesthoodGeneral) {
            return true;
          }

          return false;
        }).toList();

        if (filteredMeetings.isEmpty) {
          return EmptyStateWidget(icon: Icons.event_busy, title: 'Sin Agenda', message: emptyMsg);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
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

                    // 🚀 Mostrar qué barrio o estaca organiza la cita
                    if (widget.isStakeMode)
                      Text('📍 ${meeting.ward}', style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold)),

                    Text('${DateFormat('dd/MM/yyyy').format(meeting.date)} - ${meeting.time}'),
                    Text('Preside: ${meeting.presidedBy}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MeetingDetailScreen(
                        meeting: meeting,
                        // 🚀 Pasamos los mandos al detalle
                        isStakeMode: widget.isStakeMode,
                        currentUser: widget.currentUser,
                      ),
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

  // Helpers visuales actualizados
  Color _getColorForType(MeetingType type) {
    switch (type) {
      case MeetingType.bishopric:
      case MeetingType.stakePresidency:
      case MeetingType.highCouncil:
        return const Color(0xFF22539A); // Azul ATHEM
      case MeetingType.wardCouncil:
      case MeetingType.stakeCouncil:
      case MeetingType.stakeBishopsCouncil:
        return Colors.orange.shade800; // Naranja Liderazgo
      case MeetingType.presidency:
      case MeetingType.youthCouncil:
      case MeetingType.stakeAdultLeadership:
      case MeetingType.stakeYouthLeadership:
        return Colors.green.shade700; // Verde Presidencias
      case MeetingType.sacramental:
      case MeetingType.stakeConference:
      case MeetingType.stakePriesthoodGeneral:
        return Colors.purple.shade700; // Morado Eventos Mayores
      default: return Colors.grey;
    }
  }

  IconData _getIconForType(MeetingType type) {
    switch (type) {
      case MeetingType.bishopric:
      case MeetingType.stakePresidency:
      case MeetingType.stakeBishopsCouncil:
        return Icons.security;
      case MeetingType.wardCouncil:
      case MeetingType.stakeCouncil:
      case MeetingType.stakeConference:
        return Icons.groups;
      case MeetingType.presidency:
      case MeetingType.highCouncil:
      case MeetingType.youthCouncil:
        return Icons.assignment_ind;
      case MeetingType.sacramental:
        return Icons.home;
      default: return Icons.event;
    }
  }
}