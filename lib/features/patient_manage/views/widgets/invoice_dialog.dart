import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:dental_managment_system/services/database_service.dart';

import '../../../../core/colors.dart';
import '../../controller/profile_invoice.dart';

Future<void> openInvoiceDialog(
  BuildContext context,
  Map<String, dynamic>? patient,
) async {
  final c = Get.put(InvoiceDialogController());
  c.fetchPatients();
  await showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: View.of(context).physicalSize.width * 0.6,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'فاتورة – ${patient == null ? '' : patient['first_name']} ${patient == null ? '' : patient['last_name']}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (patient == null) ...[
              const SizedBox(height: 20),
              Text(
                'طريقة البحث عن المريض',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => ElevatedButton.icon(
                        onPressed: () => c.inputMode.value = false,
                        icon: Icon(
                          Icons.list,
                          color: c.inputMode.value
                              ? AppColors.approvedColor
                              : Colors.white,
                        ),
                        label: Text(
                          'اختيار من القائمة',
                          style: GoogleFonts.poppins(
                            color: c.inputMode.value
                                ? AppColors.approvedColor
                                : Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !c.inputMode.value
                              ? AppColors.approvedColor
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton.icon(
                        onPressed: () => c.inputMode.value = true,
                        icon: Icon(
                          Icons.edit,
                          color: !c.inputMode.value
                              ? AppColors.approvedColor
                              : Colors.white,
                        ),
                        label: Text(
                          'إدخال يدوي',
                          style: GoogleFonts.poppins(
                            color: !c.inputMode.value
                                ? AppColors.approvedColor
                                : Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.inputMode.value
                              ? AppColors.approvedColor
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Obx(() {
                if (c.inputMode.value) {
                  return TextField(
                    controller: c.patientNameController,
                    decoration: _dec('اسم المريض (الاسم الأول والأخير)'),
                  );
                } else {
                  return _PatientDropdown(
                    patients: c.patients,
                    selectedPatientId: c.pID.value,
                    onChanged: (v) {
                      c.pID.value = v!;
                      c.fetchTreatment();
                    },
                  );
                }
              }),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'اختيار نوع العلاج',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),

            Obx(
              () => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: c.treatments.map((t) {
                  final isSelected = c.selectedTreatment.contains(t['name']);

                  return GestureDetector(
                    onTap: () => c.selectTreatment(t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 160,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2A9D8F)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            t['name'].toString(),
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                // Expanded(
                //   child: TextField(
                //     keyboardType: TextInputType.number,
                //     decoration: _dec('Quantity'),
                //     onChanged: (v) => c.qty.value = int.tryParse(v) ?? 1,
                //   ),
                // ),
                // const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    // controller: TextEditingController(
                    //   text: c.price.value.toString(),
                    // ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _dec('السعر'),
                    onChanged: (v) => c.price.value = double.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),

            // const SizedBox(height: 16),

            // Row(
            //   children: [
            //     Expanded(
            //       child: Obx(
            //         () => Text(
            //           'الكلي: ${c.total.toStringAsFixed(0)} SYP',
            //           style: GoogleFonts.poppins(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 16,
            //           ),
            //         ),
            //       ),
            //     ),
            //     // Obx(
            //     //   () => Row(
            //     //     children: [
            //     //       Checkbox(
            //     //         value: c.isEstimated.value,
            //     //         onChanged: (v) => c.isEstimated.value = v!,
            //     //       ),
            //     //       Text('Estimated', style: GoogleFonts.poppins()),
            //     //     ],
            //     //   ),
            //     // ),
            //   ],
            // ),
            const SizedBox(height: 12),

            /// 💾 أزرار
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('الغاء', style: GoogleFonts.poppins()),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9D8F),
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                  ),
                  onPressed: () async {
                    final patientId = patient == null
                        ? (c.inputMode.value
                              ? await c.getOrCreatePatient(
                                  c.patientNameController.text,
                                )
                              : c.pID.value)
                        : patient['id'];

                    if (patientId == null || patientId.isEmpty) {
                      Get.snackbar('خطأ', 'يجب اختيار أو إدخال اسم المريض');
                      return;
                    }

                    log(
                      {
                        'type_of_treatment': c.treatmentTypeMethod.value,
                        'patient_id': patientId,
                        'total': c.total,
                        'status': c.isEstimated.value ? 'estimated' : 'pending',
                      }.toString(),
                    );
                    await DatabaseService.instance.addInvoice({
                      'type_of_treatment': c.treatmentTypeMethod.value,
                      'patient_id': patientId,
                      'total': c.total,
                      'status': c.isEstimated.value ? 'estimated' : 'pending',
                    });

                    Get.back();
                    Get.snackbar(
                      'نجح',
                      'تم حفظ الفاتورة بنجاح',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  child: Text(
                    'احفظ الفاتورة',
                    style: GoogleFonts.poppins(color: Colors.white),
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

InputDecoration _dec(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
);

class _PatientDropdown extends StatelessWidget {
  final List patients;
  final String? selectedPatientId;
  final ValueChanged<String?> onChanged;

  const _PatientDropdown({
    required this.patients,
    required this.selectedPatientId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    log('==> ${patients.toString()}');
    return DropdownButtonFormField<String>(
      value: selectedPatientId,
      hint: Text("اختر المريض", style: GoogleFonts.poppins()),
      decoration: _inputDecoration(),
      items: patients
          .map(
            (p) => DropdownMenuItem<String>(
              value: p['id'],
              child: Text(
                '${(p['first_name'] ?? '')}'
                '${(p['last_name'] ?? '')}',
                style: GoogleFonts.poppins(color: AppColors.approvedColor),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

InputDecoration _inputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
  );
}
