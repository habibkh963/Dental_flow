import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controller/daily_inventory_controller.dart';
import '../../utils/daily_inventory_date.dart';

class DailyPeriodFilter extends StatelessWidget {
  const DailyPeriodFilter({super.key, required this.controller});

  final DailyInventoryController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mainColor.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تصفية السجل',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _DateChip(
                    label: 'من',
                    date: controller.selectedStartDate.value,
                    onTap: () => _pickDate(
                      context,
                      initial: controller.selectedStartDate.value,
                      onSelected: (d) => controller.selectedStartDate.value = d,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => _DateChip(
                    label: 'إلى',
                    date: controller.selectedEndDate.value,
                    onTap: () => _pickDate(
                      context,
                      initial: controller.selectedEndDate.value,
                      onSelected: (d) => controller.selectedEndDate.value = d,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: controller.applyDateFilter,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text('تطبيق', style: GoogleFonts.poppins()),
              ),
              const SizedBox(width: 8),
              Obx(
                () => controller.isFilterActive.value
                    ? TextButton(
                        onPressed: controller.resetDateFilter,
                        child: Text('إعادة', style: GoogleFonts.poppins()),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initial,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.day,
      helpText: 'اختر التاريخ',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null) onSelected(picked);
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: AppColors.mainColor),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  formatDisplayDate(date),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
