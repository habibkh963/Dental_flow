import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dental_managment_system/assets/assets.dart';
import 'package:dental_managment_system/core/colors.dart';
import 'package:dental_managment_system/features/home/views/dashboard_page.dart';
import 'package:dental_managment_system/features/home/views/widgets/custome_window_bar.dart';
import 'package:dental_managment_system/features/home/views/widgets/daily_notifications_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../appointment_manage/views/appointments_page.dart';
import '../../../patient_manage/views/patients_page.dart';
import '../../../billing_manage/views/invoices_page.dart';
import '../../../inventory_manage/views/inventory_page.dart';

import '../../../settings_manage/views/settings_page.dart';
import '../../controllers/navigation_controller.dart';
import 'dart:io' show Platform;

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.put(NavigationController());
    /* to ``Ensure `` all screens will be rebuild every time  */

    return Scaffold(
      body: Column(
        children: [
          // Window controls bar (top)
          if (Platform.isWindows) CustomWindowBar(),
          // Main content
          Expanded(
            child: Row(
              children: [
                Obx(() {
                  final isOpen = nav.isHovered.value;

                  return MouseRegion(
                    onEnter: (_) => nav.isHovered(true),
                    onExit: (_) => nav.isHovered(false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isOpen ? 330.w : 100.w,
                      onEnd: () {
                        nav.finishHovereing.value = nav.isHovered.value;
                      },
                      curve: Curves.easeInOutCubic,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20.r),
                          bottomRight: Radius.circular(20.r),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20.r),
                          bottomRight: Radius.circular(20.r),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border(
                                right: BorderSide(
                                  color: Colors.white.withAlpha(50),
                                ),
                              ),
                            ),
                            child: NavigationRail(
                              backgroundColor: Colors.transparent,
                              selectedIndex: nav.selectedIndex.value,
                              onDestinationSelected: nav.select,
                              useIndicator: true,
                              indicatorColor: AppColors.mainColor.withOpacity(
                                0.15,
                              ),
                              groupAlignment: -0.50,
                              indicatorShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              leading: _railLeading(context, isOpen),
                              unselectedLabelTextStyle: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                              selectedLabelTextStyle: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                color: AppColors.mainColor,
                                fontWeight: FontWeight.w600,
                              ),
                              extended: nav.isHovered.value,
                              destinations: [
                                _railItem(
                                  context,
                                  Assets.of(context).icons.home_png,
                                  "Dashboard",
                                  isOpen,
                                  nav.finishHovereing.value,
                                ),
                                _railItem(
                                  context,
                                  Assets.of(context).icons.health_struct_png,
                                  "Patients",
                                  isOpen,
                                  nav.finishHovereing.value,
                                ),
                                _railItem(
                                  context,
                                  Assets.of(context).icons.calendar_png,
                                  "Appointments",
                                  isOpen,
                                  nav.finishHovereing.value,
                                ),
                                _railItem(
                                  context,
                                  Assets.of(context).icons.invoice_png,
                                  "Billing",
                                  isOpen,
                                  nav.finishHovereing.value,
                                ),
                                _railItem(
                                  context,
                                  Assets.of(context).icons.supply_png,
                                  "Inventory",
                                  isOpen,
                                  nav.finishHovereing.value,
                                ),

                                _railItem(
                                  context,
                                  Assets.of(context).icons.settings_png,
                                  "Settings",
                                  isOpen,
                                  nav.finishHovereing.value,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                // const VerticalDivider(width: 1),
                Expanded(
                  flex: 2,
                  child: Obx(() {
                    final index = nav.selectedIndex.value;
                    if (index == 0) {
                      return DashboardPage();
                    } else if (index == 1) {
                      return PatientsPage();
                    } else if (index == 2) {
                      return AppointmentsPage();
                    } else if (index == 3) {
                      return InvoicesPage();
                    } else if (index == 4) {
                      return InventoryPage();
                    } else if (index == 5) {
                      return SettingsPage();
                    } else {
                      return SizedBox();
                    }
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

  Padding _railLeading(BuildContext context, bool isOpen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Assets.of(context).logo_png,
            width: isOpen ? 170.w : 130.w,
          ),
          if (isOpen) ...[
            const SizedBox(height: 8),
            AutoSizeText(
              'Dental Flow',
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.mainColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  NavigationRailDestination _railItem(
    BuildContext context,
    String icon,
    String label,
    bool isOpen,
    bool finishHovereing,
  ) {
    final iconWidget = Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: Opacity(
        opacity: 0.5,
        child: Image.asset(
          icon,
          width: 34.w,
          // color: Colors.grey.withAlpha(100),
        ),
      ),
    );

    final selectedIconWidget = Padding(
      padding: EdgeInsets.only(bottom: 18.h),
      child: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: AppColors.mainColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Image.asset(icon, width: 40.w),
      ),
    );

    return NavigationRailDestination(
      icon: isOpen ? iconWidget : Tooltip(message: label, child: iconWidget),
      selectedIcon: selectedIconWidget,
      label: finishHovereing
          ? Padding(
              padding: EdgeInsets.only(left: 10.w),
              child: AutoSizeText(
                minFontSize: 6,
                label,
                maxFontSize: 15,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : SizedBox(),
    );
  }
}
