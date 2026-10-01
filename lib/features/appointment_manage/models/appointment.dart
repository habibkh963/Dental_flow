import 'appointment_status.dart';

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String date;
  final String time;
  final AppointmentStatus status;
  final String notes;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.time,
    required this.status,
    required this.notes,
  });

  factory Appointment.fromMap(
    Map<String, dynamic> map, {
    String patientName = '',
  }) {
    return Appointment(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      patientName: map['patient_name']?.toString() ?? patientName,
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      status: AppointmentStatusParsing.fromString(map['status']?.toString()),
      notes: map['notes']?.toString() ?? '',
    );
  }
}
