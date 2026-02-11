import 'package:get/get.dart';

import '../../../services/database_service.dart';

class InvoicesController extends GetxController {
  final db = DatabaseService.instance;

  var invoices = <Map<String, dynamic>>[].obs; // كل الفواتير
  var filteredInvoices = <Map<String, dynamic>>[].obs; // الفواتير بعد البحث

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

      // بعد التحميل، خلي filteredInvoices = كل الفواتير
      filteredInvoices.assignAll(inv);
    } catch (e) {
      // ممكن تعرض snackbar هنا
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

extension InvoicesSearch on InvoicesController {
  /// فلترة الفواتير حسب اسم المريض
  void filterInvoices(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      // رجّع القائمة الأصلية
      filteredInvoices.assignAll(invoices);
    } else {
      filteredInvoices.assignAll(
        invoices.where((inv) {
          final patientName = getPatientName(
            inv['patient_id'] ?? '',
            patients.value,
          );
          return patientName.toLowerCase().contains(q);
        }).toList(),
      );
    }
  }

  String getPatientName(String patientId, List<Map<String, dynamic>> patients) {
    try {
      final p = patients.firstWhere((x) => x['id'] == patientId);
      return '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
    } catch (_) {
      return '-';
    }
  }
}
