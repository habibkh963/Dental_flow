import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controller/patient_profile_controller.dart';
import '../../models/cure_progress_entry.dart';
import '../../models/patient_condition.dart';
import '../../utils/cure_level_utils.dart';
import 'cure_progress_dialog.dart';

class ConditionCureTable extends StatelessWidget {
  const ConditionCureTable({
    super.key,
    required this.controller,
    required this.condition,
    required this.entries,
  });

  final PatientProfileController controller;
  final PatientCondition condition;
  final List<CureProgressEntry> entries;

  @override
  Widget build(BuildContext context) {
    final latest = entries.isNotEmpty ? entries.first.cureLevel : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mainColor.withOpacity(0.15)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  condition.conditionName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (latest != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$latest%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainColor,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            '${entries.length} متابعة',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
          ),
          trailing: IconButton(
            tooltip: 'إضافة متابعة',
            icon: Icon(Icons.add_circle, color: AppColors.mainColor),
            onPressed: () async {
              final saved = await openCureProgressDialog(
                context,
                controller,
                condition,
              );
              if (saved == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تمت إضافة المتابعة',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                );
              }
            },
          ),
          children: [
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'لا توجد متابعات بعد — اضغط + لإضافة صف',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 72,
                  columnSpacing: 16,
                  headingTextStyle: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainColor,
                  ),
                  columns: const [
                    DataColumn(label: Text('التاريخ')),
                    DataColumn(label: Text('الوقت')),
                    DataColumn(label: Text('مستوى الشفاء')),
                    DataColumn(label: Text('ملاحظات')),
                    DataColumn(label: Text('صوت')),
                    DataColumn(label: Text('')),
                  ],
                  rows: entries
                      .map((entry) => _buildRow(context, entry))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, CureProgressEntry entry) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            formatProgressDate(entry.recordedAt),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        DataCell(
          Text(
            formatProgressTime(entry.recordedAt),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${entry.cureLevel}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                cureLevelLabel(entry.cureLevel),
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        DataCell(
          SizedBox(
            width: 140,
            child: Text(
              entry.notes.isEmpty ? '—' : entry.notes,
              style: GoogleFonts.poppins(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          entry.hasAudio
              ? IconButton(
                  icon: Icon(Icons.play_circle, color: AppColors.mainColor),
                  onPressed: () => _playAudio(context, entry.audioPath),
                )
              : Text('—', style: GoogleFonts.poppins(fontSize: 14)),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => _confirmDelete(context, entry),
          ),
        ),
      ],
    );
  }

  void _playAudio(BuildContext context, String path) {
    if (path.isEmpty || !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الملف الصوتي غير موجود', style: GoogleFonts.poppins()),
        ),
      );
      return;
    }
    try {
      Process.run('cmd', ['/c', 'start', '', path], runInShell: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تشغيل الملف: $e', style: GoogleFonts.poppins()),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CureProgressEntry entry,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف المتابعة؟', style: GoogleFonts.poppins()),
        content: Text('هل تريد حذف هذا السجل؟', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await controller.deleteProgressEntry(entry.id);
    }
  }
}
