import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../../../core/currency_utils.dart';
import '../../settings_manage/controllers/app_currency_controller.dart';
import '../../billing_manage/views/widgets/billing_form_field.dart';
import '../../inventory_manage/views/widgets/inventory_form_field.dart';

enum AmountFieldStyle { billing, inventory }

class AmountWithCurrencyField extends StatelessWidget {
  const AmountWithCurrencyField({
    super.key,
    required this.amountController,
    required this.selectedCurrencyCode,
    required this.onCurrencyChanged,
    this.label = 'المبلغ',
    this.style = AmountFieldStyle.inventory,
    this.onAmountChanged,
  });

  final TextEditingController amountController;
  final String selectedCurrencyCode;
  final ValueChanged<String> onCurrencyChanged;
  final String label;
  final AmountFieldStyle style;
  final ValueChanged<String>? onAmountChanged;

  InputDecoration _decoration() {
    final suffix = currencySuffixFor(selectedCurrencyCode);
    final hint = style == AmountFieldStyle.billing
        ? '$label ($suffix)'
        : '$label ($suffix)';
    return style == AmountFieldStyle.billing
        ? billingFieldDecoration(hint)
        : inventoryFieldDecoration(hint);
  }

  @override
  Widget build(BuildContext context) {
    final initial = Get.isRegistered<AppCurrencyController>()
        ? Get.find<AppCurrencyController>().code.value
        : 'SYP';
    final active = selectedCurrencyCode.isNotEmpty
        ? selectedCurrencyCode
        : initial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'العملة',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: kInputCurrencyCodes.map((code) {
            final isSelected = active == code;
            final label =
                code == 'SYP' ? 'ل.س (SYP)' : r'$ (USD)';
            return ChoiceChip(
              label: Text(label, style: GoogleFonts.poppins(fontSize: 11)),
              selected: isSelected,
              selectedColor: AppColors.mainColor.withValues(alpha: 0.2),
              onSelected: (_) => onCurrencyChanged(code),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: _decoration(),
          onChanged: onAmountChanged,
        ),
      ],
    );
  }
}