import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gestor_lds/core/constants/wards_list.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';

class FamilyHistoryTempleScreen extends StatefulWidget {
  // 🚀 RECIBIMOS LOS MANDOS DIRECTOS DESDE EL HUB DE HISTORIA FAMILIAR
  final bool isStakeMode;
  final UserModel currentUser;

  const FamilyHistoryTempleScreen({
    super.key,
    required this.isStakeMode,
    required this.currentUser,
  });

  @override
  State<FamilyHistoryTempleScreen> createState() => _FamilyHistoryTempleScreenState();
}

class _FamilyHistoryTempleScreenState extends State<FamilyHistoryTempleScreen> {
  static const Color _brandBlue = Color(0xFF22539A);

  // Filtros del panel
  String _barrioFiltro = 'Todos';
  DocumentSnapshot? _selectedTrip; // Viaje seleccionado para ver el detalle de asignación de asientos

  @override
  void initState() {
    super.initState();
    // 🚀 INICIALIZACIÓN CON SENSOR DE SOMBRERO EN VIVO
    _barrioFiltro = widget.isStakeMode ? 'Todos' : widget.currentUser.ward;
  }

  @override
  Widget build(BuildContext context) {
    final bool esAdminEstaca = widget.isStakeMode;

    // Regla de Permisos Eclesiásticos vinculada al usuario inyectado
    final String orgUsuario = widget.currentUser.organization ?? '';
    final bool esLiderEstaca = widget.currentUser.role == 'lider_estaca' ||
        widget.currentUser.role == 'presidencia_estaca' ||
        widget.currentUser.role == 'admin';

    final bool tienePermisoGestion = esLiderEstaca ||
        widget.currentUser.role == 'obispado' ||
        orgUsuario == 'Quórum de Élderes' ||
        orgUsuario == 'Sociedad de Socorro';

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        title: Text(_selectedTrip == null ? 'Caravanas y Viajes al Templo' : 'Logística de Asientos', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _selectedTrip != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedTrip = null))
            : null,
      ),
      body: _selectedTrip == null
          ? _buildTripsListTab(esAdminEstaca, tienePermisoGestion)
          : _buildTripDetailView(tienePermisoGestion),
      floatingActionButton: _selectedTrip == null && tienePermisoGestion
          ? FloatingActionButton.extended(
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.calendar_month),
        label: const Text('Programar Caravana', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showCreateTripDialog(context, esAdminEstaca),
      )
          : null,
    );
  }

  // =========================================================================
  // 📋 VISTA 1: LISTADO DE CARAVANAS PROGRAMADAS
  // =========================================================================
  Widget _buildTripsListTab(bool esAdminEstaca, bool tienePermisoGestion) {
    Query queryTrips = FirebaseFirestore.instance.collection('temple_trips').orderBy('date', descending: false);

    if (_barrioFiltro != 'Todos') {
      queryTrips = queryTrips.where('ward', isEqualTo: _barrioFiltro);
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            // 🚀 ESCUDO DE COINCIDENCIA: Sincroniza valor exacto contra el menú
            value: esAdminEstaca ? _barrioFiltro : widget.currentUser.ward,
            decoration: InputDecoration(labelText: 'Filtrar por Barrio', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), isDense: true, fillColor: esAdminEstaca ? Colors.white : Colors.grey.shade100, filled: !esAdminEstaca),
            items: esAdminEstaca
                ? ['Todos', ...kWardsList].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList()
                : [widget.currentUser.ward].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: esAdminEstaca ? (val) => setState(() => _barrioFiltro = val!) : null,
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: queryTrips.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_bus_filled, size: 70, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text('No hay caravanas al templo programadas actualmente.', style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
                    ],
                  ),
                );
              }

              final viajes = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: viajes.length,
                itemBuilder: (context, index) {
                  var trip = viajes[index];
                  var data = trip.data() as Map<String, dynamic>;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(backgroundColor: _brandBlue.withOpacity(0.1), child: const Icon(Icons.church, color: _brandBlue)),
                      title: Text(data['title'] ?? 'Viaje al Templo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text('📅 Fecha: ${data['date']}\n🏢 Organiza: ${data['ward']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3)),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => setState(() => _selectedTrip = trip),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 🚌 VISTA 2: DETALLE INTERACTIVO DEL VIAJE (LOGÍSTICA DE PASAJEROS)
  // =========================================================================
  Widget _buildTripDetailView(bool tienePermisoGestion) {
    var tripData = _selectedTrip!.data() as Map<String, dynamic>;
    String tripId = _selectedTrip!.id;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('temple_trips')
          .doc(tripId)
          .collection('passengers')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final pasajerosDocs = snapshot.hasData ? snapshot.data!.docs : [];
        List<String> transportes = ['Bus Principal 🚌', 'Bus Adicional 🚌', 'Movilidad Particular A 🚗', 'Movilidad Particular B 🚗', 'Lista de Espera ⏳'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tripData['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Corte de control logístico. Total inscritos: ${pasajerosDocs.length} hermanos.', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  if (tienePermisoGestion) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Agregar Pasajero a la Caravana', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () => _showAddPassengerDialog(context, tripId, tripData['ward'], transportes),
                    )
                  ]
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: transportes.length,
                itemBuilder: (context, index) {
                  String vehiculo = transportes[index];
                  var pasajerosEnVehiculo = pasajerosDocs.where((doc) => (doc.data() as Map<String, dynamic>)['vehicle'] == vehiculo).toList();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      leading: Icon(vehiculo.contains('Bus') ? Icons.directions_bus : (vehiculo.contains('Lista') ? Icons.hourglass_top : Icons.directions_car), color: _brandBlue),
                      title: Text(vehiculo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text('Pasajeros asignados: ${pasajerosEnVehiculo.length}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      children: [
                        if (pasajerosEnVehiculo.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('No hay pasajeros asignados a esta unidad.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ),
                        ...pasajerosEnVehiculo.map((pasajeroDoc) {
                          var pData = pasajeroDoc.data() as Map<String, dynamic>;
                          return ListTile(
                            dense: true,
                            title: Text(pData['passengerName'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('Barrio: ${pData['passengerWard']} • Registrado por: ${pData['addedByName']}'),
                            trailing: tienePermisoGestion
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.compare_arrows, color: Colors.blue),
                                  tooltip: 'Mover de unidad',
                                  onPressed: () => _showReassignVehicleDialog(context, tripId, pasajeroDoc.id, vehiculo, transportes),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Remover del viaje',
                                  onPressed: () => pasajeroDoc.reference.delete(),
                                ),
                              ],
                            )
                                : null,
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        );
      },
    );
  }

  // =========================================================================
  // 🚀 DIÁLOGOS DE CONTROL Y MÉTODOS AUXILIARES
  // =========================================================================

  void _showCreateTripDialog(BuildContext context, bool esAdminEstaca) {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();

    // 🚀 ESCUDO ANTI-CRASH: Si el filtro de estaca dice 'Todos', arrancamos la caravana como 'Estaca Completa' por defecto
    String targetWard = esAdminEstaca
        ? (_barrioFiltro == 'Todos' ? 'Estaca Completa' : _barrioFiltro)
        : widget.currentUser.ward;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Programar Nueva Caravana', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Nombre de la Caravana (Ej: Caravana de Estaca)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Fecha (Ej: Sábado 25 de Julio)', border: OutlineInputBorder(), hintText: 'DD/MM/AAAA')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: targetWard,
              decoration: const InputDecoration(labelText: 'Organiza', border: OutlineInputBorder()),
              items: esAdminEstaca
                  ? ['Estaca Completa', ...kWardsList].map((w) => DropdownMenuItem(value: w, child: Text(w))).toList()
                  : [targetWard].map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
              onChanged: esAdminEstaca ? (val) => targetWard = val! : null,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            onPressed: () async {
              if (titleCtrl.text.isEmpty || dateCtrl.text.isEmpty) return;
              await FirebaseFirestore.instance.collection('temple_trips').add({
                'title': titleCtrl.text.trim(),
                'date': dateCtrl.text.trim(),
                'ward': targetWard,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Crear Caravana'),
          )
        ],
      ),
    );
  }

  void _showAddPassengerDialog(BuildContext context, String tripId, String wardTrip, List<String> opcionesVehiculo) {
    String? selectedPassengerId;
    String? selectedPassengerName;
    String? selectedPassengerWard;
    String initialVehicle = opcionesVehiculo.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Añadir Pasajero', style: TextStyle(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setModalState) {
            var queryUsers = FirebaseFirestore.instance.collection('users');
            var streamFuture = (wardTrip == 'Estaca Completa') ? queryUsers.get() : queryUsers.where('ward', isEqualTo: wardTrip).get();

            return FutureBuilder<QuerySnapshot>(
              future: streamFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));

                var members = snapshot.data!.docs;
                members.sort((a, b) => ((a.data() as Map<String, dynamic>)['lastName'] ?? '').compareTo((b.data() as Map<String, dynamic>)['lastName'] ?? ''));

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Autocomplete<QueryDocumentSnapshot>(
                      displayStringForOption: (opt) {
                        var d = opt.data() as Map<String, dynamic>;
                        return '${d['lastName']}, ${d['firstName']} (${d['ward']})';
                      },
                      optionsBuilder: (TextEditingValue textVal) {
                        if (textVal.text.isEmpty) return const Iterable<QueryDocumentSnapshot>.empty();
                        final q = textVal.text.toLowerCase();
                        return members.where((m) {
                          var d = m.data() as Map<String, dynamic>;
                          String full = '${d['firstName']} ${d['lastName']}'.toLowerCase();
                          String rev = '${d['lastName']}, ${d['firstName']}'.toLowerCase();
                          return full.contains(q) || rev.contains(q);
                        });
                      },
                      onSelected: (selection) {
                        var d = selection.data() as Map<String, dynamic>;
                        selectedPassengerId = selection.id;
                        selectedPassengerName = '${d['firstName']} ${d['lastName']}';
                        selectedPassengerWard = d['ward'] ?? '';
                      },
                      fieldViewBuilder: (ctx, controller, node, onSubmit) {
                        return TextField(
                          controller: controller,
                          focusNode: node,
                          decoration: const InputDecoration(labelText: 'Buscar Hermano(a) del Barrio', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: initialVehicle,
                      decoration: const InputDecoration(labelText: 'Asignar Unidad Inicial', border: OutlineInputBorder()),
                      items: opcionesVehiculo.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (val) => initialVehicle = val!,
                    )
                  ],
                );
              },
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brandBlue, foregroundColor: Colors.white),
            onPressed: () async {
              if (selectedPassengerId == null) return;

              await FirebaseFirestore.instance
                  .collection('temple_trips')
                  .doc(tripId)
                  .collection('passengers')
                  .add({
                'passengerId': selectedPassengerId,
                'passengerName': selectedPassengerName,
                'passengerWard': selectedPassengerWard,
                'vehicle': initialVehicle,
                'addedByUid': FirebaseAuth.instance.currentUser?.uid,
                'addedByName': '${widget.currentUser.firstName} ${widget.currentUser.lastName}',
                'timestamp': FieldValue.serverTimestamp(),
              });

              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Confirmar Asiento'),
          )
        ],
      ),
    );
  }

  void _showReassignVehicleDialog(BuildContext context, String tripId, String passengerDocId, String currentVehicle, List<String> opcionesVehiculo) {
    String currentSelection = currentVehicle;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reubicar Pasajero', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: DropdownButtonFormField<String>(
          value: currentSelection,
          decoration: const InputDecoration(labelText: 'Cambiar a la unidad', border: OutlineInputBorder()),
          items: opcionesVehiculo.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (val) => currentSelection = val!,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('temple_trips')
                  .doc(tripId)
                  .collection('passengers')
                  .doc(passengerDocId)
                  .update({'vehicle': currentSelection});
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Mover Pasajero'),
          )
        ],
      ),
    );
  }
}