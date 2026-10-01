import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/colors.dart';
import '../models/inventory_item.dart';
import '../utils/inventory_input.dart';
import 'inventory_controller.dart';

class InventoryItemDialogController extends GetxController {
  static const dialogTag = 'inventory_item_dialog';
  InventoryItemDialogController({
    required this.inventoryController,
    this.existing,
  });

  final InventoryController inventoryController;
  final InventoryItem? existing;

  late final TextEditingController nameController;
  late final TextEditingController qtyController;
  late final TextEditingController thresholdController;
  late final TextEditingController customUnitController;

  final selectedUnit = kDefaultInventoryUnit.obs;
  final useCustomUnit = false.obs;
  final saving = false.obs;
  final unitLabelTick = 0.obs;

  bool get isEdit => existing != null;

  String get effectiveUnit =>
      useCustomUnit.value ? customUnitController.text.trim() : selectedUnit.value;

  @override
  void onInit() {
    super.onInit();
    final item = existing;

    nameController = TextEditingController(text: item?.name ?? '');
    qtyController = TextEditingController(text: item?.quantity.toString() ?? '');
    thresholdController = TextEditingController(
      text: item?.lowStockThreshold.toString() ?? '',
    );
    customUnitController = TextEditingController();

    final unit = item?.unit ?? kDefaultInventoryUnit;
    if (kInventoryUnits.contains(unit)) {
      selectedUnit.value = unit;
    } else {
      selectedUnit.value = kDefaultInventoryUnit;
      useCustomUnit.value = true;
      customUnitController.text = unit;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    qtyController.dispose();
    thresholdController.dispose();
    customUnitController.dispose();
    super.onClose();
  }

  void selectPresetUnit(String unit) {
    useCustomUnit.value = false;
    selectedUnit.value = unit;
    _refreshUnitLabel();
  }

  void selectCustomUnit() {
    useCustomUnit.value = true;
    _refreshUnitLabel();
  }

  void onCustomUnitChanged(String _) => _refreshUnitLabel();

  void _refreshUnitLabel() => unitLabelTick.value++;

  Future<void> save() async {
    final result = tryParseInventoryForm(
      name: nameController.text,
      quantityText: qtyController.text,
      thresholdText: thresholdController.text,
      unit: effectiveUnit,
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
      await inventoryController.saveItem(result.values!, id: existing?.id);
      Get.back();
    } finally {
      saving.value = false;
    }
  }
}
