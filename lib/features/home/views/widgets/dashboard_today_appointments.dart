import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controllers/dash_board_controller.dart';
import 'appointment_notification_card.dart';

class DashboardTodayAppointments extends GetView<DashBoardController> {
  const DashboardTodayAppointments({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final appointments = controller.todayAppointments;
      if (appointments.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(Icons.event_available, size: 36, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'لا توجد معاينات اليوم',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      final upcoming = appointments
          .where((apt) => _isUpcomingAppointment(apt['time'] as String?))
          .toList();
      final others = appointments
          .where((apt) => !upcoming.contains(apt))
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'معاينات اليوم',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${appointments.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcoming.isNotEmpty) ...[
            Text(
              'قادمة (خلال 30 دقيقة)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ...upcoming.map(
              (apt) => AppointmentNotificationCard(
                appointment: apt,
                isUpcoming: true,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (others.isNotEmpty) ...[
            if (upcoming.isNotEmpty)
              Text(
                'باقي المعاينات',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            if (upcoming.isNotEmpty) const SizedBox(height: 8),
            ...others.map(
              (apt) => AppointmentNotificationCard(
                appointment: apt,
                isUpcoming: false,
              ),
            ),
          ],
        ],
      );
    });
  }

  bool _isUpcomingAppointment(String? timeStr) {
    if (timeStr == null) return false;
    try {
      final now = DateTime.now();
      final timeOnly = DateTime.parse('2000-01-01 $timeStr');
      final in30Min = now.add(const Duration(minutes: 30));
      final aptToday = DateTime(
        now.year,
        now.month,
        now.day,
        timeOnly.hour,
        timeOnly.minute,
      );
      return aptToday.isBefore(in30Min) && aptToday.isAfter(now);
    } catch (_) {
      return false;
    }
  }
}
