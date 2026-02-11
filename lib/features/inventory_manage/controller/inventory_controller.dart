import 'package:get/get.dart';

import '../../../services/database_service.dart';

// Inventoy Controller you provided
class InventoryController extends GetxController {
  final items = <Map<String, dynamic>>[].obs;
  final filteredInventory = <Map<String, dynamic>>[].obs;

  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;

    final fetchedInventory = await DatabaseService.instance.getInventory();
    items.assignAll(List<Map<String, dynamic>>.from(fetchedInventory));
    filteredInventory.assignAll(
      List<Map<String, dynamic>>.from(fetchedInventory),
    );
    loading.value = false;
  }

  Future<void> add(Map<String, dynamic> data) async {
    await DatabaseService.instance.addInventoryItem(data);
    await fetch();
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await DatabaseService.instance.updateInventoryItem(id, data);
    await fetch();
  }

  Future<void> remove(String id) async {
    await DatabaseService.instance.deleteInventoryItem(id);
    await fetch();
  }
}

extension PatientsSearch on InventoryController {
  /// فلترة الفواتير حسب اسم المريض
  void filterInventory(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      // رجّع القائمة الأصلية
      filteredInventory.assignAll(items);
    } else {
      filteredInventory.assignAll(
        items.where((inv) {
          final patientName = '${inv['name'] ?? ''} ${inv['last_name'] ?? ''}';
          return patientName.toLowerCase().contains(q);
        }).toList(),
      );
    }
  }
}
