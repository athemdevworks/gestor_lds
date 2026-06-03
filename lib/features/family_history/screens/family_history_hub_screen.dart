import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/family_history/screens/family_history_temple_screen.dart';
import 'family_history_report_screen.dart';
import 'family_history_screen.dart';
import 'family_history_sos_screen.dart';

class FamilyHistoryHubScreen extends StatefulWidget {
  // 🚀 RECIBIMOS LOS MANDOS DESDE EL HOME_SCREEN
  final bool isStakeMode;
  final UserModel currentUser;

  const FamilyHistoryHubScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser,
  });

  @override
  State<FamilyHistoryHubScreen> createState() => _FamilyHistoryHubScreenState();
}

class _FamilyHistoryHubScreenState extends State<FamilyHistoryHubScreen> {
  final Color _brandBlue = const Color(0xFF22539A);

  @override
  Widget build(BuildContext context) {
    // 🚀 IDENTIFICAMOS LAS CREDENCIALES DINÁMICAS SEGÚN EL SOMBRERO SELECCIONADO
    final bool esAdminEstaca = widget.isStakeMode;
    final String barrioUsuario = widget.isStakeMode ? 'Todos los Barrios' : widget.currentUser.ward;

    // =========================================================================
    // 🛡️ DEFENSA ESTRICTA: Filtros Cruzados (Barrio y Estaca)
    // =========================================================================

    // Convertimos el rol a texto puro para evitar el choque con los Enums
    final String miRol = widget.currentUser.role.toString();

    // 1. Escáner para Líderes de Barrio (Escanea TODA la matriz, no solo el 1ro)
    final bool sirveEnOrgClaveBarrio = widget.currentUser.callingOrganizations?.contains('Cuórum de Élderes') == true ||
        widget.currentUser.callingOrganizations?.contains('Sociedad de Socorro') == true ||
        widget.currentUser.callingOrganizations?.contains('Templo e Historia Familiar') == true;

    final bool esLiderBarrioAutorizado = (miRol == 'lider_barrio' || miRol == 'UserRole.lider_barrio') && sirveEnOrgClaveBarrio;

    // 2. Escáner para Líderes de Estaca (El Nuevo Candado)
    final bool sirveEnOrgClaveEstaca = widget.currentUser.callingOrganizations?.contains('Sumo consejo') == true ||
        widget.currentUser.callingOrganizations?.contains('Sumo Consejo') == true ||
        widget.currentUser.callingOrganizations?.contains('Templo e historia familiar de estaca') == true ||
        widget.currentUser.callingOrganizations?.contains('Templo e Historia Familiar de estaca') == true;

    final bool esLiderEstacaAutorizado = (miRol == 'lider_estaca' || miRol == 'UserRole.lider_estaca') && sirveEnOrgClaveEstaca;

    // 3. Pases VIP Absolutos (Capitanes Generales)
    final bool tienePaseVip = miRol == 'admin' || miRol == 'UserRole.admin' ||
        miRol == 'presidencia_estaca' || miRol == 'UserRole.presidencia_estaca' ||
        miRol == 'obispado' || miRol == 'UserRole.obispado';

    // 4. Permiso Total Final
    final bool tienePermisoGestion = tienePaseVip || esLiderEstacaAutorizado || esLiderBarrioAutorizado;
    // =========================================================================

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: const Text('Templo e Historia Familiar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- BANNER INSPIRACIONAL DINÁMICO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brandBlue, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.family_restroom, color: Colors.white, size: 44),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Obra de Templo e Historia Familiar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          esAdminEstaca
                              ? 'Panel de control y métricas a nivel de Estaca.'
                              : 'Gestión oficial de la obra en el Barrio $barrioUsuario.',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Secciones Disponibles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 1.1)),
            const SizedBox(height: 12),

            // 🚀 SECCIÓN 1: REGISTRAR LOGROS (LA LISTA DE CHECKS)
            _buildModuleCard(
                title: 'Registrar Logros Semanales',
                subtitle: 'Marcar metas individuales alcanzadas por los miembros en FamilySearch.',
                icon: Icons.checklist_rounded,
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => FamilyHistoryScreen(
                            isStakeMode: widget.isStakeMode, // Pasa el estado del switch superior
                            currentUser: widget.currentUser, // Pasa el perfil del usuario logueado
                          )
                      )
                  );
                }
            ),

            // 🚀 SECCIÓN 2: INFORME COMPARATIVO (OCULTO PARA MIEMBROS SIN PERMISO)
            if (tienePermisoGestion)
              _buildModuleCard(
                  title: 'Informe y Métricas Evolutivas',
                  subtitle: 'Análisis comparativo de crecimiento e indicadores mes a mes.',
                  icon: Icons.analytics_rounded,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FamilyHistoryReportScreen(
                              isStakeMode: widget.isStakeMode, // Pasa el estado del switch
                              currentUser: widget.currentUser, // Pasa la ficha del usuario
                            )
                        )
                    );
                  }
              ),

            // 🚀 SECCIÓN 3: VIAJES AL TEMPLO
            _buildModuleCard(
                title: 'Caravanas y Visitas al Templo',
                subtitle: 'Planificación de viajes, reserva de asientos y control de asistencia.',
                icon: Icons.directions_bus_rounded,
                color: Colors.orange.shade800,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FamilyHistoryTempleScreen(
                        isStakeMode: widget.isStakeMode,   // Transmite el switch de Estaca
                        currentUser: widget.currentUser,   // Transmite la ficha del líder
                      ),
                    ),
                  );
                }
            ),

            // 🚀 SECCIÓN 4: CASOS / SOS CONSULTOR
            _buildModuleCard(
                title: 'Bandeja SOS (Asignaciones)',
                subtitle: 'Asignar consultores a hermanos con dificultades específicas.',
                icon: Icons.support_agent_rounded,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FamilyHistorySosScreen(
                        isStakeMode: widget.isStakeMode,   // Transmite el switch de Estaca
                        currentUser: widget.currentUser,   // Transmite el perfil del líder
                      ),
                    ),
                  );
                }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.2)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}