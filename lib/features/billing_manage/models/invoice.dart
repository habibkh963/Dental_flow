import 'invoice_status.dart';

class Invoice {
  final String id;
  final String patientId;
  final double total;
  final InvoiceStatus status;
  final DateTime issuedAt;
  final String typeOfTreatment;
  final double remainingBalance;

  const Invoice({
    required this.id,
    required this.patientId,
    required this.total,
    required this.status,
    required this.issuedAt,
    required this.typeOfTreatment,
    required this.remainingBalance,
  });

  InvoiceStatus get displayStatus => resolveInvoiceStatus(
        storedStatus: status.storageValue,
        remainingBalance: remainingBalance,
      );

  bool get isFullyPaid => remainingBalance <= 0;

  factory Invoice.fromMap(
    Map<String, dynamic> map, {
    double remainingBalance = 0,
  }) {
    return Invoice(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      total: _parseDouble(map['total']),
      status: InvoiceStatusParsing.fromString(map['status']?.toString()),
      issuedAt: _parseDate(map['issued_at']) ?? DateTime.now(),
      typeOfTreatment: map['type_of_treatment']?.toString() ?? '',
      remainingBalance: remainingBalance,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
