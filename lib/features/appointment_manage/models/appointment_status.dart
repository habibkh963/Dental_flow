import 'package:flutter/material.dart';

enum AppointmentStatus {
  scheduled,
  done,
  cancelled,
}

extension AppointmentStatusParsing on AppointmentStatus {
  static AppointmentStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'done':
      case 'completed':
      case 'approved':
        return AppointmentStatus.done;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.scheduled;
    }
  }

  String get storageValue {
    switch (this) {
      case AppointmentStatus.done:
        return 'done';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.scheduled:
        return 'scheduled';
    }
  }

  String get label {
    switch (this) {
      case AppointmentStatus.done:
        return 'مكتمل';
      case AppointmentStatus.cancelled:
        return 'ملغي';
      case AppointmentStatus.scheduled:
        return 'مجدول';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.done:
        return const Color(0xFF264653);
      case AppointmentStatus.cancelled:
        return const Color(0xFFE76F51);
      case AppointmentStatus.scheduled:
        return const Color(0xFF2A9D8F);
    }
  }
}

/// UI dropdown values map to storage via [uiValue].
const kAppointmentStatusOptions = [
  ('scheduled', 'مجدولة'),
  ('completed', 'مكتملة'),
  ('cancelled', 'ملغية'),
];

String statusUiValue(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.done:
      return 'completed';
    case AppointmentStatus.cancelled:
      return 'cancelled';
    case AppointmentStatus.scheduled:
      return 'scheduled';
  }
}

AppointmentStatus statusFromUiValue(String value) {
  switch (value) {
    case 'completed':
      return AppointmentStatus.done;
    case 'cancelled':
      return AppointmentStatus.cancelled;
    default:
      return AppointmentStatus.scheduled;
  }
}
