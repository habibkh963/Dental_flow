import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/appointments_controller.dart';
import '../models/appointment.dart';
import 'widgets/appointment_tile.dart';

class AppointmentsPage extends GetView<AppointmentsController> {
  AppointmentsPage({super.key}) : _tag = UniqueKey().toString() {
    Get.put(AppointmentsController(), permanent: false, tag: _tag);
  }

  final String _tag;

  @override
  String? get tag => _tag;

  Map<String, List<Appointment>> _groupByDate(List<Appointment> list) {
    final grouped = <String, List<Appointment>>{};
    for (final item in list) {
      final date = item.date.isEmpty ? 'غير محدد' : item.date;
      grouped.putIfAbsent(date, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'المواعيد',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: controller.openAddDialog,
                icon: const Icon(Icons.add),
                label: const Text('موعد جديد'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.appointments.isEmpty) {
        return Center(
          child: Text(
            'لا يوجد مواعيد بعد',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
        );
      }

      final grouped = _groupByDate(controller.appointments);

      return ListView(
        children: grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '📅 ${entry.key}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF264653),
                  ),
                ),
              ),
              ...entry.value.map(
                (appointment) => AppointmentTile(
                  appointment: appointment,
                  onEdit: () => controller.openEditDialog(appointment),
                  onDelete: () => controller.confirmDelete(appointment),
                ),
              ),
            ],
          );
        }).toList(),
      );
    });
  }
}
