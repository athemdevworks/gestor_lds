import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:gestor_lds/features/budget/models/budget_model.dart';
import 'package:printing/printing.dart';

class BudgetPdfService {

  // Color Corporativo
  final PdfColor brandColor = PdfColor.fromInt(0xFF164772);

  Future<Uint8List> generateActivityBudgetPdf(ActivityBudgetModel budget) async {
    final pdf = pw.Document();

    // Cargar fuentes (Importante para tildes y ñ)
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // Cargar Logo (Opcional, si quieres que salga arriba)
    final logoData = await rootBundle.load('assets/images/logont.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. CABECERA
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    height: 60,
                    width: 60,
                    child: pw.Image(logoImage),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ESTACA TRUJILLO PERU JERUSALEN', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('BARRIO NUEVO TRUJILLO', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandColor)),
                      pw.SizedBox(height: 5),
                      pw.Text('PRESUPUESTO DE ACTIVIDADES', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // 2. DATOS GENERALES (Cuadrícula)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: brandColor, width: 1),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  children: [
                    _buildDataRow('Organización:', budget.organization, 'Fecha Actividad:', DateFormat('dd/MM/yyyy').format(budget.activityDate)),
                    pw.SizedBox(height: 5),
                    _buildDataRow('Líder Responsable:', budget.responsibleLeader, 'Fecha Presentación:', DateFormat('dd/MM/yyyy').format(budget.presentationDate)),
                    pw.SizedBox(height: 5),
                    _buildDataRow('Nombre Actividad:', budget.activityName, 'Solicitante:', budget.applicantName),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Propósito: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.Expanded(child: pw.Text(budget.activityPurpose, style: const pw.TextStyle(fontSize: 10))),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // 3. TABLA DE GASTOS
              pw.Text('DESCRIPCIÓN DE GASTOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: brandColor)),
              pw.SizedBox(height: 5),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4), // Descripción
                  1: const pw.FlexColumnWidth(1), // Cantidad
                  2: const pw.FlexColumnWidth(1.5), // Precio Unit
                  3: const pw.FlexColumnWidth(1.5), // Total
                },
                children: [
                  // Encabezados
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildCell('Descripción', isHeader: true),
                      _buildCell('Cant.', isHeader: true, align: pw.TextAlign.center),
                      _buildCell('Precio Unit.', isHeader: true, align: pw.TextAlign.right),
                      _buildCell('Subtotal', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Filas de items
                  ...budget.expenses.map((item) {
                    return pw.TableRow(
                      children: [
                        _buildCell(item.description),
                        _buildCell(item.quantity.toString(), align: pw.TextAlign.center),
                        _buildCell('S/. ${item.unitPrice.toStringAsFixed(2)}', align: pw.TextAlign.right),
                        _buildCell('S/. ${item.total.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                      ],
                    );
                  }).toList(),
                  // Fila de TOTAL
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('TOTAL SOLICITADO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Container(),
                      pw.Container(),
                      pw.Container(
                        color: PdfColors.blue50,
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('S/. ${budget.totalBudget.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: brandColor),
                            textAlign: pw.TextAlign.right
                        ),
                      ),
                    ],
                  )
                ],
              ),

              pw.SizedBox(height: 20),

              // 4. PROGRAMA SUGERIDO
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                color: brandColor,
                child: pw.Text('PROGRAMA SUGERIDO', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),

              pw.Row(children: [
                pw.Expanded(child: _buildProgramItem('Dirige', budget.conductedBy)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildProgramItem('Preside', budget.presidedBy)),
              ]),
              pw.SizedBox(height: 5),
              pw.Row(children: [
                pw.Expanded(child: _buildProgramItem('1er Himno', budget.openingHymn)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildProgramItem('1ra Oración', budget.openingPrayer)),
              ]),

              // --- AQUÍ EL DESARROLLO DE LA ACTIVIDAD ---
              pw.SizedBox(height: 10),
              pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(4),
                      color: PdfColors.grey50
                  ),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Desarrollo de la Actividad:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: brandColor)),
                        pw.SizedBox(height: 4),
                        pw.Text(budget.activityDevelopment.isEmpty ? '(Sin descripción)' : budget.activityDevelopment, style: const pw.TextStyle(fontSize: 10)),
                      ]
                  )
              ),
              pw.SizedBox(height: 10),
              // ------------------------------------------

              pw.Row(children: [
                pw.Expanded(child: _buildProgramItem('Himno Final', budget.closingHymn)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildProgramItem('Oración Final', budget.closingPrayer)),
              ]),
              pw.SizedBox(height: 5),
              _buildProgramItem('Encargados Limpieza', budget.cleaningTeam),
              pw.SizedBox(height: 5),
              _buildProgramItem('Encargados Seguridad', budget.securityTeam),

              pw.Spacer(),

              // 5. PIE DE PÁGINA Y FIRMAS
              pw.Text(
                'Nota: Se advierte que no se aprobará ningún presupuesto sin haber presentado los comprobantes de la actividad anterior.',
                style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.red900),
              ),
              pw.SizedBox(height: 30),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSignatureLine('Firma del Solicitante'),
                  _buildSignatureLine('Firma del Líder de Organización'),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --- Helpers ---

  pw.Widget _buildDataRow(String label1, String value1, String label2, String value2) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Row(children: [
            pw.Text('$label1 ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Expanded(child: pw.Text(value1, style: const pw.TextStyle(fontSize: 10), maxLines: 1, overflow: pw.TextOverflow.clip)),
          ]),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Row(children: [
            pw.Text('$label2 ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Expanded(child: pw.Text(value2, style: const pw.TextStyle(fontSize: 10), maxLines: 1)),
          ]),
        ),
      ],
    );
  }

  pw.Widget _buildCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildProgramItem(String label, String value) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5))),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureLine(String label) {
    return pw.Column(
      children: [
        pw.Container(width: 150, height: 1, color: PdfColors.black),
        pw.SizedBox(height: 5),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  // --- MÉTODO PARA GENERAR PDF DE SOLICITUD DE GASTOS ---
  Future<Uint8List> generateExpenseRequestPdf(ExpenseRequestModel request) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. TÍTULO Y CHECKS
              pw.Center(child: pw.Text('SOLICITUD DE GASTOS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  _buildCheckbox(request.isReimbursement),
                  pw.Text(' Reembolso   '),
                  _buildCheckbox(!request.isReimbursement),
                  pw.Text(' Por adelantado'),
                ],
              ),
              pw.SizedBox(height: 20),

              // 2. DATOS DE PERSONAS
              _buildFormRow('Solicitante:', request.applicantName),
              pw.SizedBox(height: 5),
              _buildFormRow('PAGAR A:', request.beneficiaryName),
              pw.SizedBox(height: 5),
              _buildFormRow('Dirección:', request.beneficiaryAddress),
              pw.SizedBox(height: 5),
              _buildFormRow('Propósito:', request.reason),

              pw.SizedBox(height: 20),

              // 3. TABLA DE CATEGORÍAS Y MONTOS
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey),
                columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1)},
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildCell('Categoría / Descripción', isHeader: true),
                      _buildCell('Fecha', isHeader: true),
                      _buildCell('Monto', isHeader: true),
                    ],
                  ),
                  ...request.items.map((item) => pw.TableRow(
                    children: [
                      _buildCell(item.category),
                      _buildCell(DateFormat('dd/MM/yyyy').format(item.date)),
                      _buildCell('S/. ${item.amount.toStringAsFixed(2)}', align: pw.TextAlign.right),
                    ],
                  )).toList(),
                  // Fila Total
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('TOTAL', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Container(),
                    pw.Container(
                      color: PdfColors.yellow100,
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('S/. ${request.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                    ),
                  ]),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Text('Firmas:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSignatureLine('Líder de Organización'),
                  _buildSignatureLine('Obispo (Opcional)'),
                ],
              ),

              pw.Spacer(),

              // 4. LÍNEA DE CORTE Y DATOS BANCARIOS (CORREGIDO)

              // Línea punteada simulada
              pw.Row(
                children: List.generate(60, (index) => pw.Expanded(
                  child: pw.Container(
                    color: index % 2 == 0 ? PdfColors.grey400 : PdfColors.white,
                    height: 1,
                  ),
                )),
              ),

              pw.SizedBox(height: 5),

              pw.Row(children: [
                // Usamos una "X" simple y elegante en negrita en lugar del icono problemático
                pw.Text('X', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(width: 5),
                // Quitamos el 'italic' para evitar que busque Helvetica y falle con la tilde de "Información"
                pw.Text('Cortar aquí para seguridad (Información EFT)', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              ]),

              pw.SizedBox(height: 10),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('DATOS BANCARIOS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 5),
                    pw.Row(children: [
                      pw.Expanded(child: _buildSimpleField('Banco', request.bankDetails.bankName)),
                      pw.SizedBox(width: 10),
                      pw.Expanded(child: _buildSimpleField('Tipo Cta', request.bankDetails.accountType)),
                    ]),
                    pw.SizedBox(height: 5),
                    _buildSimpleField('Nro Cuenta', request.bankDetails.accountNumber),
                    pw.SizedBox(height: 5),
                    _buildSimpleField('CCI', request.bankDetails.cci),
                    pw.SizedBox(height: 5),
                    pw.Row(children: [
                      pw.Expanded(child: _buildSimpleField('Beneficiario', request.beneficiaryName)),
                      pw.SizedBox(width: 10),
                      pw.Expanded(child: _buildSimpleField('DNI/RUC', request.bankDetails.identityDoc)),
                    ]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Helper checkbox simulado
  pw.Widget _buildCheckbox(bool checked) {
    return pw.Container(
      width: 12, height: 12,
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: checked ? pw.Center(child: pw.Text('X', style: const pw.TextStyle(fontSize: 8))) : null,
    );
  }

  pw.Widget _buildFormRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(width: 80, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
        pw.Expanded(
          child: pw.Container(
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSimpleField(String label, String value) {
    return pw.Row(children: [
      pw.Text('$label: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
    ]);
  }

}