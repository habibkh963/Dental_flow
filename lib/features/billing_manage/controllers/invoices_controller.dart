import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../../../services/database_service.dart';
import '../models/invoice.dart';
import '../utils/billing_input.dart';
import '../views/widgets/invoice_dialog.dart';
import '../views/widgets/payment_dialog.dart';
import 'invoice_dialog_controller.dart';
import 'payment_dialog_controller.dart';

class InvoicesController extends GetxController {
  final db = DatabaseService.instance;

  final filteredInvoices = <Invoice>[].obs;
  final patients = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  final _invoices = <Invoice>[];

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      final patientList = await db.getPatients();
      final rawInvoices = await db.getInvoices();

      patients.assignAll(patientList);

      final loaded = <Invoice>[];
      for (final raw in rawInvoices) {
        final id = raw['id']?.toString() ?? '';
        final balance = id.isEmpty ? 0.0 : await db.getInvoiceBalance(id);
        loaded.add(Invoice.fromMap(raw, remainingBalance: balance));
      }

      _invoices
        ..clear()
        ..addAll(loaded);
      _applyFilter(searchQuery.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() => loadAll();

  void filterInvoices(String query) {
    searchQuery.value = query;
    _applyFilter(query);
  }

  String getPatientName(String patientId) {
    try {
      final p = patients.firstWhere((x) => x['id'] == patientId);
      return '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    } catch (_) {
      return '-';
    }
  }

  Future<void> createInvoice(InvoiceFormValues values) async {
    await db.addInvoice({
      'patient_id': values.patientId,
      'total': values.total,
      'status': values.status,
      'type_of_treatment': values.typeOfTreatment,
    });
    await loadAll();
  }

  Future<void> recordPayment({
    required String invoiceId,
    required PaymentFormValues payment,
  }) async {
    await db.addPayment({
      'invoice_id': invoiceId,
      'amount': payment.amount,
      'method': payment.method,
      'note': payment.note,
    });
    await loadAll();
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await db.deleteInvoice(invoiceId);
    await loadAll();
  }

  void openCreateInvoiceDialog({Map<String, dynamic>? patient}) {
    _openInvoiceDialog(patient: patient);
  }

  void openPaymentDialog(Invoice invoice, String patientName) {
    final tag = PaymentDialogController.dialogTag;
    if (Get.isRegistered<PaymentDialogController>(tag: tag)) {
      Get.delete<PaymentDialogController>(tag: tag);
    }

    Get.put(
      PaymentDialogController(
        invoicesController: this,
        invoice: invoice,
        patientName: patientName,
      ),
      tag: tag,
    );

    Get.dialog(const PaymentDialog()).whenComplete(() {
      if (Get.isRegistered<PaymentDialogController>(tag: tag)) {
        Get.delete<PaymentDialogController>(tag: tag);
      }
    });
  }

  Future<void> confirmDeleteInvoice(Invoice invoice, String patientName) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('حذف فاتورة $patientName؟', style: GoogleFonts.poppins()),
        content: Text(
          'سيتم حذف الفاتورة وجميع الدفعات المرتبطة بها. هل أنت متأكد؟',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('إلغاء', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'حذف',
              style: GoogleFonts.poppins(color: AppColors.cancelledColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteInvoice(invoice.id);
    }
  }

  void _openInvoiceDialog({Map<String, dynamic>? patient}) {
    final tag = InvoiceDialogController.dialogTag;
    if (Get.isRegistered<InvoiceDialogController>(tag: tag)) {
      Get.delete<InvoiceDialogController>(tag: tag);
    }

    Get.put(
      InvoiceDialogController(invoicesController: this, patient: patient),
      tag: tag,
    );

    Get.dialog(
      InvoiceDialog(patient: patient),
      barrierDismissible: false,
    ).whenComplete(() {
      if (Get.isRegistered<InvoiceDialogController>(tag: tag)) {
        Get.delete<InvoiceDialogController>(tag: tag);
      }
    });
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      filteredInvoices.assignAll(_invoices);
      return;
    }

    filteredInvoices.assignAll(
      _invoices.where((invoice) {
        final patientName = getPatientName(invoice.patientId).toLowerCase();
        return patientName.contains(q);
      }).toList(),
    );
  }
}
