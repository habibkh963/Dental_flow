import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controllers/dash_board_controller.dart';
import '../../../patient_manage/controller/patients_controller.dart';
import '../../../patient_manage/views/widgets/patient_dialog.dart';
import 'quick_daily_entry_dialog.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'إجراءات سريعة',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(width: 12),
        _QuickActionPill(
          icon: Icons.person_add_alt_1_rounded,
          label: 'مريض',
          filled: false,
          onTap: () => _addPatient(context),
        ),
        const SizedBox(width: 8),
        _QuickActionPill(
          icon: Icons.add_card_rounded,
          label: 'إيراد / مصروف',
          filled: true,
          onTap: () => showQuickDailyEntryDialog(context),
        ),
      ],
    );
  }

  Future<void> _addPatient(BuildContext context) async {
    const tag = 'dashboard_patients_quick';
    final patients = Get.isRegistered<PatientsController>(tag: tag)
        ? Get.find<PatientsController>(tag: tag)
        : Get.put(PatientsController(), tag: tag, permanent: false);
    await openPatientDialog(context, patients);
    if (Get.isRegistered<DashBoardController>()) {
      await Get.find<DashBoardController>().refresh();
    }
  }
}

class _QuickActionPill extends StatelessWidget {
  const _QuickActionPill({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: filled
          ? AppColors.mainColor
          : AppColors.mainColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled ? Colors.white : AppColors.mainColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : AppColors.mainColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return child;
  }
}