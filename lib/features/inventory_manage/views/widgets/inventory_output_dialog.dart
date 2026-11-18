import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../../shared/widgets/amount_with_currency_field.dart';
import '../../controller/inventory_output_dialog_controller.dart';
import 'inventory_form_field.dart';
import 'inventory_unit_selector.dart';
import 'styled_inventory_dialog.dart';

class InventoryOutputDialog extends StatelessWidget {
  const InventoryOutputDialog({
    super.key,
    required this.dialogController,
  });

  final InventoryOutputDialogController dialogController;

  @override
  Widget build(BuildContext context) {
    final c = dialogController;

    return styledInventoryDialog(
      title: 'إضافة مخرج جديد',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
              TextField(
                controller: c.itemNameController,
                decoration: inventoryFieldDecoration('اسم المادة / الفاتورة'),
                onChanged: (_) => c.clearFormError(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: c.quantityController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: inventoryFieldDecoration('الكمية'),
                onChanged: (_) => c.clearFormError(),
              ),
              const SizedBox(height: 12),
              InventoryUnitSelector(
                selectedUnit: c.selectedUnit,
                useCustomUnit: c.useCustomUnit,
                customUnitController: c.customUnitController,
                onPresetSelected: c.selectPresetUnit,
                onCustomSelected: c.selectCustomUnit,
                onCustomChanged: (_) => c.clearFormError(),
              ),
              const SizedBox(height: 12),
              Obx(
                () => AmountWithCurrencyField(
                  amountController: c.priceController,
                  selectedCurrencyCode: c.selectedCurrency.value,
                  onCurrencyChanged: (code) => c.selectedCurrency.value = code,
                  label: 'السعر',
                  onAmountChanged: (_) => c.clearFormError(),
                ),
              ),
              Obx(() {
                final error = c.formError.value;
                if (error == null) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cancelledColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.cancelledColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    error,
                    style: GoogleFonts.poppins(
                      color: AppColors.cancelledColor,
                      fontSize: 12,
                    ),
                  ),
                );
              }),
        ],
      ),
      actions: [
        Obx(() {
          final saving = c.saving.value;
          return TextButton(
            onPressed: saving ? null : () => Navigator.of(context).pop(),
            child: Text('إلغاء', style: GoogleFonts.poppins()),
          );
        }),
        Obx(() {
          final saving = c.saving.value;
          return FilledButton(
            onPressed: saving ? null : () => c.submit(context),
            style: FilledButton.styleFrom(backgroundColor: AppColors.mainColor),
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('إضافة', style: GoogleFonts.poppins()),
          );
        }),
      ],
    );
  }
}
