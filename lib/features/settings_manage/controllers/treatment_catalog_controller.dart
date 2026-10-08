import 'package:get/get.dart';

import '../../../core/models/treatment_catalog_item.dart';
import '../../../services/treatment_catalog_service.dart';

class TreatmentCatalogController extends GetxController {
  final items = <TreatmentCatalogItem>[].obs;
  final loading = true.obs;

  List<String> get planNames =>
      items.map((e) => e.name).where((n) => n.trim().isNotEmpty).toList();

  List<Map<String, dynamic>> get forBilling => items
      .map((e) => {'name': e.name, 'price': e.price})
      .toList();

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    loading.value = true;
    try {
      items.assignAll(await TreatmentCatalogService.instance.load());
    } finally {
      loading.value = false;
    }
  }

  Future<void> persist() async {
    await TreatmentCatalogService.instance.save(items.toList());
  }

  Future<void> addItem({required String name, required double price}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (items.any(
      (e) => e.name.trim().toLowerCase() == trimmed.toLowerCase(),
    )) {
      return;
    }
    items.add(
      TreatmentCatalogItem(
        id: TreatmentCatalogService.newItemId(),
        name: trimmed,
        price: price,
      ),
    );
    await persist();
  }

  Future<void> updateItem(
    String id, {
    required String name,
    required double price,
  }) async {
    final index = items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    items[index] = items[index].copyWith(
      name: name.trim(),
      price: price,
    );
    await persist();
  }

  Future<void> removeItem(String id) async {
    items.removeWhere((e) => e.id == id);
    await persist();
  }
}
