import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../appointment_manage/views/appointments_page.dart';
import '../../../billing_manage/views/invoices_page.dart';
import '../../../inventory_manage/views/daily_inventory_page.dart';
import '../../../inventory_manage/views/inventory_page.dart';
import '../../../patient_manage/views/patients_page.dart';
import '../../../settings_manage/views/settings_page.dart';
import '../../controllers/dash_board_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../dashboard_page.dart';
import 'app_nav_bar.dart';
import 'custome_window_bar.dart';
import 'daily_notifications_drawer.dart';

class AppShell extends StatelessWidget {
  AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DashBoardController>()) {
      Get.put(DashBoardController(), permanent: true);
    }
    if (!Get.isRegistered<NavigationController>()) {
      Get.put(NavigationController(), permanent: true);
    }

    final nav = Get.find<NavigationController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          if (Platform.isWindows) const CustomWindowBar(),
          const AppNavBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Obx(() => _buildPage(nav.selectedIndex.value)),
                ),
                Obx(
                  () => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: nav.showNotificationsPanel.value ? 320 : 0,
                    child: nav.showNotificationsPanel.value
                        ? const DailyNotificationsDrawer()
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage();
      case 1:
        return PatientsPage();
      case 2:
        return AppointmentsPage();
      case 3:
        return InvoicesPage();
      case 4:
        return InventoryPage();
      case 5:
        return DailyInventoryPage();
      case 6:
        return SettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }

  NavigationController get nav => Get.find<NavigationController>();
}
