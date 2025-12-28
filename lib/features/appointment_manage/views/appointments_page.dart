import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/appointments_controller.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/appointments_controller.dart';
import 'widgets/appointment_dialog.dart';

class AppointmentsPage extends StatelessWidget {
  final c = Get.put(
    AppointmentsController(),
    permanent: false,
    tag: UniqueKey().toString(),
  );

  AppointmentsPage({super.key});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed':
        return const Color(0xFF264653);
      case 'cancelled':
        return const Color(0xFFE76F51);
      case 'scheduled':
        return const Color(0xFF2A9D8F);
      default:
        return const Color(0xFFE9C46A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔹 Header
          Row(
            children: [
              Text(
                "Appointments",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openAppointmentDialog(context, c),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(),
                  backgroundColor: const Color(0xFF2A9D8F),
                ),
                icon: const Icon(Icons.add),
                label: const Text('New Appointment'),
              ),
            ],
          ),

          const SizedBox(height: 26),

          /// 🔹 Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A9D8F).withOpacity(0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text("Patient")),
                Expanded(child: Text("Date")),
                Expanded(child: Text("Time")),
                Expanded(child: Text("Status")),
                Expanded(child: Text("Actions")),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// 🔹 Appointments
          Expanded(
            child: Obx(() {
              if (c.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (c.appts.isEmpty) {
                return const Center(child: Text("No appointments yet"));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: c.appts.length,
                itemBuilder: (_, i) {
                  final a = c.appts[i];

                  final pid = a['patient_id'];
                  final patientName = (() {
                    for (final x in c.patients) {
                      if (x['id'] == pid)
                        return ('${x['first_name'] ?? ''}  ${x['last_name'] ?? ''}') ??
                            '';
                    }
                    return '-';
                  })();

                  final status = a['status'] ?? '';
                  final color = _statusColor(status);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      border: Border.all(color: color.withOpacity(.4)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        /// Patient
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: color,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                patientName,
                                style: GoogleFonts.poppins(color: color),
                              ),
                            ],
                          ),
                        ),

                        /// Date
                        Expanded(child: Text(a['date'] ?? '-')),

                        /// Time
                        Expanded(child: Text(a['time'] ?? '-')),

                        /// Status
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        /// Actions
                        Expanded(
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: color),
                                onPressed: () => _openAppointmentDialog(
                                  context,
                                  c,
                                  existing: a,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => c.remove(a['id']),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

Future<void> _openAppointmentDialog(
  BuildContext context,
  AppointmentsController controller, {
  Map<String, dynamic>? existing,
}) async {
  await AppointmentDialog.show(
    context: context,
    controller: controller,
    existing: existing,
  );
}
