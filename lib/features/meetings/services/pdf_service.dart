import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';
import 'package:printing/printing.dart'; // <--- IMPORTANTE: Para cargar fuentes

class PdfService {

  // Función principal para generar el PDF
  Future<Uint8List> generateAgendaPdf(MeetingModel meeting) async {
    final pdf = pw.Document();

    // 1. CARGAR RECURSOS (Logo y Fuentes)
    final logoData = await rootBundle.load('assets/images/logont.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // --- CORRECCIÓN DE FUENTES (UNICODE) ---
    // Usamos OpenSans que soporta tildes, ñ y viñetas
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fontItalic = await PdfGoogleFonts.openSansItalic();
    // ---------------------------------------

    // Color Azul Intenso para el PDF
    final PdfColor brandColor = PdfColor.fromInt(0xFF164772);

    // 2. RECUPERAR COMPROMISOS
    List<CommitmentModel> meetingCommitments = [];
    try {
      if (meeting.type != MeetingType.sacramental) {
        final snapshot = await FirebaseFirestore.instance
            .collection('commitments')
            .where('meetingId', isEqualTo: meeting.id)
            .get();
        meetingCommitments = snapshot.docs
            .map((doc) => CommitmentModel.fromMap(doc.data(), doc.id))
            .toList();
      }
    } catch (e) {
      print('Error cargando compromisos: $e');
    }

    // 3. CONSTRUCCIÓN DEL CUERPO
    final agendaBody = <pw.Widget>[];

    if (meeting.type == MeetingType.sacramental && meeting.sacramentAgenda != null) {
      // A. AGENDA SACRAMENTAL
      final agenda = meeting.sacramentAgenda!;

      agendaBody.addAll([
        pw.Text('AGENDA SACRAMENTAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),        pw.Divider(),

        if (agenda.welcome != null && agenda.welcome!.isNotEmpty)
          _buildPdfItem('Bienvenida', agenda.welcome!, bold: true),

        _buildPdfItem('Anuncios del Barrio', agenda.announcements),
        // Nombres corregidos
        _buildPdfItem('Primer Himno', agenda.openingHymn),
        _buildPdfItem('Director(a) de Música', agenda.chorister),
        _buildPdfItem('Pianista', agenda.pianist),
        _buildPdfItem('Primera Oración', agenda.openingPrayer),

        if (agenda.wardBusiness.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          // Título de la sección (ya estaba en 10)
          pw.Text('Asuntos del Barrio:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.indigo)),
          pw.SizedBox(height: 2),

          ...agenda.wardBusiness.map((business) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 1. CORRECCIÓN: Bullet con tamaño 10
                  pw.Text("• ", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),

                  pw.Expanded(
                    child: pw.RichText(
                      text: pw.TextSpan(
                        // 2. CORRECCIÓN: Estilo base con tamaño 10 para todo el renglón
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
                        children: [
                          // Tipo (Sostenimiento, Relevo, etc.)
                          pw.TextSpan(text: "${business.type}: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

                          // Nombre de la persona (hereda el tamaño 10 base)
                          pw.TextSpan(text: business.personName),

                          // Llamamiento (lo mantenemos un pelín más pequeño, en 9, o lo subes a 10 si prefieres)
                          if (business.calling != null)
                            pw.TextSpan(
                                text: " (${business.calling})",
                                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)
                            ),
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

        pw.SizedBox(height: 5),
        _buildPdfItem('Himno Sacramental', agenda.sacramentHymn, bold: true),
        pw.SizedBox(height: 15),

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
        pw.Divider(),
        _buildPdfItem('Último Himno', agenda.closingHymn),
        _buildPdfItem('Última Oración', agenda.closingPrayer),
      ]);

    } else if (meeting.agendaItems != null && meeting.agendaItems!.isNotEmpty) {
      // B. AGENDA DE LIDERAZGO
      agendaBody.addAll([
        pw.Text('PUNTOS DE AGENDA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
        pw.Divider(),
        pw.SizedBox(height: 10),

        ...meeting.agendaItems!.map((item) {
          final itemCommitments = meetingCommitments.where((c) => c.agendaItemId == item.id).toList();

          return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 6, height: 6,
                          margin: const pw.EdgeInsets.only(top: 6, right: 8),
                          decoration: pw.BoxDecoration(color: brandColor, shape: pw.BoxShape.circle),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            item.topic,
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                          ),
                        ),
                      ],
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 14, bottom: 4),
                      child: pw.Text(
                        'Presenta: ${item.assignedTo}',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
                      ),
                    ),
                    if (itemCommitments.isNotEmpty)
                      pw.Container(
                          margin: const pw.EdgeInsets.only(left: 14, top: 4),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('ASIGNACIONES / COMPROMISOS:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                                pw.SizedBox(height: 4),
                                ...itemCommitments.map((c) => pw.Row(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Container(
                                        width: 8, height: 8,
                                        margin: const pw.EdgeInsets.only(top: 2, right: 6),
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(color: PdfColors.black, width: 0.5),
                                          color: c.isCompleted ? PdfColors.grey300 : PdfColors.white,
                                        ),
                                      ),
                                      pw.Expanded(
                                          child: pw.RichText(
                                              text: pw.TextSpan(
                                                  style: const pw.TextStyle(fontSize: 10),
                                                  children: [
                                                    pw.TextSpan(text: c.description),
                                                    pw.TextSpan(
                                                        text: ' (Resp: ${c.responsibleName ?? "Asignado"})',
                                                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)
                                                    ),
                                                  ]
                                              )
                                          )
                                      )
                                    ]
                                )).toList()
                              ]
                          )
                      )
                  ]
              )
          );
        }).toList(),
      ]);
    } else {
      agendaBody.add(pw.Text('No hay agenda detallada para esta reunión.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)));
    }

    // 4. CREAR PÁGINA
    pdf.addPage(
        pw.Page(
            pageFormat: PdfPageFormat.a4,
            // --- AQUÍ APLICAMOS LA FUENTE ---
            theme: pw.ThemeData.withFont(
              base: fontRegular,
              bold: fontBold,
              italic: fontItalic,
            ),
            // --------------------------------
            build: (pw.Context context) {
              return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // CABECERA
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('AGENDA DE REUNIÓN',
                                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brandColor)),
                              pw.Text(meeting.type.displayName,
                                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                              if (meeting.organization != null)
                                pw.Text(meeting.organization!,
                                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                            ],
                          ),
                        ),
                        pw.Container(
                          height: 150, // Ajusté el tamaño del logo para que no sea tan invasivo
                          width: 150,
                          child: pw.Image(logoImage),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 10),
                    pw.Divider(color: brandColor, thickness: 2),
                    pw.SizedBox(height: 10),

                    // DETALLES
                    _buildPdfItem('Preside', meeting.presidedBy),
                    _buildPdfItem('Dirige', meeting.directedBy),
                    _buildPdfItem('Fecha', DateFormat('EEEE, d MMMM yyyy', 'es').format(meeting.date), bold: true),
                    _buildPdfItem('Hora', meeting.time, bold: true),

                    pw.SizedBox(height: 20),

                    // CUERPO DE AGENDA
                    ...agendaBody,
                  ]
              );
            }
        )
    );

    return pdf.save();
  }

  pw.Widget _buildPdfItem(String label, String? value, {bool bold = false, PdfColor color = PdfColors.black}) {
    if (value == null || value.isEmpty || value == 'null') return pw.SizedBox.shrink();

    // TAMAÑO DE FUENTE GENERAL PARA LOS ITEMS
    const double fontSize = 10.0;

    return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 4), // Reduje el padding de 5 a 4
        child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 130,
                child: pw.Text(
                    '$label:',
                    style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: color)
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                    value,
                    style: bold
                        ? pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: color)
                        : pw.TextStyle(fontSize: fontSize, color: color)
                ),
              ),
            ]
        )
    );
  }
}