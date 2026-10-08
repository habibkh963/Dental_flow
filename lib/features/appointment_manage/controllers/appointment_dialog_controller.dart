import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/database_service.dart';
import '../../home/controllers/dash_board_controller.dart';
import '../models/appointment.dart';
import '../models/appointment_status.dart';
import '../utils/appointment_input.dart';
import '../utils/appointment_time.dart';
import 'appointments_controller.dart';

class AppointmentDialogController extends GetxController {
  static const dialogTag = 'appointment_dialog';

  AppointmentDialogController({
    required this.appointmentsController,
    this.existing,
  });

  final AppointmentsController appointmentsController;
  final Appointment? existing;

  late final TextEditingController notesController;
  late final TextEditingController customPresentationController;

  final selectedPatientId = ''.obs;
  final selectedDate = Rxn<DateTime>();
  final selectedTime = Rxn<TimeOfDay>();
  final selectedPresentations = <String>[].obs;
  final selectedMaterials = <Map<String, dynamic>>[].obs;
  final selectedMaterialId = RxnString();
  final selectedQuantity = 1.obs;
  final saving = false.obs;
  final formError = RxnString();

  bool get isEdit => existing != null;

  void clearFormError() => formError.value = null;

  void setFormError(String message) => formError.value = message;

  bool get showMaterials =>
      isEdit && existing!.status == AppointmentStatus.done;

  @override
  void onInit() {
    super.onInit();
    final appt = existing;
    notesController = TextEditingController(text: appt?.notes ?? '');
    customPresentationController = TextEditingController();

    if (appt != null) {
      selectedPatientId.value = appt.patientId;
      selectedDate.value = DateTime.tryParse(appt.date);
      selectedTime.value = parseTimeOfDay(appt.time);
      selectedPresentations.assignAll(_splitPresentation(appt.presentation));
      _loadExistingMaterials(appt.id);
    }

    if (appointmentsController.patients.isEmpty) {
      appointmentsController.fetchPatients();
    }
    if (appointmentsController.inventory.isEmpty) {
      appointmentsController.fetchInventory();
    }
  }

  @override
  void onClose() {
    notesController.dispose();
    customPresentationController.dispose();
    super.onClose();
  }

  List<String> _splitPresentation(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw.split(RegExp(r'[,،]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  String get presentationText {
    final list = List<String>.from(selectedPresentations);
    final custom = customPresentationController.text.trim();
    if (custom.isNotEmpty && !list.contains(custom)) {
      list.add(custom);
    }
    return list.join('، ');
  }

  String get uiStatusForSave =>
      isEdit ? statusUiValue(existing!.status) : 'scheduled';

  Future<void> _loadExistingMaterials(String appointmentId) async {
    final materials =
        await DatabaseService.instance.getAppointmentMaterials(appointmentId);
    selectedMaterials.assignAll(
      materials
          .map(
            (m) => {
              'material_id': m['material_id'],
              'quantity': m['quantity'],
            },
          )
          .toList(),
    );
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      selectedDate.value = picked;
      clearFormError();
    }
  }

  Future<void> pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime.value ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      selectedTime.value = picked;
      clearFormError();
    }
  }

  void addMaterial() {
    final materialId = selectedMaterialId.value;
    final qty = selectedQuantity.value;
    if (materialId == null || qty <= 0) return;

    final item = appointmentsController.inventory
        .firstWhereOrNull((i) => i['id'] == materialId);
    final available = item?['qty'] is int
        ? item!['qty'] as int
        : int.tryParse('${item?['qty']}') ?? 0;

    if (qty > available) {
      setFormError(
        'الكمية المطلوبة ($qty) أكبر من المخزون المتاح ($available)',
      );
      return;
    }

    clearFormError();

    selectedMaterials.add({'material_id': materialId, 'quantity': qty});
    selectedMaterialId.value = null;
    selectedQuantity.value = 1;
  }

  void removeMaterial(int index) {
    if (index < 0 || index >= selectedMaterials.length) return;
    selectedMaterials.removeAt(index);
  }

  Future<void> save(BuildContext context) async {
    final timeString = selectedTime.value == null
        ? null
        : formatTimeForStorage(selectedTime.value!);

    final parsed = tryParseAppointmentForm(
      patientId: selectedPatientId.value,
      date: selectedDate.value,
      time: timeString,
      uiStatus: uiStatusForSave,
      presentation: presentationText,
      notes: notesController.text,
      materials: selectedMaterials.toList(),
    );

    if (parsed.values == null) {
      setFormError(parsed.error ?? 'تحقق من الحقول');
      return;
    }

    await appointmentsController.reloadAppointmentsCache();

    final conflict = appointmentsController.validateTimeConflict(
      date: parsed.values!.date,
      time: parsed.values!.time,
      excludeId: existing?.id,
    );

    if (conflict != null) {
      setFormError('تعارض في الموعد: $conflict');
      return;
    }

    clearFormError();
    saving.value = true;
    try {
      if (isEdit) {
        await appointmentsController.updateAppointment(
          existing!.id,
          parsed.values!,
        );
      } else {
        await appointmentsController.createAppointment(parsed.values!);
      }

      if (Get.isRegistered<DashBoardController>()) {
        await Get.find<DashBoardController>().loadStats();
      }

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      saving.value = false;
    }
  }
}
