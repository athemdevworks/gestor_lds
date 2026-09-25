import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';

class ModuleSettingsScreen extends StatelessWidget {
  const ModuleSettingsScreen({super.key});

  static const Color _brandBlue = Color(0xFF22539A);
  static const String _stakeEntityName = 'Estaca'; // O el nombre configurado

  // Lista de módulos controlables por licencia
  static const Map<String, String> kSalvationModules = {
    'historiaFamiliarActiva': 'Historia Familiar',
    'obraMisionalActiva': 'Obra Misional',
    'ministracionActiva': 'Ministración',
    'asistenciaActiva': 'Asistencia Nominal',
  };

  static const Map<String, String> kLogisticsModules = {
    'agendasActivas': 'Agendas y Minutas',
    'compromisosActivos': 'Mis Compromisos',
    'calendarioActivo': 'Calendario',
    'entrevistasActivas': 'Entrevistas',
    'actividadesActivas': 'Actividades',
    'presupuestoActivo': 'Presupuestos y Gastos',
  };

  static const Map<String, String> kAdminModules = {
    'directorioActivo': 'Directorio y Membresía',
    'reportesActivos': 'Reportes y Estadísticas',
    'comunicacionesActivas': 'Comunicaciones Oficiales',
  };

  @override
  Widget build(BuildContext context) {
    final List<String> adminEntities = [_stakeEntityName, ...kWardsList];

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: const Text('Gestor de Licencias (SaaS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panel de Control de Licencias por Unidad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  'Habilite o restrinja los módulos disponibles para cada Barrio o la Estaca en tiempo real.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('ward_settings').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final Map<String, Map<String, dynamic>> settingsMap = {};
                if (snapshot.hasData && snapshot.data != null) {
                  for (var doc in snapshot.data!.docs) {
                    settingsMap[doc.id] = doc.data() as Map<String, dynamic>;
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: adminEntities.length,
                  itemBuilder: (context, index) {
                    final entityName = adminEntities[index];
                    final bool isStake = entityName == _stakeEntityName;
                    final wardData = settingsMap[entityName] ?? {};

                    // Verificación si todos los módulos están encendidos
                    final allKeys = [
                      ...kSalvationModules.keys,
                      ...kLogisticsModules.keys,
                      ...kAdminModules.keys,
                    ];
                    final bool isAllActive = allKeys.every((key) => wardData[key] == true);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isStake ? BorderSide(color: Colors.amber.shade700, width: 1.5) : BorderSide.none,
                      ),
                      elevation: 2,
                      child: ExpansionTile(
                        initiallyExpanded: isStake,
                        leading: CircleAvatar(
                          backgroundColor: isStake ? Colors.amber.shade100 : _brandBlue.withOpacity(0.1),
                          child: Icon(
                            isStake ? Icons.account_balance : Icons.location_city,
                            color: isStake ? Colors.amber.shade800 : _brandBlue,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entityName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isStake ? Colors.amber.shade900 : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          isStake ? 'Licencia Global (Estaca)' : 'Licencia Local (Barrio)',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        children: [
                          // 🚀 SWITCH MAESTRO DE ACCIÓN RÁPIDA
                          Container(
                            color: Colors.blue.shade50.withOpacity(0.5),
                            child: SwitchListTile(
                              activeColor: Colors.green.shade700,
                              title: const Text('Plan Completo (Habilitar Todo)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('Activa o desactiva todos los módulos para esta unidad', style: TextStyle(fontSize: 11)),
                              value: isAllActive,
                              onChanged: (val) => _toggleAllModules(entityName, allKeys, val),
                            ),
                          ),
                          const Divider(height: 1),

                          // 🌟 OBRA DE SALVACIÓN
                          _buildCategoryHeader('OBRA DE SALVACIÓN Y EXALTACIÓN'),
                          ...kSalvationModules.entries.map((e) => _buildSwitch(entityName, e.value, e.key, wardData[e.key] ?? false)),

                          // 📅 ORGANIZACIÓN Y LOGÍSTICA
                          _buildCategoryHeader('ORGANIZACIÓN Y LOGÍSTICA'),
                          ...kLogisticsModules.entries.map((e) => _buildSwitch(entityName, e.value, e.key, wardData[e.key] ?? false)),

                          // ⚙️ ADMINISTRACIÓN Y REPORTES
                          _buildCategoryHeader('ADMINISTRACIÓN Y REPORTES'),
                          ...kAdminModules.entries.map((e) => _buildSwitch(entityName, e.value, e.key, wardData[e.key] ?? false)),

                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      width: double.infinity,
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildSwitch(String wardName, String title, String field, bool value) {
    return SwitchListTile(
      activeColor: _brandBlue,
      dense: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      value: value,
      onChanged: (bool val) => _updateWardSetting(wardName, field, val),
    );
  }

  Future<void> _updateWardSetting(String wardName, String field, bool value) async {
    try {
      await FirebaseFirestore.instance.collection('ward_settings').doc(wardName).set({
        field: value,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error actualizando módulo para $wardName: $e');
    }
  }

  Future<void> _toggleAllModules(String wardName, List<String> keys, bool enable) async {
    try {
      final Map<String, dynamic> updates = {
        for (var k in keys) k: enable,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('ward_settings').doc(wardName).set(updates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error en lote para $wardName: $e');
    }
  }
}