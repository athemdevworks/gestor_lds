import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:flutter/services.dart'; // Necesario para cargar fuentes/imágenes
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';

class PdfService {
  // Función principal para generar el PDF
  Future<Uint8List> generateAgendaPdf(MeetingModel meeting) async {
    final pdf = pw.Document();

    // 1. CARGAR LOGO (Asegúrate que el nombre coincida con tu archivo)
    final logoData = await rootBundle.load('assets/images/logont.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Color Azul Intenso para el PDF
    final PdfColor brandColor = PdfColor.fromInt(0xFF164772);

    // Mapeo condicional para el cuerpo del PDF...
    final agendaBody = <pw.Widget>[];

    if (meeting.type == MeetingType.sacramental && meeting.sacramentAgenda != null) {
      // A. AGENDA SACRAMENTAL (FIJA)
      final agenda = meeting.sacramentAgenda!;

      agendaBody.addAll([
        pw.Text('AGENDA SACRAMENTAL', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
        pw.Divider(),

        // 1. BIENVENIDA (NUEVO)
        if (agenda.welcome != null && agenda.welcome!.isNotEmpty)
          _buildPdfItem('Bienvenida', agenda.welcome!, bold: true),

        // 2. ANUNCIOS
        _buildPdfItem('Anuncios del Barrio', agenda.announcements),

        // 3. APERTURA
        _buildPdfItem('Primer Himno', agenda.openingHymn),
        _buildPdfItem('Director(a) de Música', agenda.chorister),
        _buildPdfItem('Pianista', agenda.pianist),
        _buildPdfItem('Primera Oración', agenda.openingPrayer),

        // 4. ASUNTOS DEL BARRIO (NUEVO - ITERACIÓN)
        if (agenda.wardBusiness.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Text('Asuntos del Barrio:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.indigo)),
          pw.SizedBox(height: 2),
          ...agenda.wardBusiness.map((business) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("• ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Expanded(
                    child: pw.RichText(
                      text: pw.TextSpan(
                        children: [
                          pw.TextSpan(text: "${business.type}: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.TextSpan(text: business.personName),
                          if (business.calling != null)
                            pw.TextSpan(text: " (${business.calling})", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 5),
        ],
        // ---------------------------------------------

        pw.SizedBox(height: 5),

        // 5. SANTA CENA
        _buildPdfItem('Himno Sacramental', agenda.sacramentHymn, bold: true),
        pw.SizedBox(height: 15),

        // LÓGICA DE DISCURSOS / TESTIMONIOS
        if (agenda.isFastAndTestimony)
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: PdfColors.yellow50, borderRadius: pw.BorderRadius.circular(5)),
            child: pw.Text('DOMINGO DE AYUNO Y TESTIMONIO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
          )
        else
          pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Orden de discursos: 1er Discurso -> Himno Intermedio -> 2do Discurso
                _buildPdfItem('1er Discursante', agenda.firstSpeakerName ?? 'No asignado', bold: true),
                _buildPdfItem('Tema', agenda.firstSpeakerTopic ?? 'N/A'),
                pw.SizedBox(height: 8),

                if (agenda.intermediateHymn != null && agenda.intermediateHymn!.isNotEmpty) ...[
                  _buildPdfItem('Himno Especial', agenda.intermediateHymn!, bold: true, color: PdfColors.blueGrey700),
                  pw.SizedBox(height: 8),
                ],

                _buildPdfItem('2do Discursante', agenda.secondSpeakerName ?? 'No asignado', bold: true),
                _buildPdfItem('Tema', agenda.secondSpeakerTopic ?? 'N/A'),
              ]
          ),

        pw.SizedBox(height: 15),

        // CIERRE
        pw.Divider(),
        _buildPdfItem('Último Himno', agenda.closingHymn),
        _buildPdfItem('Última Oración', agenda.closingPrayer),
      ]);

    } else if (meeting.agendaItems != null && meeting.agendaItems!.isNotEmpty) {
      // B. AGENDA DE LIDERAZGO (DINÁMICA)
      agendaBody.addAll([
        pw.Text('PUNTOS DE AGENDA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
        pw.Divider(),
        ...meeting.agendaItems!.map((item) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfItem('Asunto', item.topic, bold: true, color: PdfColors.blue700),
              _buildPdfItem('Responsable', item.assignedTo),
              pw.SizedBox(height: 5),
            ]
        )).toList(),
      ]);
    } else {
      agendaBody.add(pw.Text('No hay agenda detallada para esta reunión.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
    }

    // ------------------------------------------------------------------

    pdf.addPage(
        pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // --- CABECERA CON LOGO ---
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Columna de Textos (Izquierda)
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('AGENDA DE REUNIÓN',
                                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: brandColor)),
                              pw.Text(meeting.type.displayName,
                                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                              if (meeting.organization != null)
                                pw.Text(meeting.organization!,
                                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                            ],
                          ),
                        ),
                        // Logo (Derecha)
                        pw.Container(
                          height: 150, // Ajustado para que no ocupe tanto
                          width: 150,
                          child: pw.Image(logoImage),
                        ),
                      ],
                    ),
                    // -------------------------------

                    pw.SizedBox(height: 10),
                    pw.Divider(color: brandColor, thickness: 2), // Línea azul divisoria
                    pw.SizedBox(height: 10),

                    // DETALLES BÁSICOS (Alineados)
                    _buildPdfItem('Preside', meeting.presidedBy),
                    _buildPdfItem('Dirige', meeting.directedBy),
                    _buildPdfItem('Fecha', DateFormat('EEEE, d MMMM yyyy', 'es').format(meeting.date), bold: true),
                    _buildPdfItem('Hora', meeting.time, bold: true),

                    pw.SizedBox(height: 20),

                    // CUERPO DE LA AGENDA
                    ...agendaBody,
                  ]
              );
            }
        )
    );

    return pdf.save();
  }

  pw.Widget _buildPdfItem(String label, String? value, {bool bold = false, PdfColor color = PdfColors.black}) {
    // Oculta el campo si el valor es nulo o vacío
    if (value == null || value.isEmpty || value == 'null') return pw.SizedBox.shrink();

    return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 130, // Ancho fijo para las etiquetas para que se alineen bonito
                child: pw.Text('$label:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color)),
              ),
              pw.Expanded(
                child: pw.Text(value, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color) : pw.TextStyle(color: color)),
              ),
            ]
        )
    );
  }
}