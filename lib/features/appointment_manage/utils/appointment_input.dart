import '../models/appointment.dart';
import '../models/appointment_status.dart';
import 'appointment_time.dart';

class AppointmentFormValues {
  final String patientId;
  final String date;
  final String time;
  final String status;
  final String notes;
  final List<Map<String, dynamic>> materials;

  const AppointmentFormValues({
    required this.patientId,
    required this.date,
    required this.time,
    required this.status,
    required this.notes,
    required this.materials,
  });
}

({AppointmentFormValues? values, String? error}) tryParseAppointmentForm({
  required String? patientId,
  required DateTime? date,
  required String? time,
  required String uiStatus,
  required String notes,
  required List<Map<String, dynamic>> materials,
}) {
  if (patientId == null || patientId.trim().isEmpty) {
    return (values: null, error: 'يجب اختيار المريض');
  }

  if (date == null) {
    return (values: null, error: 'يجب اختيار التاريخ');
  }

  if (time == null || time.trim().isEmpty) {
    return (values: null, error: 'يجب اختيار الوقت');
  }

  if (timeToMinutes(time) == null) {
    return (values: null, error: 'صيغة الوقت غير صالحة');
  }

  final storageStatus = switch (uiStatus) {
    'completed' => 'done',
    'cancelled' => 'cancelled',
    _ => 'scheduled',
  };

  if (storageStatus == 'done') {
    for (final material in materials) {
      final qty = material['quantity'];
      final parsedQty = qty is int ? qty : int.tryParse('$qty') ?? 0;
      if (parsedQty <= 0) {
        return (values: null, error: 'كمية المواد يجب أن تكون أكبر من صفر');
      }
    }
  }

  return (
    values: AppointmentFormValues(
      patientId: patientId.trim(),
      date: date.toIso8601String().split('T').first,
      time: time,
      status: storageStatus,
      notes: notes.trim(),
      materials: List<Map<String, dynamic>>.from(materials),
    ),
    error: null,
  );
}

String? findTimeConflict({
  required String date,
  required String time,
  required List<Appointment> appointments,
  String? excludeId,
  int slotMinutes = kDefaultAppointmentSlotMinutes,
}) {
  final newStart = timeToMinutes(time);
  if (newStart == null) return 'صيغة الوقت غير صالحة';

  final newEnd = newStart + slotMinutes;

  for (final appt in appointments) {
    if (excludeId != null && appt.id == excludeId) continue;
    if (appt.date != date) continue;
    if (appt.status == AppointmentStatus.cancelled) continue;

    final apptStart = timeToMinutes(appt.time);
    if (apptStart == null) continue;
    final apptEnd = apptStart + slotMinutes;

    if (timeRangesOverlap(
      startA: newStart,
      endA: newEnd,
      startB: apptStart,
      endB: apptEnd,
    )) {
      return 'يتعارض مع موعد آخر (${appt.patientName} – ${appt.time})';
    }
  }

  return null;
}
