import 'package:get/get.dart';

import '../../../services/database_service.dart';

class InvoicesController extends GetxController {
  final db = DatabaseService.instance;

  var invoices = <Map<String, dynamic>>[].obs;
  var patients = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      isLoading.value = true;
      final p = await db.getPatients();
      final inv = await db.getInvoices();
      patients.assignAll(p);
      invoices.assignAll(inv);
    } catch (e) {
      // swallow for now; UI can show snackbar if needed
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reload() => loadAll();

  Future<double> getRemaining(String invoiceId) async {
    try {
      return await db.getInvoiceBalance(invoiceId);
    } catch (_) {
      return 0.0;
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    await db.deleteInvoice(invoiceId);
    await loadAll();
  }

  Future<void> addPayment(Map<String, dynamic> payment) async {
    await db.addPayment(payment);
    await loadAll();
  }
}
