import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'daily_inventory_controller.dart';

class InventoryOutputDialogController extends GetxController {
  static const dialogTag = 'inventory_output_dialog';

  InventoryOutputDialogController(this.dailyController);

  final DailyInventoryController dailyController;

  final itemNameController = TextEditingController();
  final quantityController = TextEditingController();
  final unitController = TextEditingController();
  final priceController = TextEditingController();

  final saving = false.obs;
  final formError = RxnString();

  void clearFormError() => formError.value = null;

  @override
  void onClose() {
    itemNameController.dispose();
    quantityController.dispose();
    unitController.dispose();
    priceController.dispose();
    super.onClose();
  }

  Future<void> submit(BuildContext context) async {
    final itemName = itemNameController.text.trim();
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    final unit = unitController.text.trim();
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
