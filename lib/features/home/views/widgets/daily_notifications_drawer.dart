import 'package:dental_managment_system/features/home/controllers/dash_board_controller.dart';
import 'package:dental_managment_system/features/home/views/widgets/notification_tile.dart';
import '../../../../core/colors.dart';
import '../../controllers/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyNotificationsDrawer extends StatelessWidget {
  const DailyNotificationsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final DashBoardController ctrl = Get.isRegistered<DashBoardController>()
        ? Get.find<DashBoardController>()
        : Get.put(DashBoardController(), permanent: true);

    final nav = Get.find<NavigationController>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الإشعارات',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Obx(
                        () => Text(
                          '${ctrl.todayAppointments.length} معاينة · ${ctrl.lowStockItems.length} مخزون',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'إغلاق',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: nav.closeNotificationsPanel,
                ),
              ],
            ),
          ),

          Expanded(
            child: Obx(() {
                    final appts = ctrl.todayAppointments;
                    final low = ctrl.lowStockItems;

                    if (appts.isEmpty && low.isEmpty) {
                      return Center(
                        child: Text(
                          'لا اشعاراتا اليوم',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: [
                        // Upcoming appointments (next 30 min)
                        if (appts.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Text(
                              'المعاينات',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ...appts.map((apt) {
                            final status =
                                (apt['status'] as String?) ?? 'pending';
                            final id = (apt['id'] ?? '').toString();
                            return NotificationTile(
                              name:
                                  '${apt['first_name'] ?? ''} ${apt['last_name'] ?? ''}',
                              time: _formatTime(apt['time']),
                              type: _mapStatus(status),
                              key: ValueKey(apt['id']),
                              onTap: () {
                                final nav =
                                    Get.isRegistered<NavigationController>()
                                    ? Get.find<NavigationController>()
                                    : null;
                                if (nav != null)
                                  nav.select(2); // go to Appointments
                              },
                              onApprove: id.isEmpty
                                  ? null
                                  : () {
                                      ctrl.db
                                          .updateAppointment(id, {
                                            'status': 'done',
                                          })
                                          .then((_) => ctrl.loadStats());
                                      Get.snackbar(
                                        'المعاينة',
                                        'مكتملة',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    },
                              onCancel: id.isEmpty
                                  ? null
                                  : () {
                                      ctrl.db
                                          .updateAppointment(id, {
                                            'status': 'cancelled',
                                          })
                                          .then((_) => ctrl.loadStats());
                                      Get.snackbar(
                                        'المعاينة',
                                        'ملغية',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    },
                              onStatusChanged: id.isEmpty
                                  ? null
                                  : (newStatus) {
                                      final s = _statusToString(newStatus);
                                      ctrl.db
                                          .updateAppointment(id, {'status': s})
                                          .then((_) => ctrl.loadStats());
                                      Get.snackbar(
                                        'المعاينة',
                                        'تم التحديث',
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    },
                            );
                          }),
                        ],

                        // Inventory alerts
                        if (low.isNotEmpty) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Text(
                              'تنبيه المخزون',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ...low.map((item) {
                            final qty = item['qty'] ?? 0;
                            return GestureDetector(
                              onTap: () {
                                // navigate to appointments page when clicking inventory alert
                                final nav =
                                    Get.isRegistered<NavigationController>()
                                    ? Get.find<NavigationController>()
                                    : null;
                                if (nav != null) nav.select(4);
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 8.h),
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.14),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(10.w),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.14),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2,
                                        color: Colors.orange,
                                        size: 20.sp,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'] ?? 'Unknown',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            'مخزون منخفض: $qty',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12.sp,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14.sp,
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    );
            }),
          ),
        ],
      ),
    );
  }

  // helper functions below

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '--:--';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(0, 0, 0, hour, minute);
      return TimeOfDay.fromDateTime(dt).format(Get.context!);
    } catch (_) {
      return timeStr;
    }
  }

  AppointmentStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'approved':
        return AppointmentStatus.approved;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'done':
        return AppointmentStatus.done;
      default:
        return AppointmentStatus.pending;
    }
  }

  String _statusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.approved:
        return 'approved';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.done:
        return 'done';
    }
  }
}
