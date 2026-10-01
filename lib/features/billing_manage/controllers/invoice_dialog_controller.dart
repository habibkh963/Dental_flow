import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/colors.dart';
import '../../../services/database_service.dart';
import '../utils/billing_input.dart';
import 'invoices_controller.dart';

class InvoiceDialogController extends GetxController {
  static const dialogTag = 'invoice_dialog';

  InvoiceDialogController({
    required this.invoicesController,
    this.patient,
  });

  final InvoicesController invoicesController;
  final Map<String, dynamic>? patient;

  late final TextEditingController patientNameController;
  late final TextEditingController priceController;

  final patients = <Map<String, dynamic>>[].obs;
  final selectedPatientId = ''.obs;
  final selectedTreatments = <String>[].obs;
  final inputMode = false.obs;
  final isEstimated = false.obs;
  final saving = false.obs;

  bool get hasPresetPatient => patient != null;

  @override
  void onInit() {
    super.onInit();
    patientNameController = TextEditingController();
    priceController = TextEditingController();
    _loadPatients();
  }

  @override
  void onClose() {
    patientNameController.dispose();
    priceController.dispose();
    super.onClose();
  }

  Future<void> _loadPatients() async {
    patients.assignAll(await DatabaseService.instance.getPatients());
    if (patient != null) {
      selectedPatientId.value = patient!['id']?.toString() ?? '';
      return;
    }

    selectedPatientId.value = patients.isNotEmpty
        ? patients.first['id']?.toString() ?? ''
        : '';

    if (selectedPatientId.value.isNotEmpty) {
      await loadLatestTreatments(selectedPatientId.value);
    }
  }

  Future<void> loadLatestTreatments(String patientId) async {
    final invoice =
        await DatabaseService.instance.getLatestInvoiceByPatientId(patientId);
    if (invoice == null) return;

    final treatmentText = invoice['type_of_treatment']?.toString() ?? '';
    selectedTreatments.assignAll(
      treatmentText.split(' , ').where((e) => e.trim().isNotEmpty).toList(),
    );
    _syncPriceFromTreatments();
  }

  void selectTreatment(String name) {
    if (selectedTreatments.contains(name)) {
      selectedTreatments.remove(name);
    } else {
      selectedTreatments.add(name);
    }
    _syncPriceFromTreatments();
  }

  void _syncPriceFromTreatments() {
    final total = sumTreatmentPrices(selectedTreatments);
    priceController.text = total > 0 ? total.toStringAsFixed(0) : '';
  }

  Future<String?> resolvePatientId() async {
    if (patient != null) {
      return patient!['id']?.toString();
    }

    if (inputMode.value) {
      return getOrCreatePatient(patientNameController.text);
    }

    final id = selectedPatientId.value.trim();
    return id.isEmpty ? null : id;
  }

  Future<String?> getOrCreatePatient(String fullName) async {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      Get.snackbar('خطأ', 'يجب إدخال اسم المريض');
      return null;
    }

    final patientList = await DatabaseService.instance.getPatients();
    final found = patientList.firstWhereOrNull((p) {
      final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
          .trim()
          .toLowerCase();
      return name == trimmed.toLowerCase();
    });

    if (found != null) {
      return found['id']?.toString();
    }

    final names = trimmed.split(' ');
    final firstName = names.isNotEmpty ? names.first : '';
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

    await DatabaseService.instance.addPatient({
      'first_name': firstName,
      'last_name': lastName,
      'phone': '',
    });

    final refreshed = await DatabaseService.instance.getPatients();
    final created = refreshed.firstWhereOrNull((p) {
      final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
          .trim()
          .toLowerCase();
      return name == trimmed.toLowerCase();
    });

    return created?['id']?.toString();
  }

  Future<void> save() async {
    final patientId = await resolvePatientId();
    final result = tryParseInvoiceForm(
      patientId: patientId,
      selectedTreatments: selectedTreatments.toList(),
      priceText: priceController.text,
      isEstimated: isEstimated.value,
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
      await invoicesController.createInvoice(result.values!);
      Get.back();
      Get.snackbar(
        'نجح',
        'تم حفظ الفاتورة بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } finally {
      saving.value = false;
    }
  }
}
