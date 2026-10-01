import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controllers/invoice_dialog_controller.dart';
import '../../controllers/invoices_controller.dart';
import '../../utils/billing_input.dart';
import 'billing_form_field.dart';

void openInvoiceDialog({Map<String, dynamic>? patient}) {
  const flowTag = 'standalone_invoice_flow';
  if (!Get.isRegistered<InvoicesController>(tag: flowTag)) {
    Get.put(InvoicesController(), tag: flowTag, permanent: false);
  }
  Get.find<InvoicesController>(tag: flowTag)
      .openCreateInvoiceDialog(patient: patient);
}

class InvoiceDialog extends GetView<InvoiceDialogController> {
  const InvoiceDialog({super.key, this.patient});

  final Map<String, dynamic>? patient;

  @override
  String? get tag => InvoiceDialogController.dialogTag;

  @override
  Widget build(BuildContext context) {
    final patientName = patient == null
        ? ''
        : '${patient!['first_name'] ?? ''} ${patient!['last_name'] ?? ''}'.trim();

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient == null ? 'فاتورة جديدة' : 'فاتورة – $patientName',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mainColor,
                ),
              ),
              if (!controller.hasPresetPatient) ...[
                const SizedBox(height: 20),
                Text(
                  'طريقة البحث عن المريض',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.inputMode.value = false,
                          icon: Icon(
                            Icons.list,
                            color: controller.inputMode.value
                                ? AppColors.approvedColor
                                : Colors.white,
                          ),
                          label: Text(
                            'اختيار من القائمة',
                            style: GoogleFonts.poppins(
                              color: controller.inputMode.value
                                  ? AppColors.approvedColor
                                  : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !controller.inputMode.value
                                ? AppColors.approvedColor
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.inputMode.value = true,
                          icon: Icon(
                            Icons.edit,
                            color: !controller.inputMode.value
                                ? AppColors.approvedColor
                                : Colors.white,
                          ),
                          label: Text(
                            'إدخال يدوي',
                            style: GoogleFonts.poppins(
                              color: !controller.inputMode.value
                                  ? AppColors.approvedColor
                                  : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.inputMode.value
                                ? AppColors.approvedColor
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Obx(() {
                  controller.patients.length;
                  if (controller.inputMode.value) {
                    return TextField(
                      controller: controller.patientNameController,
                      decoration: billingFieldDecoration(
                        'اسم المريض (الاسم الأول والأخير)',
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: controller.selectedPatientId.value.isEmpty
                        ? null
                        : controller.selectedPatientId.value,
                    hint: Text('اختر المريض', style: GoogleFonts.poppins()),
                    decoration: billingFieldDecoration('المريض'),
                    items: controller.patients
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p['id']?.toString(),
                            child: Text(
                              '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
                                  .trim(),
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      controller.selectedPatientId.value = value;
                      controller.loadLatestTreatments(value);
                    },
                  );
                }),
              ],
              const SizedBox(height: 20),
              Text(
                'اختيار نوع العلاج',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Obx(
                () => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: kDentalTreatments.map((treatment) {
                    final name = treatment['name'] as String;
                    final isSelected =
                        controller.selectedTreatments.contains(name);

                    return GestureDetector(
                      onTap: () => controller.selectTreatment(name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 150,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.mainColor
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                color:
                                    isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(treatment['price'] as num).toStringAsFixed(0)} ل.س',
                              style: GoogleFonts.poppins(
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey.shade700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller.priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: billingFieldDecoration('السعر الإجمالي (ل.س)'),
              ),
              const SizedBox(height: 12),
              Obx(
                () => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: controller.isEstimated.value,
                  onChanged: (value) =>
                      controller.isEstimated.value = value ?? false,
                  title: Text(
                    'فاتورة تقديرية (مثل التقويم)',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(
                    () => TextButton(
                      onPressed:
                          controller.saving.value ? null : () => Get.back(),
                      child: Text('الغاء', style: GoogleFonts.poppins()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(
                    () => FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        padding: const EdgeInsets.symmetric(horizontal: 26),
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
                          : Text(
                              'احفظ الفاتورة',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
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
