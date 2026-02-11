import 'package:dental_managment_system/core/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/dash_board_controller.dart';
import 'widgets/appointment_notification_card.dart';
import 'widgets/urgent_appointment_alert.dart';
import '../../inventory_manage/views/widgets/daily_payment_summary_widget.dart';

String? tag = UniqueKey().toString();

class DashboardPage extends StatelessWidget {
  DashboardPage({super.key});
  final dashBoardController = Get.find<DashBoardController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Urgent Appointment Alert (if any)
            // Obx(() {
            //   final urgent = dashBoardController.todayAppointments
            //       .where((apt) => _isUpcomingAppointment(apt['time']))
            //       .toList();

            //   return UrgentAppointmentAlert(
            //     urgentAppointments: dashBoardController.todayAppointments.value,
            //   );
            // }),
            // const SizedBox(height: 32),
            // Daily Payment Summary Widget
            DailyPaymentSummaryWidget(),
            const SizedBox(height: 32),
            // Stat Cards

            // Today's Appointments Section
            Obx(() {
              if (dashBoardController.todayAppointments.isEmpty) {
                return const SizedBox.shrink();
              }

              // Separate upcoming and other appointments
              final appointments = dashBoardController.todayAppointments;
              final upcomingAppointments = appointments.where((apt) {
                return _isUpcomingAppointment(apt['time']);
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with count
                  Row(
                    children: [
                      Text(
                        "معاينات اليوم",
                        style: GoogleFonts.poppins(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${appointments.length} معاينة',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Urgent/Upcoming appointments first
                  if (upcomingAppointments.isNotEmpty) ...[
                    Text(
                      '🔔 قادمة (خلال 30 دقيقة)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...upcomingAppointments.map(
                      (apt) => AppointmentNotificationCard(
                        appointment: apt,
                        isUpcoming: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Other appointments
                  if (appointments.length > upcomingAppointments.length) ...[
                    Text(
                      'معاينات اخرى اليوم',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...appointments
                        .where((apt) => !upcomingAppointments.contains(apt))
                        .map(
                          (apt) => AppointmentNotificationCard(
                            appointment: apt,
                            isUpcoming: false,
                          ),
                        ),
                    const SizedBox(height: 32),
                  ] else ...[
                    const SizedBox(height: 32),
                  ],
                ],
              );
            }),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3 / 3.5,
              children: [
                Obx(() {
                  return _StatCard(
                    title: 'المرضى',
                    icon: Icons.people,
                    value: dashBoardController.numberOfPatients.value
                        .toString(),
                  );
                }),
                Obx(() {
                  return _StatCard(
                    title: 'معاينات اليوم',
                    icon: Icons.event,
                    value: dashBoardController.appointmentsToday.value
                        .toString(),
                    hasNotification:
                        dashBoardController.hasUrgentAppointments.value,
                  );
                }),
                Obx(() {
                  return _StatCard(
                    title: 'مواد على وشك النفاذ',
                    icon: Icons.inventory_2,
                    value: dashBoardController.lowStockCount.value.toString(),
                    hasNotification: dashBoardController.hasLowStock.value,
                  );
                }),
              ],
            ),

            // // Low Stock Items Section
            // Obx(() {
            //   if (dashBoardController.lowStockItems.isEmpty) {
            //     return const SizedBox.shrink();
            //   }
            //   return Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text(
            //         'Low Stock Items (< 3)',
            //         style: GoogleFonts.poppins(
            //           fontSize: 22.sp,
            //           fontWeight: FontWeight.w700,
            //         ),
            //       ),
            //       const SizedBox(height: 16),
            //       Card(
            //         child: ListView.separated(
            //           shrinkWrap: true,
            //           physics: const NeverScrollableScrollPhysics(),
            //           itemCount: dashBoardController.lowStockItems.length,
            //           separatorBuilder: (_, __) => const Divider(),
            //           itemBuilder: (context, index) {
            //             final item = dashBoardController.lowStockItems[index];
            //             final qty = item['qty'] ?? 0;
            //             return Padding(
            //               padding: const EdgeInsets.all(12),
            //               child: Row(
            //                 children: [
            //                   Container(
            //                     padding: const EdgeInsets.symmetric(
            //                       horizontal: 12,
            //                       vertical: 8,
            //                     ),
            //                     decoration: BoxDecoration(
            //                       color: qty == 0
            //                           ? Colors.red
            //                           : (qty <= 1
            //                                 ? Colors.orange[300]
            //                                 : Colors.yellow[300]),
            //                       borderRadius: BorderRadius.circular(4),
            //                     ),
            //                     child: Text(
            //                       qty.toString(),
            //                       style: const TextStyle(
            //                         fontWeight: FontWeight.bold,
            //                         fontSize: 16,
            //                       ),
            //                     ),
            //                   ),
            //                   const SizedBox(width: 16),
            //                   Expanded(
            //                     child: Column(
            //                       crossAxisAlignment: CrossAxisAlignment.start,
            //                       children: [
            //                         Text(
            //                           item['name'] ?? 'Unknown',
            //                           style: const TextStyle(
            //                             fontWeight: FontWeight.w600,
            //                           ),
            //                         ),
            //                         const SizedBox(height: 4),
            //                         if (qty == 0)
            //                           const Text(
            //                             'OUT OF STOCK',
            //                             style: TextStyle(
            //                               color: Colors.red,
            //                               fontWeight: FontWeight.bold,
            //                               fontSize: 11,
            //                             ),
            //                           ),
            //                       ],
            //                     ),
            //                   ),
            //                   if (qty == 0)
            //                     Container(
            //                       padding: const EdgeInsets.symmetric(
            //                         horizontal: 8,
            //                         vertical: 4,
            //                       ),
            //                       decoration: BoxDecoration(
            //                         color: Colors.red,
            //                         borderRadius: BorderRadius.circular(4),
            //                       ),
            //                       child: const Text(
            //                         'URGENT',
            //                         style: TextStyle(
            //                           color: Colors.white,
            //                           fontSize: 10,
            //                           fontWeight: FontWeight.bold,
            //                         ),
            //                       ),
            //                     )
            //                   else
            //                     Icon(
            //                       Icons.warning,
            //                       color: qty <= 1
            //                           ? Colors.orange
            //                           : Colors.yellow[700],
            //                     ),
            //                 ],
            //               ),
            //             );
            //           },
            //         ),
            //       ),
            //       const SizedBox(height: 32),
            //     ],
            //   );
            // }),
            // const DashboardCharts(),
          ],
        ),
      ),
    );
  }

  bool _isUpcomingAppointment(String? timeStr) {
    if (timeStr == null) return false;
    try {
      final now = DateTime.now();
      final timeOnly = DateTime.parse('2000-01-01 $timeStr');
      final in30Min = now.add(const Duration(minutes: 30));
      return timeOnly.isBefore(in30Min) && timeOnly.isAfter(now);
    } catch (_) {
      return false;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool hasNotification;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Card(
          elevation: 0,

          color: AppColors.approvedColor.withAlpha(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 300.w),
                Icon(icon, color: cs.primary),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasNotification)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
