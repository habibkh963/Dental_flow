import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controller/daily_inventory_controller.dart';
import '../../utils/daily_inventory_date.dart';
import '../../utils/money_format.dart';

class DailyPeriodBanner extends StatelessWidget {
  const DailyPeriodBanner({super.key, required this.controller});

  final DailyInventoryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isFilterActive.value) return const SizedBox.shrink();

      final summary = controller.periodFilterSummary.value;
      final range = normalizeRange(
        controller.selectedStartDate.value,
        controller.selectedEndDate.value,
      );

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.mainColor.withOpacity(0.08),
              AppColors.mainColor.withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.mainColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ملخص الفترة (${formatDisplayDate(range.$1)} – ${formatDisplayDate(range.$2)})',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _chip(
                  'مدفوعات (${summary.paymentsCount})',
                  formatMoney(summary.paymentsTotal),
                  Colors.green,
                ),
                _chip(
                  'مخرجات (${summary.outputsCount})',
                  formatMoney(summary.expensesTotal),
                  Colors.red,
                ),
                _chip(
                  'صافي الفترة',
                  formatMoney(summary.netTotal),
                  summary.netTotal >= 0 ? Colors.teal : Colors.red,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _chip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
