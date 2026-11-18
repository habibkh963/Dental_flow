import '../features/settings_manage/controllers/app_currency_controller.dart';

/// عملات سريعة في حقول الإدخال (ل.س / $).
const kInputCurrencyCodes = ['SYP', 'USD'];

String currencySuffixFor(String? code) {
  if (code == null || code.isEmpty) return 'ل.س';
  for (final opt in kAppCurrencyOptions) {
    if (opt.code == code) return opt.suffix;
  }
  return code;
}

String currencyLabelFor(String? code) {
  if (code == null || code.isEmpty) return 'ل.س';
  for (final opt in kAppCurrencyOptions) {
    if (opt.code == code) return opt.label;
  }
  return code;
}