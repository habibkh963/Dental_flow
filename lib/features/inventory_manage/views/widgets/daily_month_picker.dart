import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controller/daily_inventory_controller.dart';
import '../../utils/daily_inventory_date.dart';

class DailyMonthPicker extends StatelessWidget {
  const DailyMonthPicker({super.key, required this.controller});

  final DailyInventoryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final months = controller.historyMonths;
      if (months.isEmpty) return const SizedBox.shrink();

      final selected = controller.selectedHistoryMonth.value;
      final filterActive = controller.isFilterActive.value;

      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.mainColor.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 16, color: AppColors.mainColor),
                const SizedBox(width: 6),
                Text(
                  'سجل الأشهر',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (filterActive)
                  TextButton(
                    onPressed: controller.resetDateFilter,
                    child: Text(
                      'عرض الكل',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: months.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final month = months[index];
                  final isSelected = selected != null &&
                      isSameMonthReference(startOfMonth(month), selected);

                  return FilterChip(
                    label: Text(
                      formatMonthLabel(month),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: AppColors.mainColor,
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.mainColor
                          : Colors.grey.shade300,
                    ),
                    onSelected: (_) => controller.selectHistoryMonth(month),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
