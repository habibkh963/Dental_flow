import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/colors.dart';
import '../../../services/database_service.dart';
import '../models/invoice.dart';
import '../models/payment_record.dart';
import '../utils/billing_input.dart';
import 'invoices_controller.dart';

class PaymentDialogController extends GetxController {
  static const dialogTag = 'payment_dialog';

  PaymentDialogController({
    required this.invoicesController,
    required this.invoice,
    required this.patientName,
  });

  final InvoicesController invoicesController;
  final Invoice invoice;
  final String patientName;

  late final TextEditingController amountController;
  late final TextEditingController noteController;

  final payments = <PaymentRecord>[].obs;
  final remainingBalance = 0.0.obs;
  final totalAmount = 0.0.obs;
  final payMethod = kPaymentMethods.first.obs;
  final loading = true.obs;
  final saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    amountController = TextEditingController();
    noteController = TextEditingController();
    totalAmount.value = invoice.total;
    loadData();
  }

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }

  Future<void> loadData() async {
    loading.value = true;
    try {
      final db = DatabaseService.instance;
      final balance = await db.getInvoiceBalance(invoice.id);
      final rawPayments = await db.getPayments(invoice.id);

      remainingBalance.value = balance;
      payments.assignAll(rawPayments.map(PaymentRecord.fromMap));
    } finally {
      loading.value = false;
    }
  }

  Future<void> submitPayment() async {
    final result = tryParsePaymentForm(
      amountText: amountController.text,
      remainingBalance: remainingBalance.value,
      method: payMethod.value,
      note: noteController.text,
    );

    if (result.values == null) {
      Get.snackbar(
        'خطأ',
        result.error ?? 'تحقق من الحقول',
        backgroundColor: AppColors.cancelledColor,
        colorText: Colors.white,
      );
      return;
    }

    saving.value = true;
    try {
      await invoicesController.recordPayment(
        invoiceId: invoice.id,
        payment: result.values!,
      );
      amountController.clear();
      noteController.clear();
      await loadData();
      await invoicesController.loadAll();
      Get.snackbar(
        'نجح',
        'تم تسجيل عملية الدفع',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } finally {
      saving.value = false;
    }
  }

  Future<void> deletePayment(String paymentId) async {
    await DatabaseService.instance.deletePayment(paymentId);
    await loadData();
    await invoicesController.loadAll();
  }

  void fillRemainingAmount() {
    if (remainingBalance.value > 0) {
      amountController.text = remainingBalance.value.toStringAsFixed(2);
    }
  }
}
