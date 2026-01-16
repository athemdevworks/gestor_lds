import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gestor_lds/features/meetings/models/meeting_model.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/meetings/utils/meeting_types.dart';
import 'package:gestor_lds/features/commitments/models/commitment_model.dart';
import 'package:printing/printing.dart';

class PdfService {

  // Color Azul Corporativo (Definido globalmente para consistencia)
  final PdfColor brandColor = PdfColor.fromInt(0xFF164772);

  // Función principal para generar el PDF
  Future<Uint8List> generateAgendaPdf(MeetingModel meeting) async {
    final pdf = pw.Document();

    // 1. CARGAR RECURSOS
    final logoData = await rootBundle.load('assets/images/logont.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fontItalic = await PdfGoogleFonts.openSansItalic();

    // 2. RECUPERAR COMPROMISOS (Si aplica)
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
      // ==========================================
      // A. AGENDA SACRAMENTAL
      // ==========================================
      final agenda = meeting.sacramentAgenda!;

      agendaBody.addAll([
        // TÍTULO PRINCIPAL
        pw.Text('AGENDA SACRAMENTAL',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: brandColor)),
        pw.SizedBox(height: 2),
        pw.Divider(color: brandColor, thickness: 1.5), // Línea principal gruesa
        pw.SizedBox(height: 5),

        if (agenda.welcome != null && agenda.welcome!.isNotEmpty)
          _buildPdfItem('Bienvenida', agenda.welcome),
          _buildPdfItem('Anuncios del Barrio', agenda.announcements),
          _buildPdfItem('Primer Himno', agenda.openingHymn),
          _buildPdfItem('Director(a) de Música', agenda.chorister),
          _buildPdfItem('Pianista', agenda.pianist),
          _buildPdfItem('Primera Oración', agenda.openingPrayer),

        if (agenda.wardBusiness.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text('Asuntos del Barrio:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: brandColor)),
          pw.Divider(color: brandColor, thickness: 1.5),
          pw.SizedBox(height: 2),
          ...agenda.wardBusiness.map((business) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10, bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("• ", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Expanded(
                    child: pw.RichText(
                      text: pw.TextSpan(
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
                        children: [
                          pw.TextSpan(text: "${business.type}: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.TextSpan(text: business.personName),
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
        ],

        // --- SECCIÓN: ASUNTOS DE ESTACA (Añadido) ---
        pw.SizedBox(height: 8),
        pw.Text('Asuntos de Estaca', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandColor)),
        pw.Divider(color: brandColor, thickness: 1.5),
        pw.SizedBox(height: 12),
        // Líneas para escribir (Finas y Azules)
        pw.Divider(color: brandColor, thickness: 0.5),
        pw.SizedBox(height: 12),
        pw.Divider(color: brandColor, thickness: 0.5),
        pw.SizedBox(height: 8),

        // --- SECCIÓN: BENDICIÓN Y REPARTO (Añadido) ---
        pw.Text('Bendición y Reparto de la Santa Cena', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandColor)),
        pw.Divider(color: brandColor, thickness: 1.5),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10),
          child: pw.Text(
            "(Si reparte solo Sacerdocio Aarónico se indica que está a cargo del Sacerdocio Aarónico. De lo contrario, se indica que está a cargo del Sacerdocio del Barrio.)",
            textAlign: pw.TextAlign.left,
            style: pw.TextStyle(
                fontSize: 8,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey800
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        // HIMNO SACRAMENTAL (Continúa normal)
        _buildPdfItem('Himno Sacramental', agenda.sacramentHymn, bold: true),
        pw.SizedBox(height: 2),
        pw.Divider(color: brandColor, thickness: 1.5),
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
                  _buildPdfItem('Himno Especial', agenda.intermediateHymn),
                  pw.SizedBox(height: 8),
                ],

                _buildPdfItem('2do Discursante', agenda.secondSpeakerName ?? 'No asignado', bold: true),
                _buildPdfItem('Tema', agenda.secondSpeakerTopic ?? 'N/A'),
              ]
          ),

        pw.SizedBox(height: 10),
        // Línea final antes del cierre
        pw.Divider(color: brandColor, thickness: 1.5),
        pw.SizedBox(height: 10),

        _buildPdfItem('Último Himno', agenda.closingHymn),
        _buildPdfItem('Última Oración', agenda.closingPrayer),
      ]);

    } else if (meeting.agendaItems != null && meeting.agendaItems!.isNotEmpty) {
      // ==========================================
      // B. AGENDA DE LIDERAZGO
      // ==========================================
      agendaBody.addAll([
        pw.Text('PUNTOS DE AGENDA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brandColor)),
        pw.Divider(color: brandColor, thickness: 1.5),
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

    // 4. CREAR PÁGINA FINAL
    pdf.addPage(
        pw.Page(
            pageFormat: PdfPageFormat.a4,
            theme: pw.ThemeData.withFont(
              base: fontRegular,
              bold: fontBold,
              italic: fontItalic,
            ),
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
                          height: 150, // Logo ajustado
                          width: 150,
                          child: pw.Image(logoImage),
                        ),
                      ],
                    ),

                    pw.Divider(color: brandColor, thickness: 2),

                    // DETALLES GENERALES
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

  // Helper para items normales (Label: Value)
  pw.Widget _buildPdfItem(String label, String? value, {bool bold = false, PdfColor? color}) {
    if (value == null || value.isEmpty || value == 'null') return pw.SizedBox.shrink();
    const double fontSize = 10.0;
    // Si no se especifica color, usa negro
    final textColor = color ?? PdfColors.black;

    return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 130,
                child: pw.Text(
                    '$label:',
                    style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: textColor)
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                    value,
                    style: bold
                        ? pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: textColor)
                        : pw.TextStyle(fontSize: fontSize, color: textColor)
                ),
              ),
            ]
        )
    );
  }

  // Helper para las barras azules de título
  pw.Widget _buildBlueSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
      color: brandColor, // Usa el azul corporativo
      child: pw.Center(
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}