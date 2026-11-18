import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/colors.dart';
import '../../../shared/widgets/amount_with_currency_field.dart';
import '../../../shared/widgets/app_dialog_shell.dart';
import '../../controllers/payment_dialog_controller.dart';
import '../../utils/billing_input.dart';
import 'billing_form_field.dart';
import '../../../inventory_manage/utils/money_format.dart';

class PaymentDialog extends GetView<PaymentDialogController> {
  const PaymentDialog({super.key});

  @override
  String? get tag => PaymentDialogController.dialogTag;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Obx(() {
        if (controller.loading.value) {
          return const AppDialogFrame(
            title: 'دفعات الفاتورة',
            width: 520,
            body: SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final subtitle =
            'رقم الفاتورة: ${controller.invoice.id}'
            '${controller.invoice.typeOfTreatment.isNotEmpty ? ' · ${controller.invoice.typeOfTreatment}' : ''}';

        final invoiceCurrency = controller.invoice.currency;

        return AppDialogFrame(
          title: 'دفعات — ${controller.patientName}',
          subtitle: subtitle,
          width: 520,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BalanceSummary(
                controller: controller,
                currencyCode: invoiceCurrency,
              ),
              if (controller.remainingBalance.value <= 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'تم سداد الفاتورة بالكامل',
                    style: GoogleFonts.poppins(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (controller.remainingBalance.value > 0) ...[
                const SizedBox(height: 20),
                Text(
                  'إضافة دفعة',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => AmountWithCurrencyField(
                    amountController: controller.amountController,
                    selectedCurrencyCode: controller.selectedCurrency.value,
                    onCurrencyChanged: (c) =>
                        controller.selectedCurrency.value = c,
                    label: 'المبلغ',
                    style: AmountFieldStyle.billing,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: controller.fillRemainingAmount,
                    child: Text(
                      'تعبئة المتبقي كاملاً',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.payMethod.value,
                    decoration: billingFieldDecoration('طريقة الدفع'),
                    items: kPaymentMethods
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method, style: GoogleFonts.poppins()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.payMethod.value = value;
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.noteController,
                  maxLines: 3,
                  decoration: billingFieldDecoration('ملاحظة (اختياري)'),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'الدفعات',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (controller.payments.isEmpty)
                Text(
                  'لا يوجد دفعات بعد',
                  style: GoogleFonts.poppins(color: Colors.grey),
                )
              else
                ...controller.payments.map(
                  (payment) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      formatMoney(
                        payment.amount,
                        currencyCode: payment.currency.isNotEmpty
                            ? payment.currency
                            : invoiceCurrency,
                      ),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${payment.method} · ${DateFormat('dd/MM/yyyy HH:mm', 'ar').format(payment.paidAt)}${payment.note.isNotEmpty ? '\n${payment.note}' : ''}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => controller.deletePayment(payment.id),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: Text('إغلاق', style: GoogleFonts.poppins()),
            ),
            if (controller.remainingBalance.value > 0)
              Obx(
                () => FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                  ),
                  onPressed: controller.saving.value
                      ? null
                      : controller.submitPayment,
                  child: controller.saving.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'تسجيل الدفع',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({
    required this.controller,
    required this.currencyCode,
  });

  final PaymentDialogController controller;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mainColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _summaryRow(
            'إجمالي الفاتورة',
            formatMoney(controller.totalAmount.value, currencyCode: currencyCode),
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'المبلغ المتبقي',
            formatMoney(
              controller.remainingBalance.value,
              currencyCode: currencyCode,
            ),
            valueColor: controller.remainingBalance.value <= 0
                ? Colors.green
                : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
