import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controller/daily_inventory_controller.dart';

class DailyPaymentSummaryWidget extends StatelessWidget {
  DailyPaymentSummaryWidget({super.key});

  final DailyInventoryController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.dailyPaymentsList.isEmpty) {
        return const SizedBox.shrink();
      }

      // Get today's payments
      final today = DateTime.now();
      final normalizedToday = DateTime(today.year, today.month, today.day);
      final todayPayments = controller.dailyPaymentsList.where((payment) {
        final date = payment['date'] as DateTime;
        final normalizedDate = DateTime(date.year, date.month, date.day);
        return normalizedDate == normalizedToday;
      }).toList();

      if (todayPayments.isEmpty) {
        return const SizedBox.shrink();
      }

      double totalToday = 0;
      for (var payment in todayPayments) {
        totalToday += (payment['amount'] as double);
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.mainColor, AppColors.mainColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.mainColor.withOpacity(0.3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'الدفعات اليوم',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${totalToday.toStringAsFixed(2)} ل.س',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${todayPayments.length} دفعة',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      );
    });
  }
}
