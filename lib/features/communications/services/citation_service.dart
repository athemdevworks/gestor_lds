import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class CitationService {

  Future<Uint8List> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/logont.png');
      return data.buffer.asUint8List();
    } catch (e) {
      print("⚠️ ADVERTENCIA: No se pudo cargar el logo 'logont.png'. El PDF saldrá sin imagen.");
      print("Error técnico: $e");
      return Uint8List(0);
    }
  }

  // ==========================================
  // 1. ESQUELA DE ASIGNACIÓN (Sacramental / General)
  // ==========================================
  Future<void> generateSacramentAssignment({
    required String name,
    required bool isMale,
    required String assignmentType,
    required DateTime assignmentDate,
    required String time,
    // 🚀 NUEVOS MANDOS MULTIVERSO
    required String jurisdiction,
    required bool isStakeMode,
    String? topic,
    String? duration,
  }) async {
    final pdf = pw.Document();
    final logoBytes = await _loadLogo();
    final image = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // --- FORMATEO DE RAÍZ ---
    final letterDate = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(DateTime.now());
    final meetingDateStr = DateFormat('EEEE d \'de\' MMMM', 'es_ES').format(assignmentDate);

    final isTalk = topic != null && topic.isNotEmpty;
    final prefix = isMale ? 'Estimado Hermano:' : 'Estimada Hermana:';
    final String articulo = (assignmentType.toUpperCase().contains('ORACION') || assignmentType.toUpperCase().contains('ORACIÓN')) ? 'la ' : 'el ';

    // 🚀 LÓGICA DE TEXTOS DINÁMICOS
    final String leadershipTitle = isStakeMode ? 'Presidencia de la Estaca Jerusalén' : 'Obispado del $jurisdiction';
    final String signatureTitle = isStakeMode ? 'Presidencia de Estaca' : 'Obispado del $jurisdiction';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(image, letterDate),
              pw.SizedBox(height: 20),
              // Saludo
              pw.Text(prefix, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 15),
              _buildGreeting(leadershipTitle),
              pw.SizedBox(height: 10),
              // CUERPO DEL TEXTO
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 10),
                  children: [
                    pw.TextSpan(text: 'En esta ocasión nos complace extenderle una cordial invitación para participar en nuestra próxima reunión general con $articulo '),
                    pw.TextSpan(text: assignmentType.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: ' el día $meetingDateStr a las $time en nuestro centro de reuniones. '),
                    if (isTalk) ...[
                      const pw.TextSpan(text: 'El tema asignado para esta ocasión es '),
                      pw.TextSpan(text: '$topic', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: '.'),
                    ]
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                  isTalk
                      ? 'Tendrá un tiempo estimado no mayor a $duration min. Le pedimos estar 10 minutos antes del inicio de la reunión para sentarse en el estrado.'
                      : 'Le pedimos estar 10 minutos antes del inicio de la reunión para sentarse en el estrado.',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.justify
              ),
              pw.SizedBox(height: 10),
              if (isTalk) ...[
                pw.Text('Rogamos que el espíritu del Señor le inspire en la preparación de su mensaje y así todos podamos ser edificados en la casa de Dios. El prepararse diligentemente le traerá muchas bendiciones al esforzarse por vivir lo que aprenda.', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.justify),
                pw.SizedBox(height: 10),
              ],
              _buildClosing(),
              pw.SizedBox(height: 30),
              _buildSignature(signatureTitle),
            ],
          );
        },
      ),
    );
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Asignacion_$safeName.pdf');
  }

  // ==========================================
  // 2. CITACIÓN A ENTREVISTA
  // ==========================================
  Future<void> generateInterviewCitation({
    required String name,
    required bool isMale,
    required String leaderRole,
    required DateTime date,
    required String time,
    // 🚀 NUEVOS MANDOS MULTIVERSO
    required String jurisdiction,
    required bool isStakeMode,
  }) async {
    final pdf = pw.Document();

    final logoBytes = await _loadLogo();
    final image = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final letterDate = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(DateTime.now());
    final interviewDateStr = DateFormat('EEEE d \'de\' MMMM', 'es_ES').format(date);
    final prefix = isMale ? 'Estimado Hermano:' : 'Estimada Hermana:';

    final String leadershipTitle = isStakeMode ? 'Presidencia de la Estaca Jerusalén' : 'Obispado del $jurisdiction';
    final String signatureTitle = isStakeMode ? 'Presidencia de Estaca' : 'Obispado del $jurisdiction';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(image, letterDate),
              pw.SizedBox(height: 20),
              pw.Text(prefix, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 15),
              _buildGreeting(leadershipTitle),
              pw.SizedBox(height: 10),
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 10),
                  children: [
                    const pw.TextSpan(text: 'Por medio de la presente deseamos invitarle a una entrevista con el '),
                    pw.TextSpan(text: leaderRole.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: ', la cual se llevará a cabo el día $interviewDateStr a las $time en nuestro centro de reuniones (Oficina de liderazgo).'),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Text('Agradecemos de antemano su puntualidad y disposición.', style: const pw.TextStyle(fontSize: 10)),
              _buildClosing(),
              pw.SizedBox(height: 30),
              _buildSignature(signatureTitle),
            ],
          );
        },
      ),
    );

    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Citacion_$safeName.pdf');
  }

  // ==========================================
  // WIDGETS AUXILIARES
  // ==========================================

  pw.Widget _buildHeader(pw.MemoryImage? image, String date) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (image != null) pw.Container(width: 150, height: 150, child: pw.Image(image)),
        pw.Spacer(),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Emitido el $date', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 4),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildGreeting(String leadershipTitle) {
    return pw.Text(
      'Le extendemos un cordial saludo como $leadershipTitle, esperando que se encuentre gozando de las bendiciones y oportunidades que nuestro Padre Celestial derrama sobre las familias de todos sus hijos e hijas fieles a Su Obra.',
      style: const pw.TextStyle(fontSize: 10),
      textAlign: pw.TextAlign.justify,
    );
  }

  pw.Widget _buildClosing() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 10),
        pw.Text(
          'Le agradecemos profundamente por su dedicado y genuino servicio al Salvador. Le recordamos y le admiramos por su fe y sus humildes oraciones.',
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.justify,
        ),
      ],
    );
  }

  pw.Widget _buildSignature(String signatureTitle) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text('Con Amor,', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 10),
          pw.Text(signatureTitle.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 5),
        ],
      ),
    );
  }
}