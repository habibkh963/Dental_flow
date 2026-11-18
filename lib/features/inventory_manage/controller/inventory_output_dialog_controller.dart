import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/currency_utils.dart';
import '../../settings_manage/controllers/app_currency_controller.dart';
import '../models/inventory_item.dart';
import 'daily_inventory_controller.dart';

class InventoryOutputDialogController extends GetxController {
  static const dialogTag = 'inventory_output_dialog';

  InventoryOutputDialogController(this.dailyController);

  final DailyInventoryController dailyController;

  final itemNameController = TextEditingController();
  final quantityController = TextEditingController();
  final customUnitController = TextEditingController();
  final priceController = TextEditingController();

  final selectedUnit = kDefaultInventoryUnit.obs;
  final useCustomUnit = false.obs;
  final selectedCurrency = 'SYP'.obs;

  final saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final code = Get.isRegistered<AppCurrencyController>()
        ? Get.find<AppCurrencyController>().code.value
        : 'SYP';
    selectedCurrency.value =
        kInputCurrencyCodes.contains(code) ? code : 'SYP';
  }
  final formError = RxnString();

  String get effectiveUnit => useCustomUnit.value
      ? customUnitController.text.trim()
      : selectedUnit.value;

  void clearFormError() => formError.value = null;

  void selectPresetUnit(String unit) {
    useCustomUnit.value = false;
    selectedUnit.value = unit;
    clearFormError();
  }

  void selectCustomUnit() {
    useCustomUnit.value = true;
    clearFormError();
  }

  @override
  void onClose() {
    itemNameController.dispose();
    quantityController.dispose();
    customUnitController.dispose();
    priceController.dispose();
    super.onClose();
  }

  Future<void> submit(BuildContext context) async {
    final itemName = itemNameController.text.trim();
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    final unit = effectiveUnit;
    final price = double.tryParse(priceController.text.trim()) ?? 0;

    if (itemName.isEmpty) {
      formError.value = 'اسم المادة مطلوب';
      return;
    }
    if (quantity <= 0) {
      formError.value = 'الكمية يجب أن تكون أكبر من صفر';
      return;
    }
    if (unit.isEmpty) {
      formError.value = 'الوحدة مطلوبة';
      return;
    }
    if (price <= 0) {
      formError.value = 'السعر يجب أن يكون أكبر من صفر';
      return;
    }

    clearFormError();
    saving.value = true;
    try {
      await dailyController.addInventoryOutput({
        'item_name': itemName,
        'quantity': quantity,
        'unit': unit,
        'price': price,
        'currency': selectedCurrency.value,
        'date': DateTime.now().toIso8601String(),
      });
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      formError.value = 'تعذر حفظ المخرج، حاول مرة أخرى';
      saving.value = false;
    }
  }
}
