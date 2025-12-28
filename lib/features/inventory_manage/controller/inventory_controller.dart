import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/database_service.dart';

// Inventoy Controller you provided
class InventoryController extends GetxController {
  final items = <Map<String, dynamic>>[].obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    items.value = await DatabaseService.instance.getInventory();
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
