import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controller/inventory_item_dialog_controller.dart';
import '../../models/inventory_item.dart';
import 'inventory_form_field.dart';

class InventoryItemDialog extends GetView<InventoryItemDialogController> {
  const InventoryItemDialog({super.key});

  @override
  String? get tag => InventoryItemDialogController.dialogTag;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.isEdit
                    ? 'تعديل ${controller.existing!.name}'
                    : 'اضافة منتج جديد',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainColor,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.nameController,
                decoration: inventoryFieldDecoration('اسم المنتج'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.qtyController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: inventoryFieldDecoration('الكمية'),
              ),
              const SizedBox(height: 12),
              _UnitSelector(controller: controller),
              const SizedBox(height: 12),
              Obx(() {
                controller.unitLabelTick.value;
                final unitLabel = controller.useCustomUnit.value
                    ? controller.customUnitController.text.trim()
                    : controller.selectedUnit.value;
                final unit = unitLabel.isEmpty ? 'وحدة' : unitLabel;
                return TextField(
                  controller: controller.thresholdController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: inventoryFieldDecoration(
                    'الحد الأدنى للتنبيه (بال$unit)',
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                'تنبيه: الكمية 0 = نفذ · الكمية ≤ الحد = منخفض · غير ذلك = جيد',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(
                    () => TextButton(
                      onPressed: controller.saving.value ? null : Get.back,
                      child: Text('الغاء', style: GoogleFonts.poppins()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onPressed: controller.saving.value ? null : controller.save,
                      child: controller.saving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('حفظ', style: GoogleFonts.poppins()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitSelector extends StatelessWidget {
  const _UnitSelector({required this.controller});

  final InventoryItemDialogController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الوحدة',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...kInventoryUnits.map(
                (unit) => ChoiceChip(
                  label: Text(unit, style: GoogleFonts.poppins(fontSize: 12)),
                  selected: !controller.useCustomUnit.value &&
                      controller.selectedUnit.value == unit,
                  onSelected: (_) => controller.selectPresetUnit(unit),
                  selectedColor: AppColors.mainColor.withOpacity(0.2),
                ),
              ),
              ChoiceChip(
                label: Text('أخرى', style: GoogleFonts.poppins(fontSize: 12)),
                selected: controller.useCustomUnit.value,
                onSelected: (_) => controller.selectCustomUnit(),
                selectedColor: AppColors.mainColor.withOpacity(0.2),
              ),
            ],
          ),
        ),
        Obx(() {
          if (!controller.useCustomUnit.value) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: controller.customUnitController,
              decoration: inventoryFieldDecoration('اسم الوحدة'),
              onChanged: controller.onCustomUnitChanged,
            ),
          );
        }),
      ],
    );
  }
}
