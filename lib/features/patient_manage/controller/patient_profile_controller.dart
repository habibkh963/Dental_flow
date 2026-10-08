import 'package:get/get.dart';

import '../../../services/database_service.dart';
import '../models/cure_progress_entry.dart';
import '../models/patient_condition.dart';
import '../utils/patient_treatment_plan_utils.dart';

class PatientProfileController extends GetxController {
  PatientProfileController({required this.patient});

  final Map<String, dynamic> patient;
  final db = DatabaseService.instance;

  final isLoading = true.obs;
  final files = <Map<String, dynamic>>[].obs;
  final conditions = <PatientCondition>[].obs;
  final progressByCondition = <String, List<CureProgressEntry>>{}.obs;

  String get patientId => patient['id']?.toString() ?? '';

  /// حالات التمثيل/العلاج من ملف المريض (تقويم، فك سفلي، زراعة...).
  List<String> get plannedTreatments => parseTreatmentPlanItems(
        patient['treatment_plan']?.toString(),
        excludeLabels: parseMedicalConditions(patient['diseases']?.toString()),
      );

  List<String> get untrackedPlannedTreatments {
    final tracked =
        conditions.map((c) => c.conditionName.toLowerCase()).toSet();
    return plannedTreatments
        .where((name) => !tracked.contains(name.toLowerCase()))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      await refreshPatientFromDb();
      await Future.wait([loadFiles(), loadConditions()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPatientFromDb() async {
    final fresh = await db.getPatientById(patientId);
    if (fresh != null) {
      patient.addAll(fresh);
    }
  }

  Future<void> loadFiles() async {
    final loaded = await db.getPatientFiles(patientId);
    files.assignAll(loaded);
  }

  Future<void> loadConditions() async {
    await _syncConditionsFromTreatmentPlan();
    final rows = await db.getPatientConditions(patientId);
    conditions.assignAll(rows.map(PatientCondition.fromMap));

    final map = <String, List<CureProgressEntry>>{};
    for (final condition in conditions) {
      final progressRows = await db.getConditionProgress(condition.id);
      map[condition.id] =
          progressRows.map(CureProgressEntry.fromMap).toList();
    }
    progressByCondition.assignAll(map);
  }

  Future<void> _syncConditionsFromTreatmentPlan() async {
    final planned = plannedTreatments;
    if (planned.isEmpty) return;

    final existing = await db.getPatientConditions(patientId);
    final tracked = existing
        .map((c) => (c['condition_name']?.toString() ?? '').toLowerCase())
        .toSet();

    for (final name in planned) {
      if (tracked.contains(name.toLowerCase())) continue;
      await db.addPatientCondition({
        'patient_id': patientId,
        'condition_name': name,
      });
    }
  }

  Future<void> syncAllPlannedTreatments() async {
    await _syncConditionsFromTreatmentPlan();
    await loadConditions();
  }

  List<CureProgressEntry> progressFor(String conditionId) {
    return progressByCondition[conditionId] ?? const [];
  }

  int? latestCureLevel(String conditionId) {
    final list = progressFor(conditionId);
    if (list.isEmpty) return null;
    return list.first.cureLevel;
  }

  Future<void> addCondition(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (conditions.any(
      (c) => c.conditionName.toLowerCase() == trimmed.toLowerCase(),
    )) {
      return;
    }
    await db.addPatientCondition({
      'patient_id': patientId,
      'condition_name': trimmed,
    });
    await loadConditions();
  }

  Future<void> removeCondition(String conditionId) async {
    await db.deletePatientCondition(conditionId);
    await loadConditions();
  }

  Future<void> addProgressEntry({
    required String conditionId,
    required DateTime recordedAt,
    required int cureLevel,
    required String notes,
    String? audioTempPath,
  }) async {
    var audioPath = '';
    if (audioTempPath != null && audioTempPath.isNotEmpty) {
      audioPath = await db.saveCureProgressAudio(
        audioTempPath,
        patientId,
        conditionId,
      );
    }

    await db.addConditionProgress({
      'condition_id': conditionId,
      'recorded_at': recordedAt.toIso8601String(),
      'cure_level': cureLevel.clamp(0, 100),
      'notes': notes.trim(),
      'audio_path': audioPath,
    });
    await loadConditions();
  }

  Future<void> deleteProgressEntry(String entryId) async {
    await db.deleteConditionProgress(entryId);
    await loadConditions();
  }

  Future<void> uploadFile(String fileName, String filePath) async {
    await db.addPatientFile({
      'patient_id': patientId,
      'file_name': fileName,
      'file_path': filePath,
    });
    await loadFiles();
  }

  Future<void> deleteFile(String fileId) async {
    await db.deletePatientFile(fileId);
    await loadFiles();
  }
}
