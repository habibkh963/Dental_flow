import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controller/patient_profile_controller.dart';
import '../../models/patient_condition.dart';
import '../../utils/cure_audio_recorder.dart';
import '../../utils/cure_level_utils.dart';

Future<bool?> openCureProgressDialog(
  BuildContext context,
  PatientProfileController controller,
  PatientCondition condition,
) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _CureProgressDialog(
      controller: controller,
      condition: condition,
    ),
  );
}

class _CureProgressDialog extends StatefulWidget {
  const _CureProgressDialog({
    required this.controller,
    required this.condition,
  });

  final PatientProfileController controller;
  final PatientCondition condition;

  @override
  State<_CureProgressDialog> createState() => _CureProgressDialogState();
}

class _CureProgressDialogState extends State<_CureProgressDialog> {
  final notesController = TextEditingController();
  final recorder = CureAudioRecorder.instance;

  DateTime recordedAt = DateTime.now();
  int cureLevel = 50;
  String? formError;
  String? audioPath;
  bool isRecording = false;
  bool isSaving = false;
  bool canRecord = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final allowed = await recorder.canRecord;
    if (mounted) {
      setState(() => canRecord = allowed);
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    if (isRecording) {
      recorder.stop();
    }
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(recordedAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _toggleRecording() async {
    setState(() => formError = null);
    try {
      if (isRecording) {
        final path = await recorder.stop();
        setState(() {
          isRecording = false;
          audioPath = path;
        });
      } else {
        await recorder.start();
        setState(() {
          isRecording = true;
          audioPath = null;
        });
      }
    } catch (e) {
      setState(() => formError = e.toString());
    }
  }

  Future<void> _clearAudio() async {
    await recorder.cancel();
    setState(() {
      audioPath = null;
      isRecording = false;
    });
  }

  Future<void> _save() async {
    setState(() {
      formError = null;
      isSaving = true;
    });

    try {
      if (isRecording) {
        final path = await recorder.stop();
        audioPath = path;
        isRecording = false;
      }

      await widget.controller.addProgressEntry(
        conditionId: widget.condition.id,
        recordedAt: recordedAt,
        cureLevel: cureLevel,
        notes: notesController.text,
        audioTempPath: audioPath,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => formError = 'تعذر الحفظ: $e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'إضافة متابعة — ${widget.condition.conditionName}',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (formError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formError!,
                    style: GoogleFonts.poppins(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('التاريخ والوقت', style: GoogleFonts.poppins()),
                subtitle: Text(
                  formatProgressDateTime(recordedAt),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDateTime,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'مستوى الشفاء: $cureLevel% — ${cureLevelLabel(cureLevel)}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              Slider(
                value: cureLevel.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: AppColors.mainColor,
                label: '$cureLevel%',
                onChanged: (v) => setState(() => cureLevel = v.round()),
              ),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'ملاحظات',
                  labelStyle: GoogleFonts.poppins(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (canRecord) ...[
                Text('تسجيل صوتي', style: GoogleFonts.poppins(fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: isSaving ? null : _toggleRecording,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            isRecording ? Colors.red : AppColors.mainColor,
                      ),
                      icon: Icon(isRecording ? Icons.stop : Icons.mic),
                      label: Text(
                        isRecording ? 'إيقاف' : 'تسجيل',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    if (audioPath != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: isSaving ? null : _clearAudio,
                        child: Text('حذف التسجيل', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ],
                ),
                if (audioPath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'تم حفظ التسجيل مؤقتاً',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ] else
                Text(
                  'التسجيل الصوتي غير متاح على هذا الجهاز',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.poppins()),
        ),
        FilledButton(
          onPressed: isSaving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppColors.mainColor),
          child: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('حفظ', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }
}
