import 'package:get/get.dart';

import '../../../services/database_service.dart';

class PatientsController extends GetxController {
  final patients = <Map<String, dynamic>>[].obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    patients.value = await DatabaseService.instance.getPatients();
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
