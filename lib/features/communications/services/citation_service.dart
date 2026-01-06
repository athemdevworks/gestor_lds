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
      return Uint8List(0);
    }
  }

  // ==========================================
  // 1. ESQUELA DE ASIGNACIÓN (Discurso/Oración)
  // ==========================================
  Future<void> generateSacramentAssignment({
    required String name,
    required bool isMale,
    required String assignmentType,
    required DateTime assignmentDate,
    required String time,
    String? topic,
    String? duration,
  }) async {
    final pdf = pw.Document();
    final logoBytes = await _loadLogo();
    final image = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;
    final letterDate = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(DateTime.now());
    final meetingDateStr = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(assignmentDate);

    final isTalk = topic != null && topic.isNotEmpty;
    final prefix = isMale ? 'Estimado Hermano:' : 'Estimada Hermana:';

    // Articulación ("el" Tercer Discurso / "la" Ultima Oración)
    final String articulo = (assignmentType.toUpperCase().contains('ORACION') || assignmentType.toUpperCase().contains('ORACIÓN'))
        ? 'la ' : 'el ';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
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
              _buildGreeting(),
              pw.SizedBox(height: 10),

              // Cuerpo Específico
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 10),
                  children: [
                    pw.TextSpan(text: 'En esta ocasión nos complace extenderle una cordial invitación para participar en nuestra reunión sacramental con $articulo '),
                    pw.TextSpan(text: assignmentType.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: ' el día $meetingDateStr a las $time en la capilla Nuevo Trujillo. '),
                    if (isTalk) ...[
                      const pw.TextSpan(text: 'El tema asignado para esta ocasión es '),
                      pw.TextSpan(text: '$topic', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: '.'),
                    ]
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              if (isTalk)
                pw.Text('Tendrá un tiempo estimado no mayor a $duration min. Le pedimos estar 10 minutos antes del inicio de la reunión en el Salón Sacramental para sentarse en el estrado.', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.justify)
              else
                pw.Text('Le pedimos estar 10 minutos antes del inicio de la reunión en el Salón Sacramental para sentarse en el estrado.', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.justify),

              pw.SizedBox(height: 10),

              if (isTalk) ...[
                pw.Text('Rogamos que el espíritu del Señor le inspire en la preparación de su discurso y así todos podamos ser edificados en la casa de Dios, el prepararse diligentemente le traerá muchas bendiciones al esforzarse por vivir lo que aprenda.', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.justify),
                pw.SizedBox(height: 10),
              ],

              _buildClosing(),
              pw.SizedBox(height: 30),
              _buildSignature(),
            ],
          );
        },
      ),
    );

    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Asignacion_$safeName.pdf');
  }

  // ==========================================
  // 2. CITACIÓN A ENTREVISTA (Nueva)
  // ==========================================
  Future<void> generateInterviewCitation({
    required String name,
    required bool isMale,
    required String leaderRole, // "OBISPO", "CONSEJERO", etc.
    required DateTime date,
    required String time,
  }) async {
    final pdf = pw.Document();
    final logoBytes = await _loadLogo();
    final image = logoBytes.isNotEmpty ? pw.MemoryImage(logoBytes) : null;
    final letterDate = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(DateTime.now());
    final interviewDateStr = DateFormat('EEEE d \'de\' MMMM', 'es_ES').format(date);

    final prefix = isMale ? 'Estimado Hermano:' : 'Estimada Hermana:';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
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
              _buildGreeting(),
              pw.SizedBox(height: 10),

              // Cuerpo Entrevista
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 10),
                  children: [
                    const pw.TextSpan(text: 'Por medio de la presente deseamos invitarle a una entrevista con el '),
                    pw.TextSpan(text: leaderRole.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: ', la cual se llevará a cabo el día '),
                    pw.TextSpan(text: interviewDateStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: ' a las '),
                    pw.TextSpan(text: time, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    const pw.TextSpan(text: ' en la oficina del Obispado de la capilla Nuevo Trujillo.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Text('Agradecemos de antemano su puntualidad y disposición.', style: const pw.TextStyle(fontSize: 10)),

              _buildClosing(),
              pw.SizedBox(height: 30),
              _buildSignature(),
            ],
          );
        },
      ),
    );

    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Citacion_$safeName.pdf');
  }

  // --- Widgets Reutilizables ---
  pw.Widget _buildHeader(pw.MemoryImage? image, String date) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (image != null) pw.Container(width: 150, height: 150, child: pw.Image(image)),
        pw.Spacer(),
        pw.Text('Trujillo, $date', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildGreeting() {
    return pw.Text(
      'Le extendemos un cordial saludo como Obispado del Barrio Nuevo Trujillo, esperando que se encuentre gozando de las bendiciones y oportunidades que nuestro Padre Celestial derrama sobre las familias de todos sus hijos e hijas fieles a Su Obra.',
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
          'Le agradecemos profundamente por su dedicado y genuino servicio al Salvador. Le agradecemos, le recordamos y le admiramos por su fe y sus humildes oraciones.',
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.justify,
        ),
      ],
    );
  }

  pw.Widget _buildSignature() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text('Con Amor,', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 10),
          pw.Text('Obispado Nuevo Trujillo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 5),
          pw.Text('OBISPO LEOPOLDO GARCIA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('ROBERT MENDOZA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.Text('CESAR VALDIVIA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        ],
      ),
    );
  }
}