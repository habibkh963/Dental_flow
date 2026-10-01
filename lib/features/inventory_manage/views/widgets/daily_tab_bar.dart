import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controller/daily_inventory_controller.dart';

class DailyTabBar extends StatelessWidget {
  const DailyTabBar({super.key, required this.controller});

  final DailyInventoryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final showPayments = controller.isIncomes.value;

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _tab(
              label: 'المخرجات',
              selected: !showPayments,
              onTap: () => controller.isIncomes.value = false,
            ),
            _tab(
              label: 'المدفوعات',
              selected: showPayments,
              onTap: () => controller.isIncomes.value = true,
            ),
          ],
        ),
      );
    });
  }

  Expanded _tab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.mainColor : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.approvedColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
