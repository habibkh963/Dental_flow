import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Date picker with Arabic labels and clinic-themed styling.
/// Requires [MaterialLocalizations] from [GetMaterialApp] delegates in [main.dart].
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText ?? 'اختر التاريخ',
    cancelText: 'إلغاء',
    confirmText: 'تأكيد',
    initialDatePickerMode: initialDatePickerMode,
    builder: (context, child) {
      if (child == null) return const SizedBox.shrink();

      final base = Theme.of(context);
      return Theme(
        data: base.copyWith(
          colorScheme: base.colorScheme.copyWith(
            primary: AppColors.mainColor,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
          dialogTheme: base.dialogTheme.copyWith(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 12,
            backgroundColor: Colors.white,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            headerBackgroundColor: AppColors.mainColor,
            headerForegroundColor: Colors.white,
            rangeSelectionBackgroundColor:
                AppColors.mainColor.withValues(alpha: 0.15),
            todayForegroundColor: WidgetStateProperty.all(AppColors.mainColor),
            todayBackgroundColor: WidgetStateProperty.all(
              AppColors.mainColor.withValues(alpha: 0.12),
            ),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Colors.grey.shade900;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.mainColor;
              }
              return null;
            }),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            dayStyle: GoogleFonts.poppins(fontSize: 14),
            yearStyle: GoogleFonts.poppins(fontSize: 14),
            weekdayStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            headerHeadlineStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            headerHelpStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mainColor,
              textStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        child: child,
      );
    },
  );
}