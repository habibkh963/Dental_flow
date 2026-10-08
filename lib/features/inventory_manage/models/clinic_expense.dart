import '../utils/clinic_expense_categories.dart';

class ClinicExpense {
  final String id;
  final String category;
  final String description;
  final double amount;
  final DateTime? expenseDate;
  final String note;

  const ClinicExpense({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    this.expenseDate,
    this.note = '',
  });

  String get categoryLabel => ClinicExpenseCategory.byId(category).label;

  factory ClinicExpense.fromMap(Map<String, dynamic> map) {
    return ClinicExpense(
      id: map['id']?.toString() ?? '',
      category: map['category']?.toString() ?? 'other',
      description: map['description']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      expenseDate: _parseDate(map['expense_date'] ?? map['created_at']),
      note: map['note']?.toString() ?? '',
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
