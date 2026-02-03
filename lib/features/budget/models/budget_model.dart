import 'package:cloud_firestore/cloud_firestore.dart';

// =======================================================
// MODELO A: HOJA DE PRESUPUESTO (Planificación de Actividad)
// =======================================================

class BudgetItem {
  final String description;
  final int quantity;
  final double unitPrice;

  BudgetItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  // Cálculo automático del total
  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      description: map['description'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
    );
  }
}

class ActivityBudgetModel {
  final String id;
  final String organization;      // Ej: Hombres Jóvenes
  final String responsibleLeader; // Líder Responsable
  final DateTime activityDate;
  final String activityName;
  final String activityPurpose;
  final DateTime presentationDate; // Fecha presentación al Obispo
  final String applicantName;      // Nombre del solicitante

  final List<BudgetItem> expenses; // Lista de gastos

  // Programa Sugerido (Logística)
  final String conductedBy;       // Dirige
  final String presidedBy;        // Preside
  final String openingHymn;
  final String openingPrayer;
  final String activityDevelopment; // Desarrollo de la actividad
  final String closingHymn;
  final String closingPrayer;
  final String cleaningTeam;      // Encargados limpieza
  final String securityTeam;      // Encargados seguridad

  // Estado del presupuesto (Opcional, para tu control interno)
  final String status; // 'draft', 'approved', 'rejected'

  ActivityBudgetModel({
    required this.id,
    required this.organization,
    required this.responsibleLeader,
    required this.activityDate,
    required this.activityName,
    required this.activityPurpose,
    required this.presentationDate,
    required this.applicantName,
    required this.expenses,
    this.conductedBy = '',
    this.presidedBy = '',
    this.openingHymn = '',
    this.openingPrayer = '',
    this.activityDevelopment = '', // Inicializar en constructor
    this.closingHymn = '',
    this.closingPrayer = '',
    this.cleaningTeam = '',
    this.securityTeam = '',
    this.status = 'draft',
  });

  double get totalBudget => expenses.fold(0, (sum, item) => sum + item.total);

  Map<String, dynamic> toMap() {
    return {
      'organization': organization,
      'responsibleLeader': responsibleLeader,
      'activityDate': Timestamp.fromDate(activityDate),
      'activityName': activityName,
      'activityPurpose': activityPurpose,
      'presentationDate': Timestamp.fromDate(presentationDate),
      'applicantName': applicantName,
      'expenses': expenses.map((x) => x.toMap()).toList(),
      'conductedBy': conductedBy,
      'presidedBy': presidedBy,
      'openingHymn': openingHymn,
      'openingPrayer': openingPrayer,
      'activityDevelopment': activityDevelopment, // Guardar
      'closingHymn': closingHymn,
      'closingPrayer': closingPrayer,
      'cleaningTeam': cleaningTeam,
      'securityTeam': securityTeam,
      'status': status,
    };
  }

  factory ActivityBudgetModel.fromMap(Map<String, dynamic> map, String id) {
    return ActivityBudgetModel(
      id: id,
      organization: map['organization'] ?? '',
      responsibleLeader: map['responsibleLeader'] ?? '',
      activityDate: (map['activityDate'] as Timestamp).toDate(),
      activityName: map['activityName'] ?? '',
      activityPurpose: map['activityPurpose'] ?? '',
      presentationDate: (map['presentationDate'] as Timestamp).toDate(),
      applicantName: map['applicantName'] ?? '',
      expenses: List<BudgetItem>.from(
        (map['expenses'] as List? ?? []).map((x) => BudgetItem.fromMap(x)),
      ),
      conductedBy: map['conductedBy'] ?? '',
      presidedBy: map['presidedBy'] ?? '',
      openingHymn: map['openingHymn'] ?? '',
      openingPrayer: map['openingPrayer'] ?? '',
      activityDevelopment: map['activityDevelopment'] ?? '', // Leer
      closingHymn: map['closingHymn'] ?? '',
      closingPrayer: map['closingPrayer'] ?? '',
      cleaningTeam: map['cleaningTeam'] ?? '',
      securityTeam: map['securityTeam'] ?? '',
      status: map['status'] ?? 'draft',
    );
  }
}

// =======================================================
// MODELO B: SOLICITUD DE GASTOS (Reembolso/Adelanto)
// =======================================================

class ExpenseItem {
  final String category; // Ej: Primaria, Administración
  final DateTime date;
  final double amount;

  ExpenseItem({required this.category, required this.date, required this.amount});

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'date': Timestamp.fromDate(date),
      'amount': amount,
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      category: map['category'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      amount: map['amount']?.toDouble() ?? 0.0,
    );
  }
}

class BankDetails {
  final String bankName;
  final String accountType;
  final String accountNumber;
  final String cci; // Código Interbancario (Importante en PDF)
  final String identityDoc; // DNI

  BankDetails({
    this.bankName = '',
    this.accountType = '',
    this.accountNumber = '',
    this.cci = '',
    this.identityDoc = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountType': accountType,
      'accountNumber': accountNumber,
      'cci': cci,
      'identityDoc': identityDoc,
    };
  }

  factory BankDetails.fromMap(Map<String, dynamic> map) {
    return BankDetails(
      bankName: map['bankName'] ?? '',
      accountType: map['accountType'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      cci: map['cci'] ?? '',
      identityDoc: map['identityDoc'] ?? '',
    );
  }
}

class ExpenseRequestModel {
  final String id;
  final bool isReimbursement; // true = Reembolso, false = Adelanto
  final String applicantName; // Solicitante
  final String beneficiaryName; // Pagar a (Nombre)
  final String beneficiaryAddress; // Dirección
  final String reason; // Propósito del gasto

  final List<ExpenseItem> items; // Tabla de categorías y montos
  final BankDetails bankDetails; // Datos bancarios (parte inferior PDF)
  final DateTime requestDate;

  ExpenseRequestModel({
    required this.id,
    required this.isReimbursement,
    required this.applicantName,
    required this.beneficiaryName,
    required this.beneficiaryAddress,
    required this.reason,
    required this.items,
    required this.bankDetails,
    required this.requestDate,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.amount);

  Map<String, dynamic> toMap() {
    return {
      'isReimbursement': isReimbursement,
      'applicantName': applicantName,
      'beneficiaryName': beneficiaryName,
      'beneficiaryAddress': beneficiaryAddress,
      'reason': reason,
      'items': items.map((x) => x.toMap()).toList(),
      'bankDetails': bankDetails.toMap(),
      'requestDate': Timestamp.fromDate(requestDate),
    };
  }

  factory ExpenseRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseRequestModel(
      id: id,
      isReimbursement: map['isReimbursement'] ?? true,
      applicantName: map['applicantName'] ?? '',
      beneficiaryName: map['beneficiaryName'] ?? '',
      beneficiaryAddress: map['beneficiaryAddress'] ?? '',
      reason: map['reason'] ?? '',
      items: List<ExpenseItem>.from(
        (map['items'] as List? ?? []).map((x) => ExpenseItem.fromMap(x)),
      ),
      bankDetails: map['bankDetails'] != null
          ? BankDetails.fromMap(map['bankDetails'])
          : BankDetails(),
      requestDate: (map['requestDate'] as Timestamp).toDate(),
    );
  }
}