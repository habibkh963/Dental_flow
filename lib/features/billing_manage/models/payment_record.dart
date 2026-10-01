class PaymentRecord {
  final String id;
  final String invoiceId;
  final double amount;
  final String method;
  final String note;
  final DateTime paidAt;

  const PaymentRecord({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.method,
    required this.note,
    required this.paidAt,
  });

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    return PaymentRecord(
      id: map['id']?.toString() ?? '',
      invoiceId: map['invoice_id']?.toString() ?? '',
      amount: _parseDouble(map['amount']),
      method: map['method']?.toString() ?? 'نقدي',
      note: map['note']?.toString() ?? '',
      paidAt: _parseDate(map['paid_at']) ?? DateTime.now(),
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
