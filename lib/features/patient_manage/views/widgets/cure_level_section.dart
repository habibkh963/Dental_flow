import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../../settings_manage/controllers/treatment_catalog_controller.dart';
import '../../../shared/widgets/treatment_presentation_picker.dart';
import '../../controller/patient_profile_controller.dart';
import 'condition_cure_table.dart';

class CureLevelSection extends StatelessWidget {
  const CureLevelSection({super.key, required this.controller});

  final PatientProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final untracked = controller.untrackedPlannedTreatments;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'مراحل العلاج / تتبع الحالات',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainColor,
                ),
              ),
              const Spacer(),
              if (untracked.isNotEmpty)
                TextButton.icon(
                  onPressed: () => controller.syncAllPlannedTreatments(),
                  icon: const Icon(Icons.sync, size: 18),
                  label: Text(
                    'مزامنة الخطة',
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                ),
              FilledButton.icon(
                onPressed: () => _openAddConditionDialog(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'إضافة حالة',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'جدول متابعة لكل نوع تمثيل/علاج (من خطة المريض: فك سفلي، زراعة، تقويم...) — أضف صفاً في كل زيارة.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          if (controller.plannedTreatments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: controller.plannedTreatments.map((label) {
                final tracked = controller.conditions.any(
                  (c) => c.conditionName.toLowerCase() == label.toLowerCase(),
                );
                return Chip(
                  label: Text(label, style: GoogleFonts.poppins(fontSize: 10)),
                  backgroundColor: tracked
                      ? AppColors.mainColor.withValues(alpha: 0.12)
                      : Colors.orange.shade50,
                  side: BorderSide(
                    color: tracked
                        ? AppColors.mainColor.withValues(alpha: 0.4)
                        : Colors.orange.shade300,
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          if (controller.conditions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                controller.plannedTreatments.isEmpty
                    ? 'سجّل خطة التمثيل/العلاج في بيانات المريض أولاً، أو أضف حالة يدوياً.'
                    : 'اضغط «مزامنة الخطة» أو «إضافة حالة» لبدء جداول المتابعة.',
                style: GoogleFonts.poppins(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...controller.conditions.map(
              (condition) => ConditionCureTable(
                controller: controller,
                condition: condition,
                entries: controller.progressFor(condition.id),
              ),
            ),
        ],
      );
    });
  }

  Future<void> _openAddConditionDialog(BuildContext context) async {
    final selected = <String>[];
    final customController = TextEditingController();

    final tracked = controller.conditions
        .map((c) => c.conditionName.toLowerCase())
        .toSet();

    final fromPlan = controller.plannedTreatments
        .where((d) => !tracked.contains(d.toLowerCase()))
        .toList();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            'إضافة حالة للمتابعة',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (fromPlan.isNotEmpty) ...[
                    Text(
                      'من خطة التمثيل/العلاج للمريض',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: fromPlan.map((name) {
                        final isSelected = selected.contains(name);
                        return FilterChip(
                          label: Text(
                            name,
                            style: GoogleFonts.poppins(fontSize: 11),
                          ),
                          selected: isSelected,
                          onSelected: (value) {
                            setLocal(() {
                              if (value) {
                                if (!selected.contains(name)) {
                                  selected.add(name);
                                }
                              } else {
                                selected.remove(name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TreatmentPresentationPicker(
                    title: 'أو اختر نوع تمثيل/علاج',
                    options: Get.find<TreatmentCatalogController>().planNames,
                    emptyHint:
                        'أضف خطط العلاج من الإعدادات ← خطط العلاج والأسعار',
                    selected: selected,
                    allowMultiple: true,
                    customController: customController,
                    customHint: 'أو اكتب حالة متابعة مخصصة...',
                    onChanged: (list) {
                      setLocal(() {
                        selected
                          ..clear()
                          ..addAll(list);
                      });
                    },
                  ),
                  if (controller.plannedTreatments.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'لم تُسجَّل خطة علاج للمريض — يمكنك الاختيار من القائمة أو الكتابة.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.poppins()),
            ),
            FilledButton(
              onPressed: () async {
                final names = List<String>.from(selected);
                final custom = customController.text.trim();
                if (custom.isNotEmpty && !names.contains(custom)) {
                  names.add(custom);
                }
                if (names.isEmpty) return;

                for (final name in names) {
                  await controller.addCondition(name);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mainColor,
              ),
              child: Text('إضافة', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );

    customController.dispose();
  }
}
