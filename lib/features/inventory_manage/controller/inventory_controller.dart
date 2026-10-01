import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../../../services/database_service.dart';
import '../models/inventory_item.dart';
import '../utils/inventory_input.dart';
import '../views/widgets/inventory_item_dialog.dart';
import 'inventory_item_dialog_controller.dart';

class InventoryController extends GetxController {
  final filteredItems = <InventoryItem>[].obs;
  final loading = false.obs;
  final searchQuery = ''.obs;

  final _items = <InventoryItem>[];


  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    try {
      final fetched = await DatabaseService.instance.getInventory();
      _items
        ..clear()
        ..addAll(fetched.map(InventoryItem.fromMap));
      _applyFilter(searchQuery.value);
    } finally {
      loading.value = false;
    }
  }

  void filterInventory(String query) {
    searchQuery.value = query;
    _applyFilter(query);
  }

  Future<void> saveItem(InventoryFormValues values, {String? id}) async {
    final data = {
      'name': values.name,
      'qty': values.quantity,
      'threshold': values.lowStockThreshold,
      'unit': values.unit,
    };

    if (id == null) {
      await DatabaseService.instance.addInventoryItem(data);
    } else {
      await DatabaseService.instance.updateInventoryItem(id, data);
    }
    await fetch();
  }

  Future<void> remove(String id) async {
    await DatabaseService.instance.deleteInventoryItem(id);
    await fetch();
  }

  void openAddDialog() => _openItemDialog();

  void openEditDialog(InventoryItem item) => _openItemDialog(existing: item);

  Future<void> confirmDelete(InventoryItem item) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('حذف ${item.name}؟', style: GoogleFonts.poppins()),
        content: Text(
          'هل أنت متأكد من حذف هذا العنصر من المخزون؟',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('الغاء', style: GoogleFonts.poppins()),
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
      await remove(item.id);
    }
  }

  void _openItemDialog({InventoryItem? existing}) {
    final tag = InventoryItemDialogController.dialogTag;
    if (Get.isRegistered<InventoryItemDialogController>(tag: tag)) {
      Get.delete<InventoryItemDialogController>(tag: tag);
    }

    Get.put(
      InventoryItemDialogController(
        inventoryController: this,
        existing: existing,
      ),
      tag: tag,
    );

    Get.dialog(
      const InventoryItemDialog(),
      barrierDismissible: false,
    ).whenComplete(() {
      if (Get.isRegistered<InventoryItemDialogController>(tag: tag)) {
        Get.delete<InventoryItemDialogController>(tag: tag);
      }
    });
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      filteredItems.assignAll(_items);
      return;
    }

    filteredItems.assignAll(
      _items.where((item) => item.name.toLowerCase().contains(q)).toList(),
    );
  }
}
