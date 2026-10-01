import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/colors.dart';
import '../../controllers/appointment_dialog_controller.dart';
import '../../models/appointment_status.dart';
import 'appointment_form_field.dart';

class AppointmentDialogWidget extends StatelessWidget {
  const AppointmentDialogWidget({
    super.key,
    required this.dialogController,
  });

  final AppointmentDialogController dialogController;

  @override
  Widget build(BuildContext context) {
    final c = dialogController;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 540,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.isEdit ? 'تعديل المعاينة' : 'معاينة جديدة',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A9D8F),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(() {
                    c.appointmentsController.patients.length;
                    return DropdownButtonFormField<String>(
                      value: c.selectedPatientId.value.isEmpty
                          ? null
                          : c.selectedPatientId.value,
                      hint: Text('اختر المريض', style: GoogleFonts.poppins()),
                      decoration: appointmentFieldDecoration(),
                      items: c.appointmentsController.patients
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p['id']?.toString(),
                              child: Text(
                                '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'
                                    .trim(),
                                style: GoogleFonts.poppins(
                                  color: AppColors.approvedColor,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          c.selectedPatientId.value = value;
                          c.clearFormError();
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                  Obx(
                    () => Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => c.pickDate(context),
                            icon: const Icon(Icons.calendar_today,
                                color: Color(0xFF2A9D8F)),
                            label: Text(
                              c.selectedDate.value == null
                                  ? 'اختر التاريخ'
                                  : DateFormat('yyyy-MM-dd').format(
                                      c.selectedDate.value!,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => c.pickTime(context),
                            icon: const Icon(
                              Icons.access_time,
                              color: Color(0xFF2A9D8F),
                            ),
                            label: Text(
                              c.selectedTime.value == null
                                  ? 'اختر الوقت'
                                  : c.selectedTime.value!.format(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(() {
                    final error = c.formError.value;
                    if (error == null) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cancelledColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.cancelledColor.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        error,
                        style: GoogleFonts.poppins(
                          color: AppColors.cancelledColor,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: c.uiStatus.value,
                      decoration: appointmentFieldDecoration(),
                      items: kAppointmentStatusOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option.$1,
                              child: Text(
                                option.$2,
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          c.uiStatus.value = value;
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    if (!c.showMaterials) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() {
                          c.appointmentsController.inventory.length;
                          return DropdownButtonFormField<String>(
                            value: c.selectedMaterialId.value,
                            hint: Text(
                              'اختر المادة',
                              style: GoogleFonts.poppins(),
                            ),
                            decoration: appointmentFieldDecoration(),
                            items: c.appointmentsController.inventory
                                .map(
                                  (m) => DropdownMenuItem<String>(
                                    value: m['id']?.toString(),
                                    child: Text(
                                      '${m['name']} (المخزون: ${m['qty']})',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                c.selectedMaterialId.value = value,
                          );
                        }),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: appointmentFieldDecoration(
                                  hint: 'الكمية',
                                ),
                                onChanged: (value) {
                                  c.selectedQuantity.value =
                                      int.tryParse(value)?.clamp(1, 9999) ?? 1;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2A9D8F),
                              ),
                              onPressed: c.addMaterial,
                              child: Text(
                                'إضافة',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          if (c.selectedMaterials.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المواد المستخدمة',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...c.selectedMaterials.asMap().entries.map((entry) {
                                final material = entry.value;
                                final item = c.appointmentsController.inventory
                                    .firstWhereOrNull(
                                  (i) =>
                                      i['id']?.toString() ==
                                      material['material_id']?.toString(),
                                );
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '${item?['name'] ?? 'مادة'} × ${material['quantity']}',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        c.removeMaterial(entry.key),
                                  ),
                                );
                              }),
                            ],
                          );
                        }),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),
                  TextField(
                    controller: c.notesController,
                    maxLines: 3,
                    decoration: appointmentFieldDecoration(hint: 'الملاحظات...'),
                  ),
                  const SizedBox(height: 28),
                  Obx(() {
                    final saving = c.saving.value;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text('الغاء', style: GoogleFonts.poppins()),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2A9D8F),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                          ),
                          onPressed:
                              saving ? null : () => c.save(context),
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('حفظ', style: GoogleFonts.poppins()),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
