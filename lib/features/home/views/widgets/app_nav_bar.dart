import 'package:dental_managment_system/assets/assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controllers/dash_board_controller.dart';
import '../../controllers/navigation_controller.dart';
import 'app_nav_item.dart';

class _NavEntry {
  const _NavEntry({
    required this.index,
    required this.label,
    required this.icon,
  });

  final int index;
  final String label;
  final String icon;
}

class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavigationController>();
    final assets = Assets.of(context).icons;
    final entries = [
      _NavEntry(index: 0, label: 'الرئيسية', icon: assets.home_png),
      _NavEntry(index: 1, label: 'المرضى', icon: assets.health_struct_png),
      _NavEntry(index: 2, label: 'المعاينات', icon: assets.calendar_png),
      _NavEntry(index: 3, label: 'الفواتير', icon: assets.invoice_png),
      _NavEntry(index: 4, label: 'المخزن', icon: assets.supply_png),
      _NavEntry(index: 5, label: 'الجرد', icon: assets.supply_png),
      _NavEntry(index: 6, label: 'الإعدادات', icon: assets.settings_png),
    ];

    return Obx(() {
      final selected = nav.selectedIndex.value;
      final panelOpen = nav.showNotificationsPanel.value;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Image.asset(Assets.of(context).logo_png, height: 60),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final entry in entries) ...[
                      AppNavItem(
                        label: entry.label,
                        iconAsset: entry.icon,
                        isSelected: selected == entry.index,
                        onTap: () => nav.select(entry.index),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
            ),
            _NotificationsButton(
              panelOpen: panelOpen,
              onPressed: nav.toggleNotificationsPanel,
            ),
          ],
        ),
      );
    });
  }
}

class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton({
    required this.panelOpen,
    required this.onPressed,
  });

  final bool panelOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashBoardController>();

    return Obx(() {
      final count = dash.todayAppointments.length + dash.lowStockItems.length;

      return Tooltip(
        message: panelOpen ? 'إخفاء الإشعارات' : 'عرض الإشعارات',
        child: Material(
          color: panelOpen
              ? AppColors.mainColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Badge(
                    isLabelVisible: count > 0,
                    label: Text(
                      count > 9 ? '9+' : '$count',
                      style: GoogleFonts.poppins(fontSize: 9),
                    ),
                    child: Icon(
                      panelOpen
                          ? Icons.notifications
                          : Icons.notifications_outlined,
                      size: 20,
                      color: AppColors.mainColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'إشعارات',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
