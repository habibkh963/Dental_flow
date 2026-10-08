import 'package:intl/intl.dart';

String cureLevelLabel(int level) {
  if (level >= 81) return 'شفاء كامل';
  if (level >= 61) return 'تحسن ملحوظ';
  if (level >= 41) return 'منتصف العلاج';
  if (level >= 21) return 'تحسن مبكر';
  return 'بداية العلاج';
}

String formatProgressDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

String formatProgressTime(DateTime date) {
  return DateFormat('HH:mm').format(date);
}

String formatProgressDateTime(DateTime date) {
  return DateFormat('yyyy-MM-dd HH:mm').format(date);
}
