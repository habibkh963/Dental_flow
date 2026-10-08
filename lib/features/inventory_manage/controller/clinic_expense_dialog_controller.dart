import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/clinic_expense_categories.dart';
import 'daily_inventory_controller.dart';

class ClinicExpenseDialogController extends GetxController {
  static const dialogTag = 'clinic_expense_dialog';

  ClinicExpenseDialogController(this.dailyController);

  final DailyInventoryController dailyController;

  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final saving = false.obs;
  final formError = RxnString();
  final selectedCategory = ClinicExpenseCategory.laboratories.id.obs;
  DateTime expenseDate = DateTime.now();

  void clearFormError() => formError.value = null;

  @override
  void onClose() {
    descriptionController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      expenseDate = picked;
      update();
    }
  }

  Future<void> submit(BuildContext context) async {
    final description = descriptionController.text.trim();
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final note = noteController.text.trim();

    if (description.isEmpty) {
      formError.value = 'الوصف مطلوب';
      return;
    }
    if (amount <= 0) {
      formError.value = 'المبلغ يجب أن يكون أكبر من صفر';
      return;
    }

    clearFormError();
    saving.value = true;
    try {
      await dailyController.addClinicExpense({
        'category': selectedCategory.value,
        'description': description,
        'amount': amount,
        'expense_date': expenseDate.toIso8601String(),
        'note': note,
      });
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      formError.value = 'تعذر حفظ النفقة، حاول مرة أخرى';
      saving.value = false;
    }
  }
}
