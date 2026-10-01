DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isToday(DateTime value) => isSameDay(value, DateTime.now());

bool isSameMonth(DateTime value, DateTime reference) =>
    value.year == reference.year && value.month == reference.month;

bool isDateInRange(DateTime value, DateTime start, DateTime end) {
  final date = dateOnly(value);
  final rangeStart = dateOnly(start);
  final rangeEnd = dateOnly(end);
  return !date.isBefore(rangeStart) && !date.isAfter(rangeEnd);
}

DateTime startOfMonth(DateTime reference) =>
    DateTime(reference.year, reference.month, 1);

DateTime endOfMonth(DateTime reference) =>
    DateTime(reference.year, reference.month + 1, 0);

/// Ensures [start] is not after [end]; swaps when needed.
(DateTime start, DateTime end) normalizeRange(DateTime start, DateTime end) {
  final s = dateOnly(start);
  final e = dateOnly(end);
  if (s.isAfter(e)) return (e, s);
  return (s, e);
}

String formatDisplayDate(DateTime date) {
  final d = dateOnly(date);
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

const _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String formatMonthLabel(DateTime date) {
  final month = startOfMonth(date);
  return '${_arabicMonths[month.month - 1]} ${month.year}';
}

bool isSameMonthReference(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

/// Months from [earliest] through the current month, newest first.
List<DateTime> enumerateMonths({DateTime? earliest, DateTime? through}) {
  final end = startOfMonth(through ?? DateTime.now());
  final start = startOfMonth(earliest ?? end);
  final months = <DateTime>[];
  var cursor = end;
  while (!cursor.isBefore(start)) {
    months.add(cursor);
    cursor = DateTime(cursor.year, cursor.month - 1, 1);
  }
  return months;
}
