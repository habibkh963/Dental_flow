import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/app_date_picker.dart';
import '../../../core/currency_utils.dart';
import '../../settings_manage/controllers/app_currency_controller.dart';
import '../../home/controllers/dash_board_controller.dart';
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
  final selectedCurrency = 'SYP'.obs;
  DateTime expenseDate = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<DashBoardController>()) {
      final day = Get.find<DashBoardController>().selectedLedgerDay.value;
      expenseDate = DateTime(day.year, day.month, day.day);
    }
    final code = Get.isRegistered<AppCurrencyController>()
        ? Get.find<AppCurrencyController>().code.value
        : 'SYP';
    selectedCurrency.value =
        kInputCurrencyCodes.contains(code) ? code : 'SYP';
  }

  void clearFormError() => formError.value = null;

  @override
  void onClose() {
    descriptionController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showAppDatePicker(
      context,
      initialDate: expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'تاريخ النفقة',
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
        'currency': selectedCurrency.value,
        'expense_date': expenseDate.toIso8601String(),
        'note': note,
      });
      if (Get.isRegistered<DashBoardController>()) {
        final dash = Get.find<DashBoardController>();
        final day = dash.selectedLedgerDay.value;
        if (day.year == expenseDate.year &&
            day.month == expenseDate.month &&
            day.day == expenseDate.day) {
          await dash.loadDayLedger(day);
        }
        await dash.reloadLedgerAndFinance();
      }
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      formError.value = 'تعذر حفظ النفقة، حاول مرة أخرى';
      saving.value = false;
    }
  }
}
