import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const kDefaultAppointmentSlotMinutes = 30;

String formatTimeForStorage(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

String formatTimeForDisplay(String? time) {
  final minutes = timeToMinutes(time);
  if (minutes == null) return time ?? '-';
  final dt = DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);
  return DateFormat.jm('ar').format(dt);
}

/// Parses HH:mm or locale strings like "5:30 PM".
int? timeToMinutes(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final trimmed = value.trim();

  final hhmm = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
  if (hhmm != null) {
    final hour = int.tryParse(hhmm.group(1)!);
    final minute = int.tryParse(hhmm.group(2)!);
    if (hour != null &&
        minute != null &&
        hour >= 0 &&
        hour < 24 &&
        minute >= 0 &&
        minute < 60) {
      return hour * 60 + minute;
    }
  }

  try {
    final dt = DateFormat.jm().parse(trimmed);
    return dt.hour * 60 + dt.minute;
  } catch (_) {
    return null;
  }
}

TimeOfDay? parseTimeOfDay(String? value) {
  final minutes = timeToMinutes(value);
  if (minutes == null) return null;
  return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
}

bool timeRangesOverlap({
  required int startA,
  required int endA,
  required int startB,
  required int endB,
}) {
  return startA < endB && startB < endA;
}
