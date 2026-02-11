import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/database_service.dart';

class InvoiceDialogController extends GetxController {
  final qty = 1.obs;
  final price = 0.0.obs;
  final isEstimated = false.obs;
  final payAmount = 0.0.obs;
  RxString pID = ''.obs;
  final patients = <Map<String, dynamic>>[].obs;
  final treatmentTypeMethod = ''.obs;
  final RxList<String> selectedTreatment = <String>[].obs;
  final inputMode = false.obs; // false = dropdown, true = manual input
  late TextEditingController patientNameController;

  final treatments = [
    {'name': 'كشفية', 'price': 5000},
    {'name': 'حشو عادي', 'price': 15000},
    {'name': 'حشو عصب', 'price': 40000},
    {'name': 'قلع سن', 'price': 20000},
    {'name': 'تنظيف', 'price': 25000},
    {'name': 'تقويم (تقديري)', 'price': 150000},
  ];

  double get total => qty.value * price.value;

  Future<void> fetchPatients() async {
    patients.value = await DatabaseService.instance.getPatients();
    log(patients.toString());
    pID.value = patients.firstOrNull?['id'] ?? '';
    if (pID.value.isNotEmpty) {
      fetchTreatment();
    }

    log(patients.toString());
  }

  void fetchTreatment() async {
    final invoice = await DatabaseService.instance.getInvoice(pID.value);

    if (invoice != null) {
      treatmentTypeMethod.value = invoice['type_of_treatment'] ?? '';
      selectedTreatment.value = treatmentTypeMethod.value
          .split(' , ')
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
  }

  void selectTreatment(Map t) {
    final name = t['name'];

    if (selectedTreatment.contains(name)) {
      selectedTreatment.remove(name);
    } else {
      selectedTreatment.add(name);
    }

    // إعادة بناء النص
    treatmentTypeMethod.value = selectedTreatment.join(' , ');
  }

  /// 🔍 البحث عن مريض أو إنشاء جديد بناءً على الاسم
  Future<String?> getOrCreatePatient(String fullName) async {
    if (fullName.trim().isEmpty) {
      Get.snackbar('خطأ', 'يجب إدخال اسم المريض');
      return null;
    }

    // البحث عن المريض
    final patientList = await DatabaseService.instance.getPatients();
    final foundPatient = patientList.firstWhereOrNull((p) {
      final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
          .trim()
          .toLowerCase();
      return name == fullName.trim().toLowerCase();
    });

    if (foundPatient != null) {
      return foundPatient['id'];
    }

    // إنشاء مريض جديد إذا لم يوجد
    final names = fullName.trim().split(' ');
    final firstName = names.isNotEmpty ? names.first : '';
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

    await DatabaseService.instance.addPatient({
      'first_name': firstName,
      'last_name': lastName,
      'phone': '',
    });

    // إعادة جلب المرضى
    await fetchPatients();

    // البحث عن المريض الجديد
    final newPatientList = await DatabaseService.instance.getPatients();
    final newPatient = newPatientList.firstWhereOrNull((p) {
      final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
          .trim()
          .toLowerCase();
      return name == fullName.trim().toLowerCase();
    });

    return newPatient?['id'];
  }

  @override
  void onInit() {
    super.onInit();
    patientNameController = TextEditingController();
    fetchPatients();
  }

  @override
  void onClose() {
    patientNameController.dispose();
    super.onClose();
  }
}
