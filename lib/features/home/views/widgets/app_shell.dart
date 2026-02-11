import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dental_managment_system/assets/assets.dart';
import 'package:dental_managment_system/core/colors.dart';
import 'package:dental_managment_system/features/home/views/dashboard_page.dart';
import 'package:dental_managment_system/features/home/views/widgets/custome_window_bar.dart';
import 'package:dental_managment_system/features/home/views/widgets/daily_notifications_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../appointment_manage/views/appointments_page.dart';
import '../../../patient_manage/views/patients_page.dart';
import '../../../billing_manage/views/invoices_page.dart';
import '../../../inventory_manage/views/inventory_page.dart';
import '../../../inventory_manage/views/daily_inventory_page.dart';
import '../../../settings_manage/views/settings_page.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/dash_board_controller.dart';
import 'dart:io' show Platform;

class AppShell extends StatelessWidget {
  AppShell({super.key});
  final dashBoardController = Get.put(
    DashBoardController(),
    permanent: false,
    builder: () {
      tag = UniqueKey().toString();
      return DashBoardController();
    },
    tag: tag,
  );
  @override
  Widget build(BuildContext context) {
    final nav = Get.put(NavigationController());
    // dailyInventoryController.getTodaySummary();
    return Scaffold(
      body: Column(
        children: [
          if (Platform.isWindows) const CustomWindowBar(),
          _topNavigationBar(nav, context),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Obx(() {
                    final index = nav.selectedIndex.value;
                    if (index == 0) return DashboardPage();
                    if (index == 1) return PatientsPage();
                    if (index == 2) return AppointmentsPage();
                    if (index == 3) return InvoicesPage();
                    if (index == 4) return InventoryPage();
                    if (index == 5) return DailyInventoryPage();
                    if (index == 6) return SettingsPage();
                    return const SizedBox();
                  }),
                ),
                Expanded(child: DailyNotificationsDrawer()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topNavigationBar(NavigationController nav, BuildContext context) {
    return Obx(() {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Row(
          children: [
            Image.asset(Assets.of(context).logo_png, width: 120.w),
            SizedBox(width: 20.w),
            _navItem(nav, 0, "الرئيسية ", Assets.of(context).icons.home_png),
            _navItem(
              nav,
              1,
              "المرضى",
              Assets.of(context).icons.health_struct_png,
            ),
            _navItem(
              nav,
              2,
              "المعاينات",
              Assets.of(context).icons.calendar_png,
            ),
            _navItem(nav, 3, "الفواتير", Assets.of(context).icons.invoice_png),
            _navItem(nav, 4, "المخزن", Assets.of(context).icons.supply_png),
            _navItem(nav, 5, "الجرد ", Assets.of(context).icons.supply_png),
            _navItem(
              nav,
              6,
              "الاعدادات",
              Assets.of(context).icons.settings_png,
            ),
            const Spacer(),
            // 💰 صناديق الإحصائيات المالية
            _statBox(
              'صافي الربح الشهري',
              '${dashBoardController.monthlyNetProfit.value.toStringAsFixed(0)} ل.س',
              Colors.green,
            ),
            SizedBox(width: 15.w),
            _statBox(
              'الربح الشهري',
              '${dashBoardController.monthlyProfit.value.toStringAsFixed(0)} ل.س',
              Colors.blue,
            ),
            SizedBox(width: 15.w),
            _statBox(
              'المبلغ المدفوع',
              '${dashBoardController.monthlyPaid.value.toStringAsFixed(0)} ل.س',
              Colors.orange,
            ),
            SizedBox(width: 20.w),
          ],
        ),
      );
    });
  }

  Widget _navItem(
    NavigationController nav,
    int index,
    String label,
    String icon,
  ) {
    final isSelected = nav.selectedIndex.value == index;
    return GestureDetector(
      onTap: () => nav.select(index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => nav.isHovered(true),
        onExit: (_) => nav.isHovered(false),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.mainColor.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: isSelected ? 1 : 0.1,
                child: Image.asset(icon, width: isSelected ? 38.w : 32.w),
              ),
              SizedBox(width: 8.w),
              AutoSizeText(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.mainColor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 صندوق إحصائي للمؤشرات المالية
  Widget _statBox(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          AutoSizeText(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
