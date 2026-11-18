import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/colors.dart';
import '../../../shared/widgets/amount_with_currency_field.dart';
import '../../controller/clinic_expense_dialog_controller.dart';
import '../../utils/clinic_expense_categories.dart';
import 'inventory_form_field.dart';
import 'styled_inventory_dialog.dart';

class ClinicExpenseDialog extends StatelessWidget {
  const ClinicExpenseDialog({super.key, required this.dialogController});

  final ClinicExpenseDialogController dialogController;

  @override
  Widget build(BuildContext context) {
    final c = dialogController;

    return styledInventoryDialog(
      title: 'إضافة نفقة تشغيل',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: c.selectedCategory.value,
                  decoration: inventoryFieldDecoration('نوع النفقة'),
                  items: ClinicExpenseCategory.all
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.label, style: GoogleFonts.poppins()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) c.selectedCategory.value = v;
                    c.clearFormError();
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: c.descriptionController,
                decoration: inventoryFieldDecoration('الوصف / اسم الفاتورة'),
                onChanged: (_) => c.clearFormError(),
              ),
              const SizedBox(height: 12),
              Obx(
                () => AmountWithCurrencyField(
                  amountController: c.amountController,
                  selectedCurrencyCode: c.selectedCurrency.value,
                  onCurrencyChanged: (code) => c.selectedCurrency.value = code,
                  label: 'المبلغ',
                  onAmountChanged: (_) => c.clearFormError(),
                ),
              ),
              const SizedBox(height: 12),
              GetBuilder<ClinicExpenseDialogController>(
                init: c,
                builder: (_) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('تاريخ النفقة', style: GoogleFonts.poppins()),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(c.expenseDate),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => c.pickDate(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: c.noteController,
                maxLines: 2,
                decoration: inventoryFieldDecoration('ملاحظة (اختياري)'),
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
