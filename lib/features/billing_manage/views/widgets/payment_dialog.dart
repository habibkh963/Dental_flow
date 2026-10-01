import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/colors.dart';
import '../../controllers/payment_dialog_controller.dart';
import '../../utils/billing_input.dart';
import 'billing_form_field.dart';

class PaymentDialog extends GetView<PaymentDialogController> {
  const PaymentDialog({super.key});

  @override
  String? get tag => PaymentDialogController.dialogTag;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
          width: MediaQuery.sizeOf(context).width * 0.55,
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            if (controller.loading.value) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'فاتورة المريض: ${controller.patientName}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'رقم الفاتورة: ${controller.invoice.id}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (controller.invoice.typeOfTreatment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'العلاج: ${controller.invoice.typeOfTreatment}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _BalanceSummary(controller: controller),
                  const SizedBox(height: 24),
                  if (controller.remainingBalance.value > 0) ...[
                    Text(
                      'إضافة دفعة',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.amountController,
                            decoration: billingFieldDecoration('المبلغ'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: controller.fillRemainingAmount,
                          child: Text(
                            'المتبقي كاملاً',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                      ],
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: Get.back,
                          child: Text('إغلاق', style: GoogleFonts.poppins()),
                        ),
                        const SizedBox(width: 8),
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
                                : Text('تسجيل الدفع', style: GoogleFonts.poppins()),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
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
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: Get.back,
                        child: Text('إغلاق', style: GoogleFonts.poppins()),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
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
                          '${payment.amount.toStringAsFixed(2)} ل.س',
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
            );
          }),
        ),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({required this.controller});

  final PaymentDialogController controller;

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
            '${controller.totalAmount.value.toStringAsFixed(2)} ل.س',
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'المبلغ المتبقي',
            '${controller.remainingBalance.value.toStringAsFixed(2)} ل.س',
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
