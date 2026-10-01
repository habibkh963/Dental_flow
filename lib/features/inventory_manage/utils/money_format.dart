import 'package:intl/intl.dart';

final _moneyFormatter = NumberFormat('#,##0.00', 'ar');

String formatMoney(double amount) => '${_moneyFormatter.format(amount)} ل.س';

String formatMoneyCompact(double amount) {
  if (amount.abs() >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(1)}M ل.س';
  }
  if (amount.abs() >= 1000) {
    return '${(amount / 1000).toStringAsFixed(1)}K ل.س';
  }
  return formatMoney(amount);
}
