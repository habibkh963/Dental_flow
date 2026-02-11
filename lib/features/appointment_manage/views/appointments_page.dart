import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/appointments_controller.dart';
import 'widgets/appointment_dialog.dart';

class AppointmentsPage extends StatelessWidget {
  AppointmentsPage({super.key});

  final c = Get.put(
    AppointmentsController(),
    permanent: false,
    tag: UniqueKey().toString(),
  );

  // 🎨 لون الحالة
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

  // 🌍 ترجمة الحالة
  String translateStatus(String s) {
    switch (s.toLowerCase()) {
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغي';
      case 'scheduled':
        return 'مجدول';
      default:
        return s;
    }
  }

  // 📅 تقسيم حسب التاريخ
  Map<String, List<Map<String, dynamic>>> groupByDate(
    List<Map<String, dynamic>> list,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final item in list) {
      final date = item['date'] ?? 'غير محدد';

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(item);
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
          /// 🔹 العنوان
          Row(
            children: [
              Text(
                "المواعيد",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openAppointmentDialog(context, c),
                icon: const Icon(Icons.add),
                label: const Text("موعد جديد"),
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

          /// 🔹 القائمة
          Expanded(
            child: Obx(() {
              if (c.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (c.appts.isEmpty) {
                return const Center(child: Text("لا يوجد مواعيد بعد"));
              }

              final grouped = groupByDate(c.appts);

              return ListView(
                children: grouped.entries.map((entry) {
                  final date = entry.key;
                  final list = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🗓️ التاريخ
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "📅 $date",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF264653),
                          ),
                        ),
                      ),

                      ...list.map((a) {
                        final status = translateStatus(a['status'] ?? '');
                        final color = _statusColor(a['status'] ?? '');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            border: Border.all(color: color.withOpacity(.4)),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              /// 👤 المريض
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
                                      a['patient_name'] ?? 'غير معروف',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// ⏰ الوقت
                              Expanded(
                                child: Text(
                                  a['time'] ?? '-',
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              /// 📌 الحالة
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
                                    status,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              /// ⚙️ أكشن
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
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => c.remove(a['id']),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
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
