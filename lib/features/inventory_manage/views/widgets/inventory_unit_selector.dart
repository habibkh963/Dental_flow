import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../models/inventory_item.dart';
import 'inventory_form_field.dart';

class InventoryUnitSelector extends StatelessWidget {
  const InventoryUnitSelector({
    super.key,
    required this.selectedUnit,
    required this.useCustomUnit,
    required this.customUnitController,
    required this.onPresetSelected,
    required this.onCustomSelected,
    this.onCustomChanged,
  });

  final RxString selectedUnit;
  final RxBool useCustomUnit;
  final TextEditingController customUnitController;
  final ValueChanged<String> onPresetSelected;
  final VoidCallback onCustomSelected;
  final ValueChanged<String>? onCustomChanged;

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
                  selected: !useCustomUnit.value && selectedUnit.value == unit,
                  onSelected: (_) => onPresetSelected(unit),
                  selectedColor: AppColors.mainColor.withValues(alpha: 0.2),
                ),
              ),
              ChoiceChip(
                label: Text('أخرى', style: GoogleFonts.poppins(fontSize: 12)),
                selected: useCustomUnit.value,
                onSelected: (_) => onCustomSelected(),
                selectedColor: AppColors.mainColor.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
        Obx(() {
          if (!useCustomUnit.value) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: customUnitController,
              decoration: inventoryFieldDecoration('اسم الوحدة'),
              onChanged: onCustomChanged,
            ),
          );
        }),
      ],
    );
  }
}
