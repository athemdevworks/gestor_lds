import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class _CouncilLeaders {
  final String center;
  final String counselor1;
  final String counselor2;

  _CouncilLeaders({
    required this.center,
    required this.counselor1,
    required this.counselor2,
  });
}

class CitationService {
  // ==========================================
  // 🔍 CONSULTA INTELIGENTE DE LIDERAZGO (FIREBASE)
  // ==========================================
  Future<_CouncilLeaders> _fetchCouncilLeaders({
    required String jurisdiction,
    required bool isStakeMode,
  }) async {
    final String cleanUnitName = jurisdiction
        .replaceAll(RegExp(r'^(Barrio|Estaca|Rama)\s+', caseSensitive: false), '')
        .trim();

    String center = isStakeMode ? 'PRESIDENTE DE ESTACA' : 'OBISPO';
    String c1 = 'PRIMER CONSEJERO';
    String c2 = 'SEGUNDO CONSEJERO';

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .where('isActive', isEqualTo: true);

      if (!isStakeMode) {
        query = query.where('ward', isEqualTo: cleanUnitName);
      }

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String firstName = (data['firstName'] ?? '').toString().trim();
        final String lastName = (data['lastName'] ?? '').toString().trim();
        final String fullName = '$firstName $lastName'.toUpperCase();

        final List<dynamic> callings = data['callings'] ?? [];
        final List<dynamic> callingOrgs = data['callingOrganizations'] ?? [];

        for (int i = 0; i < callings.length; i++) {
          final calling = callings[i].toString().toLowerCase();
          final org = i < callingOrgs.length ? callingOrgs[i].toString().toLowerCase() : '';

          if (isStakeMode) {
            bool isStakeOrg = org.contains('estaca') || org.contains('presidencia');
            if (isStakeOrg && calling.contains('presidente') && !calling.contains('consejero') && !calling.contains('socorro') && !calling.contains('hombres') && !calling.contains('primaria') && !calling.contains('jovenes')) {
              center = fullName;
            } else if (isStakeOrg && (calling.contains('primer consejero') || calling.contains('1er consejero') || calling.contains('1° consejero'))) {
              c1 = fullName;
            } else if (isStakeOrg && (calling.contains('segundo consejero') || calling.contains('2do consejero') || calling.contains('2° consejero'))) {
              c2 = fullName;
            }
          } else {
            bool isBishopricOrg = org.contains('obispado') || org.contains('presidencia de rama') || data['organization']?.toString().toLowerCase() == 'obispado';

            if (calling == 'obispo' || calling.contains('presidente de rama') || (isBishopricOrg && calling.contains('obispo') && !calling.contains('consejero'))) {
              center = calling.contains('rama') ? 'PRESIDENTE $fullName' : 'OBISPO $fullName';
            } else if (isBishopricOrg && (calling.contains('primer consejero') || calling.contains('1er consejero') || calling.contains('1° consejero'))) {
              c1 = fullName;
            } else if (isBishopricOrg && (calling.contains('segundo consejero') || calling.contains('2do consejero') || calling.contains('2° consejero'))) {
              c2 = fullName;
            }
          }
        }
      }
    } catch (_) {}

    return _CouncilLeaders(center: center, counselor1: c1, counselor2: c2);
  }

  // ==========================================
  // 1. ESQUELA DE ASIGNACIÓN SACRAMENTAL
  // ==========================================
  Future<void> generateSacramentAssignment({
    required String name,
    required bool isMale,
    required String assignmentType,
    required DateTime assignmentDate,
    required String time,
    required String jurisdiction,
    required bool isStakeMode,
    String? topic,
    String? duration,
    String? leaderCenter,
    String? leader1,
    String? leader2,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final letterDate = DateFormat("d 'de' MMMM 'de' yyyy", 'es_ES').format(DateTime.now());
    final meetingDateStr = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(assignmentDate);

    final isTalk = assignmentType.toUpperCase().contains('DISCURSO');
    final prefix = isMale ? 'Estimado Hermano:' : 'Estimada Hermana:';
    final articulo = (assignmentType.toUpperCase().contains('ORACION') || assignmentType.toUpperCase().contains('ORACIÓN')) ? 'la ' : 'el ';

    final String unitType = isStakeMode ? 'ESTACA' : 'BARRIO';
    final String cleanUnitName = jurisdiction.replaceAll(RegExp(r'^(Barrio|Estaca|Rama)\s+', caseSensitive: false), '').trim();
    final String councilTitle = isStakeMode ? 'Presidencia de la Estaca $cleanUnitName' : 'Obispado del Barrio $cleanUnitName';

    // Todo en mayúsculas garantizado
    final String closingCouncil = (isStakeMode ? 'Presidencia Estaca $cleanUnitName' : 'Obispado $cleanUnitName').toUpperCase();

    final leaders = await _fetchCouncilLeaders(jurisdiction: jurisdiction, isStakeMode: isStakeMode);
    final String nameLeaderCenter = leaderCenter ?? leaders.center;
    final String nameLeader1 = leader1 ?? leaders.counselor1;
    final String nameLeader2 = leader2 ?? leaders.counselor2;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        margin: const pw.EdgeInsets.symmetric(horizontal: 55, vertical: 50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ENCABEZADO FORMAL
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        unitType,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2.0,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        cleanUnitName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      'Trujillo, $letterDate',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.black),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // DESTINATARIO
              pw.Text(prefix, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(name, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.SizedBox(height: 22),

              // SALUDO
              pw.Text(
                'Le extendemos un cordial saludo como $councilTitle, esperando que se encuentre gozando de las bendiciones y oportunidades que nuestro Padre Celestial derrama sobre las familias de todos sus hijos e hijas fieles a Su Obra.',
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.45),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 14),

              // ASIGNACIÓN
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.45, color: PdfColors.black),
                  children: [
                    pw.TextSpan(text: 'En esta ocasión nos complace extenderle una cordial invitación para participar en nuestra reunión sacramental con $articulo'),
                    pw.TextSpan(text: assignmentType.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: ' el día $meetingDateStr a las $time en la capilla $cleanUnitName. '),
                    if (isTalk && topic != null && topic.trim().isNotEmpty) ...[
                      pw.TextSpan(text: 'El tema asignado para esta ocasión es '),
                      pw.TextSpan(text: topic.trim(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: '.'),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // DETALLES Y TIEMPO
              pw.Text(
                isTalk
                    ? 'Tendrá un tiempo estimado no mayor a $duration min. Le pedimos estar 10 minutos antes del inicio de la reunión en el Salón Sacramental para sentarse en el estrado.'
                    : 'Le pedimos estar 10 minutos antes del inicio de la reunión en el Salón Sacramental para sentarse en el estrado.',
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.45),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 14),

              if (isTalk) ...[
                pw.Text(
                  'Rogamos que el espíritu del Señor le inspire en la preparación de su discurso y así todos podamos ser edificados en la casa de Dios, el prepararse diligentemente le traerá muchas bendiciones al esforzarse por vivir lo que aprenda.',
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.45),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 14),
              ],

              pw.Text(
                'Le agradecemos profundamente por su dedicado y genuino servicio al Salvador. Le agradecemos, le recordamos y le admiramos por su fe y sus humildes oraciones.',
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.45),
                textAlign: pw.TextAlign.justify,
              ),

              pw.Spacer(),

              // FIRMAS CENTRADAS (MAYÚSCULAS Y TAMAÑO REDUCIDO)
              pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Con Amor,', style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      closingCouncil,
                      style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      nameLeaderCenter.toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      nameLeader1.toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      nameLeader2.toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),
            ],
          );
        },
      ),
    );

    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Asignacion_$safeName.pdf',
    );
  }

  // ==========================================
  // 2. CITACIÓN OFICIAL A ENTREVISTA
  // ==========================================
  Future<void> generateInterviewCitation({
    required String name,
    required bool isMale,
    required String leaderRole,
    required DateTime date,
    required String time,
    required String jurisdiction,
    required bool isStakeMode,
    String? leaderCenter,
    String? leader1,
    String? leader2,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final letterDate = DateFormat("d 'de' MMMM 'de' yyyy", 'es_ES').format(DateTime.now());
    final interviewDateStr = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(date);
    final prefix = isMale ? 'Estimado Hermano:' : 'Estimada Hermana:';

    final String unitType = isStakeMode ? 'ESTACA' : 'BARRIO';
    final String cleanUnitName = jurisdiction.replaceAll(RegExp(r'^(Barrio|Estaca|Rama)\s+', caseSensitive: false), '').trim();
    final String councilTitle = isStakeMode ? 'Presidencia de la Estaca $cleanUnitName' : 'Obispado del Barrio $cleanUnitName';

    final String closingCouncil = (isStakeMode ? 'Presidencia Estaca $cleanUnitName' : 'Obispado $cleanUnitName').toUpperCase();

    final leaders = await _fetchCouncilLeaders(jurisdiction: jurisdiction, isStakeMode: isStakeMode);
    final String nameLeaderCenter = leaderCenter ?? leaders.center;
    final String nameLeader1 = leader1 ?? leaders.counselor1;
    final String nameLeader2 = leader2 ?? leaders.counselor2;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        margin: const pw.EdgeInsets.symmetric(horizontal: 55, vertical: 50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        unitType,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2.0,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        cleanUnitName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      'Trujillo, $letterDate',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.black),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              pw.Text(prefix, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text(name, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.SizedBox(height: 22),

              pw.Text(
                'Le extendemos un cordial saludo como $councilTitle, esperando que se encuentre gozando de las bendiciones y oportunidades que nuestro Padre Celestial derrama sobre las familias de todos sus hijos e hijas fieles a Su Obra.',
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.45),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 14),

              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.45, color: PdfColors.black),
                  children: [
                    const pw.TextSpan(text: 'Por medio de la presente deseamos invitarle a una entrevista con el '),
                    pw.TextSpan(text: leaderRole.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: ', la cual se llevará a cabo el día $interviewDateStr a las $time en nuestro centro de reuniones (Oficina de liderazgo).'),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              pw.Text(
                'Agradecemos de antemano su puntualidad y disposición. Si tiene algún inconveniente con el horario, por favor avísenos con anticipación.',
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.45),
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 14),

              pw.Text(
                'Le agradecemos profundamente por su dedicado y genuino servicio al Salvador. Le recordamos y le admiramos por su fe y sus humildes oraciones.',
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.45),
                textAlign: pw.TextAlign.justify,
              ),

              pw.Spacer(),

              // FIRMAS CENTRADAS (MAYÚSCULAS Y TAMAÑO REDUCIDO)
              pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Con Amor,', style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      closingCouncil,
                      style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      nameLeaderCenter.toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      nameLeader1.toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      nameLeader2.toUpperCase(),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),
            ],
          );
        },
      ),
    );

    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Citacion_$safeName.pdf',
    );
  }
}