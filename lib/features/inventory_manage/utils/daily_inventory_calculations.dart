import '../models/daily_financial_summary.dart';
import 'daily_inventory_date.dart';

typedef DatePredicate = bool Function(DateTime date);

double toMoney(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? parseRecordDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Map<String, double> groupPaymentsByInvoice(
  List<Map<String, dynamic>> payments,
) {
  final grouped = <String, double>{};
  for (final payment in payments) {
    final invoiceId = payment['invoice_id']?.toString();
    if (invoiceId == null || invoiceId.isEmpty) continue;
    grouped[invoiceId] = (grouped[invoiceId] ?? 0) + toMoney(payment['amount']);
  }
  return grouped;
}

double sumPayments(
  List<Map<String, dynamic>> payments, {
  DatePredicate? whereDate,
}) {
  var total = 0.0;
  for (final payment in payments) {
    final date = parseRecordDate(payment['paid_at'] ?? payment['date']);
    if (date == null) continue;
    if (whereDate != null && !whereDate(date)) continue;
    total += toMoney(payment['amount']);
  }
  return total;
}

double sumInvoiceTotals(
  List<Map<String, dynamic>> invoices, {
  DatePredicate? whereDate,
}) {
  var total = 0.0;
  for (final invoice in invoices) {
    final date = parseRecordDate(invoice['issued_at']);
    if (date == null) continue;
    if (whereDate != null && !whereDate(date)) continue;
    total += toMoney(invoice['total']);
  }
  return total;
}

/// Outstanding = Σ max(0, invoice.total − payments on that invoice).
double sumOutstanding(
  List<Map<String, dynamic>> invoices,
  Map<String, double> paymentsByInvoice, {
  DatePredicate? whereInvoiceDate,
}) {
  var total = 0.0;
  for (final invoice in invoices) {
    final issuedAt = parseRecordDate(invoice['issued_at']);
    if (issuedAt == null) continue;
    if (whereInvoiceDate != null && !whereInvoiceDate(issuedAt)) continue;

    final invoiceId = invoice['id']?.toString() ?? '';
    final invoiceTotal = toMoney(invoice['total']);
    final paid = paymentsByInvoice[invoiceId] ?? 0;
    final remaining = invoiceTotal - paid;
    if (remaining > 0) total += remaining;
  }
  return total;
}

double sumOutputExpenses(
  List<Map<String, dynamic>> outputs, {
  DatePredicate? whereDate,
}) {
  var total = 0.0;
  for (final output in outputs) {
    final date = parseRecordDate(output['date'] ?? output['created_at']);
    if (date == null) continue;
    if (whereDate != null && !whereDate(date)) continue;
    total += toMoney(output['price']);
  }
  return total;
}

class DailyFinancialReport {
  final DailyFinancialSummary daily;
  final DailyFinancialSummary monthly;
  final DailyFinancialSummary allTime;

  const DailyFinancialReport({
    required this.daily,
    required this.monthly,
    required this.allTime,
  });
}

DailyFinancialSummary computeSummaryForMonth({
  required List<Map<String, dynamic>> invoices,
  required List<Map<String, dynamic>> payments,
  required List<Map<String, dynamic>> outputs,
  required DateTime month,
}) {
  final reference = startOfMonth(month);
  final paymentsByInvoice = groupPaymentsByInvoice(payments);
  bool inMonth(DateTime date) => isSameMonth(date, reference);

  return DailyFinancialSummary(
    invoicesTotal: sumInvoiceTotals(invoices, whereDate: inMonth),
    paymentsReceived: sumPayments(payments, whereDate: inMonth),
    outstanding: sumOutstanding(
      invoices,
      paymentsByInvoice,
      whereInvoiceDate: inMonth,
    ),
    expenses: sumOutputExpenses(outputs, whereDate: inMonth),
    netCashFlow: sumPayments(payments, whereDate: inMonth) -
        sumOutputExpenses(outputs, whereDate: inMonth),
  );
}

List<DateTime> collectAvailableHistoryMonths({
  required List<Map<String, dynamic>> invoices,
  required List<Map<String, dynamic>> payments,
  required List<Map<String, dynamic>> outputs,
}) {
  final dates = <DateTime>[];

  for (final invoice in invoices) {
    final date = parseRecordDate(invoice['issued_at']);
    if (date != null) dates.add(date);
  }
  for (final payment in payments) {
    final date = parseRecordDate(payment['paid_at'] ?? payment['date']);
    if (date != null) dates.add(date);
  }
  for (final output in outputs) {
    final date = parseRecordDate(output['date'] ?? output['created_at']);
    if (date != null) dates.add(date);
  }

  if (dates.isEmpty) {
    return enumerateMonths();
  }

  dates.sort();
  return enumerateMonths(earliest: dates.first);
}

DailyFinancialReport computeFinancialReport({
  required List<Map<String, dynamic>> invoices,
  required List<Map<String, dynamic>> payments,
  required List<Map<String, dynamic>> outputs,
}) {
  final paymentsByInvoice = groupPaymentsByInvoice(payments);
  final now = DateTime.now();

  DailyFinancialSummary forPredicate(DatePredicate? predicate) {
    return DailyFinancialSummary(
      invoicesTotal: sumInvoiceTotals(invoices, whereDate: predicate),
      paymentsReceived: sumPayments(payments, whereDate: predicate),
      outstanding: sumOutstanding(
        invoices,
        paymentsByInvoice,
        whereInvoiceDate: predicate,
      ),
      expenses: sumOutputExpenses(outputs, whereDate: predicate),
      netCashFlow: sumPayments(payments, whereDate: predicate) -
          sumOutputExpenses(outputs, whereDate: predicate),
    );
  }

  return DailyFinancialReport(
    daily: forPredicate(isToday),
    monthly: forPredicate((date) => isSameMonth(date, now)),
    allTime: forPredicate(null),
  );
}

DailyPeriodFilterSummary computePeriodFilterSummary({
  required List<Map<String, dynamic>> payments,
  required List<Map<String, dynamic>> outputs,
  required DateTime start,
  required DateTime end,
}) {
  final range = normalizeRange(start, end);
  bool inRange(DateTime date) => isDateInRange(date, range.$1, range.$2);

  var paymentsTotal = 0.0;
  var paymentsCount = 0;
  for (final payment in payments) {
    final date = parseRecordDate(payment['date']);
    if (date == null || !inRange(date)) continue;
    paymentsTotal += toMoney(payment['amount']);
    paymentsCount++;
  }

  var expensesTotal = 0.0;
  var outputsCount = 0;
  for (final output in outputs) {
    final date = parseRecordDate(output['date'] ?? output['created_at']);
    if (date == null || !inRange(date)) continue;
    expensesTotal += toMoney(output['price']);
    outputsCount++;
  }

  return DailyPeriodFilterSummary(
    paymentsTotal: paymentsTotal,
    expensesTotal: expensesTotal,
    netTotal: paymentsTotal - expensesTotal,
    paymentsCount: paymentsCount,
    outputsCount: outputsCount,
  );
}

List<Map<String, dynamic>> normalizePayments(
  List<Map<String, dynamic>> payments,
) {
  final normalized = <Map<String, dynamic>>[];
  for (final payment in payments) {
    final date = parseRecordDate(payment['paid_at'] ?? payment['date']);
    if (date == null) continue;
    normalized.add({
      'id': payment['id'],
      'date': date,
      'amount': toMoney(payment['amount']),
      'patient_id': payment['patient_id'],
      'invoice_id': payment['invoice_id'],
      'payment_method': payment['method'] ?? 'نقدي',
      'notes': payment['note'] ?? payment['notes'] ?? '',
    });
  }
  normalized.sort(
    (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
  );
  return normalized;
}

List<Map<String, dynamic>> filterByDateRange({
  required List<Map<String, dynamic>> items,
  required DateTime start,
  required DateTime end,
  required DateTime? Function(Map<String, dynamic> item) dateSelector,
}) {
  final range = normalizeRange(start, end);
  return items.where((item) {
    final date = dateSelector(item);
    if (date == null) return false;
    return isDateInRange(date, range.$1, range.$2);
  }).toList();
}
