import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../controller/daily_inventory_controller.dart';
import 'widgets/daily_month_picker.dart';
import '../models/daily_inventory_tab.dart';
import 'widgets/clinic_expenses_section.dart';
import 'widgets/daily_outputs_section.dart';
import 'widgets/daily_payments_list.dart';
import 'widgets/daily_period_banner.dart';
import 'widgets/daily_period_filter.dart';
import 'widgets/daily_summary_grid.dart';
import 'widgets/daily_tab_bar.dart';

class DailyInventoryPage extends GetView<DailyInventoryController> {
  DailyInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(() {
        if (controller.isLoading.value &&
            controller.financialReport.value == null) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.mainColor),
          );
        }

        return RefreshIndicator(
          color: AppColors.mainColor,
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                DailySummaryGrid(controller: controller),

                const SizedBox(height: 16),
                DailyMonthPicker(controller: controller),
                const SizedBox(height: 12),
                DailyTabBar(controller: controller),
                const SizedBox(height: 12),
                DailyPeriodBanner(controller: controller),
                Obx(() {
                  switch (controller.selectedTab.value) {
                    case DailyInventoryTab.payments:
                      return DailyPaymentsList(controller: controller);
                    case DailyInventoryTab.clinicExpenses:
                      return ClinicExpensesSection(controller: controller);
                    case DailyInventoryTab.outputs:
                      return DailyOutputsSection(controller: controller);
                  }
                }),
                const SizedBox(height: 16),

                DailyPeriodFilter(controller: controller),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'الجرد اليومي',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
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
