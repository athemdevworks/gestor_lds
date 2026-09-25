import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';

class MeetingBannerWidget extends StatelessWidget {
  final MeetingModel meeting;

  const MeetingBannerWidget({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'es').format(meeting.date);
    const brandBlue = Color(0xFF22539A);

    return Container(
      width: 400, // Ancho fijo ideal para un banner limpio y nítido
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandBlue, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENCABEZADO CON LOGO Y TÍTULO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GESTOR LDS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(
                    meeting.organization ?? meeting.type.displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandBlue),
                  ),
                ],
              ),
              // Logo o icono representativo
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: brandBlue.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.event_note, color: brandBlue, size: 28),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1.5),

          // DATOS GENERALES
          _buildInfoRow(Icons.location_on, 'Unidad', meeting.ward),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_today, 'Fecha', formattedDate),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.access_time, 'Hora', meeting.time),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.security, 'Preside', meeting.presidedBy),
          _buildInfoRow(Icons.person, 'Dirige', meeting.directedBy),

          // DETALLE RÁPIDO
          if (meeting.type == MeetingType.sacramental && meeting.sacramentAgenda != null) ...[
            const Divider(height: 24),
            const Text('PUNTOS PRINCIPALES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            if ((meeting.sacramentAgenda!.openingHymn.isNotEmpty) || (meeting.openingHymn?.isNotEmpty == true))
              Text('• Primer Himno: ${meeting.sacramentAgenda!.openingHymn.isNotEmpty ? meeting.sacramentAgenda!.openingHymn : meeting.openingHymn}', style: const TextStyle(fontSize: 13)),
            if ((meeting.sacramentAgenda!.openingPrayer.isNotEmpty) || (meeting.openingPrayer?.isNotEmpty == true))
              Text('• Primera Oración: ${meeting.sacramentAgenda!.openingPrayer.isNotEmpty ? meeting.sacramentAgenda!.openingPrayer : meeting.openingPrayer}', style: const TextStyle(fontSize: 13)),
            if (meeting.sacramentAgenda!.wardBusiness.isNotEmpty)
              Text('• Asuntos de Barrio: ${meeting.sacramentAgenda!.wardBusiness.length} registros', style: const TextStyle(fontSize: 13)),
          ],

          const SizedBox(height: 20),
          // PIE DE PÁGINA DEL BANNER
          const Center(
            child: Text(
              '📲 Generado con GestorLDS SaaS',
              style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF22539A)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}