import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../controllers/dash_board_controller.dart';
import 'widgets/dashboard_finance_strip.dart';
import 'widgets/dashboard_stat_strip.dart';
import 'widgets/dashboard_today_appointments.dart';

class DashboardPage extends GetView<DashBoardController> {
  DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        color: AppColors.mainColor,
        onRefresh: controller.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              const DashboardTodayAppointments(),
              const SizedBox(height: 16),
              const DashboardStatStrip(),
              const SizedBox(height: 14),
              const DashboardFinanceStrip(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'الرئيسية',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Obx(() {
          if (!controller.isLoading.value) return const SizedBox.shrink();
          return SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.mainColor,
            ),
          );
        }),
      ],
    );
  }
}
