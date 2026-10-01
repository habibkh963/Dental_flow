import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/dash_board_controller.dart';
import 'dashboard_kpi_chip.dart';

class DashboardStatStrip extends GetView<DashBoardController> {
  const DashboardStatStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نظرة سريعة',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                DashboardKpiChip(
                  title: 'المرضى',
                  value: controller.numberOfPatients.value.toString(),
                  icon: Icons.people_outline,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                DashboardKpiChip(
                  title: 'معاينات اليوم',
                  value: controller.appointmentsToday.value.toString(),
                  icon: Icons.event_outlined,
                  color: Colors.teal,
                  hasAlert: controller.hasUrgentAppointments.value,
                ),
                const SizedBox(width: 8),
                DashboardKpiChip(
                  title: 'مخزون منخفض',
                  value: controller.lowStockCount.value.toString(),
                  icon: Icons.inventory_2_outlined,
                  color: Colors.orange,
                  hasAlert: controller.hasLowStock.value,
                  subtitle: controller.hasLowStock.value
                      ? 'يحتاج متابعة'
                      : null,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
