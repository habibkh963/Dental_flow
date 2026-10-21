import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../../../core/patient_medical_conditions.dart';
import '../../../settings_manage/controllers/treatment_catalog_controller.dart';
import '../../../shared/widgets/treatment_presentation_picker.dart';
import '../../controller/patients_controller.dart';
import '../../utils/patient_treatment_plan_utils.dart';

Future<void> openPatientDialog(
  BuildContext context,
  PatientsController controller, {
  Map<String, dynamic>? existing,
}) async {
  final isEdit = existing != null;

  final first = TextEditingController(text: existing?['first_name'] ?? '');
  final last = TextEditingController(text: existing?['last_name'] ?? '');
  final phone = TextEditingController(text: existing?['phone'] ?? '');
  final email = TextEditingController(text: existing?['email'] ?? '');
  final address = TextEditingController(text: existing?['address'] ?? '');

  if (!Get.isRegistered<TreatmentCatalogController>()) {
    Get.put(TreatmentCatalogController(), permanent: true);
  }
  final treatmentCatalog = Get.find<TreatmentCatalogController>();
  final treatmentOptions = treatmentCatalog.planNames;

  final selectedDiseases = parseMedicalConditions(
    existing?['diseases']?.toString(),
  );
  final diseaseSuggestions = <String>[
    ...kMedicalConditionSuggestions,
    ...selectedDiseases.where((d) => !kMedicalConditionSuggestions.contains(d)),
  ];

  final customDiseaseController = TextEditingController();
  final customTreatmentController = TextEditingController();

  final selectedTreatments = parseTreatmentPlanItems(
    existing?['treatment_plan']?.toString(),
    excludeLabels: selectedDiseases,
  );

  await showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: MediaQuery.widthOf(context) * 0.7,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.95),
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEdit ? "تعديل المريض" : "إضافة مريض ",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _field(first, "الاسم الأول"),
                    const SizedBox(height: 12),
                    _field(last, "الكنية"),
                    const SizedBox(height: 12),
                    _field(phone, "رقم الهاتف"),
                    const SizedBox(height: 12),
                    _field(email, "البريد الالكتروني"),
                    const SizedBox(height: 12),
                    _field(address, "العنوان", maxLines: 2),
                    const SizedBox(height: 18),

                    TreatmentPresentationPicker(
                      title: 'خطة التمثيل / العلاج',
                      options: treatmentOptions,
                      emptyHint:
                          'أضف خطط العلاج من الإعدادات ← خطط العلاج والأسعار',
                      selected: selectedTreatments,
                      allowMultiple: true,
                      customController: customTreatmentController,
                      customHint: 'أو اكتب خطة علاج مخصصة...',
                      onChanged: (list) {
                        final diseaseSet = selectedDiseases
                            .map((d) => d.toLowerCase())
                            .toSet();
                        selectedTreatments
                          ..clear()
                          ..addAll(
                            list.where(
                              (item) =>
                                  !diseaseSet.contains(item.toLowerCase()),
                            ),
                          );
                        (ctx as Element).markNeedsBuild();
                      },
                    ),

                    const SizedBox(height: 18),

                    /// Diseases Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'الحالات الطبية الخاصة',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'للتاريخ الطبي فقط — لا تُضاف إلى خطة العلاج ولا للفواتير.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Input to add custom disease
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customDiseaseController,
                            decoration: _dec('اختر الحالات  (اضغط للاضافة +)'),
                            onSubmitted: (val) {
                              final v = val.trim();
                              if (v.isEmpty) return;
                              if (!selectedDiseases.contains(v)) {
                                selectedDiseases.add(v);
                              }
                              if (!diseaseSuggestions.contains(v)) {
                                diseaseSuggestions.add(v);
                              }
                              customDiseaseController.clear();
                              (ctx as Element).markNeedsBuild();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.mainColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              final v = customDiseaseController.text.trim();
                              if (v.isEmpty) return;
                              if (!selectedDiseases.contains(v)) {
                                selectedDiseases.add(v);
                              }
                              if (!diseaseSuggestions.contains(v)) {
                                diseaseSuggestions.add(v);
                              }
                              customDiseaseController.clear();
                              (ctx as Element).markNeedsBuild();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: diseaseSuggestions.map((disease) {
                        final isSelected = selectedDiseases.contains(disease);
                        return FilterChip(
                          label: Text(
                            disease,
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.mainColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedDiseases.add(disease);
                              } else {
                                selectedDiseases.remove(disease);
                              }
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.mainColor,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.mainColor
                                : AppColors.mainColor.withOpacity(0.3),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text("الغاء"),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                          ),
                          onPressed: () async {
                            final diseaseSet = selectedDiseases
                                .map((d) => d.toLowerCase())
                                .toSet();
                            final plans = List<String>.from(selectedTreatments);
                            final customPlan = customTreatmentController.text
                                .trim();
                            if (customPlan.isNotEmpty &&
                                !plans.contains(customPlan) &&
                                !diseaseSet.contains(
                                  customPlan.toLowerCase(),
                                )) {
                              plans.add(customPlan);
                            }
                            plans.removeWhere(
                              (p) => diseaseSet.contains(p.toLowerCase()),
                            );
                            final data = {
                              'first_name': first.text.trim(),
                              'last_name': last.text.trim(),
                              'phone': phone.text.trim(),
                              'email': email.text.trim(),
                              'address': address.text.trim(),
                              'diseases': selectedDiseases.join(', '),
                              'treatment_plan': plans.join('، '),
                            };

                            if (isEdit) {
                              await controller.updatePatient(
                                existing['id'],
                                data,
                              );
                            } else {
                              await controller.add(data);
                            }

                            Get.back();
                          },
                          child: const Text('حفظ'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

InputDecoration _dec(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  ),
);

Widget _field(TextEditingController c, String hint, {int maxLines = 1}) {
  return TextField(controller: c, maxLines: maxLines, decoration: _dec(hint));
}
