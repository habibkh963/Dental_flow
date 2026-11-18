import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AppCurrencyOption {
  const AppCurrencyOption({
    required this.code,
    required this.label,
    required this.suffix,
  });

  final String code;
  final String label;
  final String suffix;
}

const kAppCurrencyOptions = [
  AppCurrencyOption(code: 'SYP', label: 'ليرة سورية', suffix: 'ل.س'),
  AppCurrencyOption(code: 'USD', label: 'دولار أمريكي', suffix: 'USD'),
  AppCurrencyOption(code: 'EUR', label: 'يورو', suffix: 'EUR'),
  AppCurrencyOption(code: 'TRY', label: 'ليرة تركية', suffix: 'TRY'),
  AppCurrencyOption(code: 'SAR', label: 'ريال سعودي', suffix: 'SAR'),
  AppCurrencyOption(code: 'AED', label: 'درهم إماراتي', suffix: 'AED'),
];

class AppCurrencyController extends GetxController {
  static const storageKey = 'app_currency_code';

  final code = 'SYP'.obs;
  final _box = GetStorage();

  AppCurrencyOption get current => kAppCurrencyOptions.firstWhere(
        (c) => c.code == code.value,
        orElse: () => kAppCurrencyOptions.first,
      );

  String get suffix => current.suffix;

  @override
  void onInit() {
    super.onInit();
    final stored = _box.read(storageKey);
    if (stored is String && stored.isNotEmpty) {
      code.value = stored;
    }
  }

  Future<void> setCurrency(String newCode) async {
    code.value = newCode;
    await _box.write(storageKey, newCode);
  }
}