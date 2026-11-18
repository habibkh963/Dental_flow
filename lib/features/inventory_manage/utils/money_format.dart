import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/currency_utils.dart';
import '../../settings_manage/controllers/app_currency_controller.dart';

final _moneyFormatter = NumberFormat('#,##0.00', 'ar');

String _currencySuffix() {
  if (Get.isRegistered<AppCurrencyController>()) {
    return Get.find<AppCurrencyController>().suffix;
  }
  return 'ل.س';
}

String formatMoney(double amount, {String? currencyCode}) {
  final suffix =
      currencyCode != null ? currencySuffixFor(currencyCode) : _currencySuffix();
  return '${_moneyFormatter.format(amount)} $suffix';
}

String formatMoneyCompact(double amount, {String? currencyCode}) {
  final suffix =
      currencyCode != null ? currencySuffixFor(currencyCode) : _currencySuffix();
  if (amount.abs() >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M $suffix';
  }
  if (amount.abs() >= 1000) {
    return '${(amount / 1000).toStringAsFixed(1)}K $suffix';
  }
  return formatMoney(amount, currencyCode: currencyCode);
}

double _toAmount(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

/// العملة المحفوظة مع السجل (مخرج، نفقة، دفعة، …).
String recordCurrencyCode(Map<String, dynamic> row, {String fallback = 'SYP'}) {
  final raw = row['currency']?.toString().trim();
  return (raw != null && raw.isNotEmpty) ? raw : fallback;
}

Map<String, double> sumAmountsByCurrency(
  Iterable<Map<String, dynamic>> rows,
  String amountKey, {
  String currencyKey = 'currency',
}) {
  final totals = <String, double>{};
  for (final row in rows) {
    final code = recordCurrencyCode(row);
    totals[code] = (totals[code] ?? 0) + _toAmount(row[amountKey]);
  }
  return totals;
}

int _currencyDisplayOrder(String code) {
  switch (code.toUpperCase()) {
    case 'SYP':
      return 0;
    case 'USD':
      return 1;
    default:
      return 2;
  }
}

String _currencyShortTag(String currencyCode) {
  final code = currencyCode.toUpperCase();
  if (code == 'USD') return 'USD';
  if (code == 'SYP') return 'SYP';
  return currencySuffixFor(code).toUpperCase();
}

/// مبلغ واحد بوسم عملة ثابت في الواجهة العربية (مثل 50 USD).
String formatMoneyTagged(double amount, String currencyCode) {
  final n = _moneyFormatter.format(amount);
  final tag = _currencyShortTag(currencyCode);
  return '\u2068$n $tag\u2069';
}

List<MapEntry<String, double>> _orderedCurrencyTotals(
  Map<String, double> totals,
) {
  final nonZero = totals.entries.where((e) => e.value != 0).toList();
  nonZero.sort(
    (a, b) => _currencyDisplayOrder(a.key).compareTo(
      _currencyDisplayOrder(b.key),
    ),
  );
  return nonZero;
}

String formatAmountsByCurrency(Map<String, double> totals) {
  if (totals.isEmpty) return formatMoneyTagged(0, 'SYP');
  final ordered = _orderedCurrencyTotals(totals);
  if (ordered.isEmpty) return formatMoneyTagged(0, 'SYP');
  if (ordered.length == 1) {
    final e = ordered.first;
    return formatMoneyTagged(e.value, e.key);
  }
  return ordered.map((e) => formatMoneyTagged(e.value, e.key)).join('  ');
}

/// ويدجت آمنة للـ RTL: شريط فئات (نص عربي + مبالغ LTR).
List<String> currencyAmountParts(Map<String, double> totals) {
  return _orderedCurrencyTotals(totals)
      .map((e) => formatMoneyTagged(e.value, e.key))
      .toList();
}

Map<String, double> mergeCurrencyTotals(Iterable<Map<String, double>> maps) {
  final merged = <String, double>{};
  for (final map in maps) {
    for (final e in map.entries) {
      merged[e.key] = (merged[e.key] ?? 0) + e.value;
    }
  }
  return merged;
}

String formatSumForRecords(
  Iterable<Map<String, dynamic>> rows,
  String amountKey,
) {
  return formatAmountsByCurrency(sumAmountsByCurrency(rows, amountKey));
}
