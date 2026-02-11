import 'dart:developer';

import 'package:get/get.dart';

import '../../../services/database_service.dart';

class PatientsController extends GetxController {
  final patients = <Map<String, dynamic>>[].obs;
  final filteredPatients = <Map<String, dynamic>>[].obs;

  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    final fetchedPatients = await DatabaseService.instance.getPatients();
    patients.assignAll(List<Map<String, dynamic>>.from(fetchedPatients));
    filteredPatients.assignAll(
      List<Map<String, dynamic>>.from(fetchedPatients),
    );

    loading.value = false;
  }

  Future<void> add(Map<String, dynamic> data) async {
    await DatabaseService.instance.addPatient(data);
    await fetch();
  }

  Future<void> updatePatient(String id, Map<String, dynamic> data) async {
    await DatabaseService.instance.updatePatient(id, data);
    await fetch();
  }

  Future<void> remove(String id) async {
    await DatabaseService.instance.deletePatient(id);
    await fetch();
  }
}

extension PatientsSearch on PatientsController {
  /// فلترة الفواتير حسب اسم المريض
  void filterPatients(String query) {
    final q = query.trim().toLowerCase();
    log(filteredPatients.toString());
    if (q.isEmpty) {
      // رجّع القائمة الأصلية
      filteredPatients.assignAll(patients);
    } else {
      filteredPatients.assignAll(
        patients.where((inv) {
          final patientName =
              '${inv['first_name'] ?? ''} ${inv['last_name'] ?? ''}';
          return patientName.toLowerCase().contains(q);
        }).toList(),
      );
    }
  }
}
