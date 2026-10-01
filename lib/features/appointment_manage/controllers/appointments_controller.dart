import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../../../services/database_service.dart';
import '../models/appointment.dart';
import '../utils/appointment_input.dart';
import '../views/widgets/appointment_dialog.dart';
import 'appointment_dialog_controller.dart';

class AppointmentsController extends GetxController {
  final db = DatabaseService.instance;

  final appointments = <Appointment>[].obs;
  final patients = <Map<String, dynamic>>[].obs;
  final inventory = <Map<String, dynamic>>[].obs;
  final loading = false.obs;

  final _appointments = <Appointment>[];

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    loading.value = true;
    try {
      await Future.wait([fetchPatients(), fetchInventory()]);
      final raw = await db.getAppointments();
      final patientMap = {
        for (final p in patients)
          p['id']?.toString() ?? '': _patientName(p),
      };

      _appointments
        ..clear()
        ..addAll(
          raw.map(
            (row) => Appointment.fromMap(
              row,
              patientName: patientMap[row['patient_id']?.toString()] ?? '-',
            ),
          ),
        );
      appointments.assignAll(_appointments);
    } finally {
      loading.value = false;
    }
  }

  Future<void> reloadAppointmentsCache() async {
    if (patients.isEmpty) {
      await fetchPatients();
    }

    final raw = await db.getAppointments();
    final patientMap = {
      for (final p in patients) p['id']?.toString() ?? '': _patientName(p),
    };

    _appointments
      ..clear()
      ..addAll(
        raw.map(
          (row) => Appointment.fromMap(
            row,
            patientName: patientMap[row['patient_id']?.toString()] ?? '-',
          ),
        ),
      );
  }

  Future<void> fetchPatients() async {
    patients.assignAll(await db.getPatients());
  }

  Future<void> fetchInventory() async {
    inventory.assignAll(await db.getInventory());
  }

  String _patientName(Map<String, dynamic> patient) {
    return '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'
        .trim();
  }

  Future<void> createAppointment(AppointmentFormValues values) async {
    await _saveAppointment(values: values);
    await loadAll();
  }

  Future<void> updateAppointment(
    String id,
    AppointmentFormValues values,
  ) async {
    await _saveAppointment(id: id, values: values, isUpdate: true);
    await loadAll();
  }

  Future<void> remove(String id) async {
    final oldMaterials = await db.getAppointmentMaterials(id);
    if (oldMaterials.isNotEmpty) {
      await _restoreMaterials(oldMaterials);
      await db.deleteAppointmentMaterials(id);
    }
    await db.deleteAppointment(id);
    await loadAll();
  }

  void openAddDialog() => _openDialog();

  void openEditDialog(Appointment appointment) =>
      _openDialog(existing: appointment);

  Future<void> confirmDelete(Appointment appointment) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('حذف الموعد؟', style: GoogleFonts.poppins()),
        content: Text(
          'هل أنت متأكد من حذف موعد ${appointment.patientName}؟',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('إلغاء', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'حذف',
              style: GoogleFonts.poppins(color: AppColors.cancelledColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await remove(appointment.id);
    }
  }

  String? validateTimeConflict({
    required String date,
    required String time,
    String? excludeId,
  }) {
    return findTimeConflict(
      date: date,
      time: time,
      appointments: _appointments,
      excludeId: excludeId,
    );
  }

  void _openDialog({Appointment? existing}) {
    final tag = AppointmentDialogController.dialogTag;
    if (Get.isRegistered<AppointmentDialogController>(tag: tag)) {
      Get.delete<AppointmentDialogController>(tag: tag);
    }

    final dialogController = Get.put(
      AppointmentDialogController(
        appointmentsController: this,
        existing: existing,
      ),
      tag: tag,
    );

    final context = Get.context;
    if (context == null) {
      Get.delete<AppointmentDialogController>(tag: tag);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppointmentDialogWidget(
        dialogController: dialogController,
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<AppointmentDialogController>(tag: tag)) {
          Get.delete<AppointmentDialogController>(tag: tag);
        }
      });
    });
  }

  Future<void> _saveAppointment({
    String? id,
    required AppointmentFormValues values,
    bool isUpdate = false,
  }) async {
    final payload = {
      'patient_id': values.patientId,
      'date': values.date,
      'time': values.time,
      'status': values.status,
      'notes': values.notes,
    };

    if (isUpdate && id != null) {
      await _restoreAndClearMaterials(id);
      await db.updateAppointment(id, payload);
      await _applyMaterials(id, values.materials);
      return;
    }

    final appointmentId = await db.addAppointment(payload);
    await _applyMaterials(appointmentId, values.materials);
  }

  Future<void> _restoreAndClearMaterials(String appointmentId) async {
    final oldMaterials = await db.getAppointmentMaterials(appointmentId);
    if (oldMaterials.isEmpty) return;
    await _restoreMaterials(oldMaterials);
    await db.deleteAppointmentMaterials(appointmentId);
    await fetchInventory();
  }

  Future<void> _applyMaterials(
    String appointmentId,
    List<Map<String, dynamic>> materials,
  ) async {
    if (materials.isEmpty) return;

    for (final material in materials) {
      final materialId = material['material_id']?.toString() ?? '';
      final usedQty = material['quantity'] is int
          ? material['quantity'] as int
          : int.tryParse('${material['quantity']}') ?? 0;
      if (materialId.isEmpty || usedQty <= 0) continue;

      await db.addAppointmentMaterial(appointmentId, materialId, usedQty);
      await _adjustInventoryStock(materialId, -usedQty);
    }

    await fetchInventory();
  }

  Future<void> _restoreMaterials(List<Map<String, dynamic>> materials) async {
    for (final material in materials) {
      final materialId = material['material_id']?.toString() ?? '';
      final qty = material['quantity'] is int
          ? material['quantity'] as int
          : int.tryParse('${material['quantity']}') ?? 0;
      if (materialId.isEmpty || qty <= 0) continue;
      await _adjustInventoryStock(materialId, qty);
    }
  }

  Future<void> _adjustInventoryStock(String materialId, int delta) async {
    final item = inventory.firstWhereOrNull((i) => i['id'] == materialId) ??
        (await db.getInventory())
            .firstWhereOrNull((i) => i['id'] == materialId);

    if (item == null) return;

    final currentQty = item['qty'] is int
        ? item['qty'] as int
        : int.tryParse('${item['qty']}') ?? 0;
    final newQty = (currentQty + delta).clamp(0, 999999);
    await db.updateInventoryItem(materialId, {'qty': newQty});
  }
}
