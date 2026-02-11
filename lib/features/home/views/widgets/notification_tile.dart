import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppointmentStatus { pending, approved, cancelled, done }

class NotificationTile extends StatelessWidget {
  final String name;
  final String time;
  final AppointmentStatus type;
  final VoidCallback? onApprove;
  final VoidCallback? onCancel;

  final ValueChanged<AppointmentStatus>? onStatusChanged;
  final VoidCallback? onTap;
  const NotificationTile({
    super.key,
    required this.name,
    required this.time,
    required this.type,
    this.onApprove,
    this.onCancel,
    this.onStatusChanged,
    this.onTap,
  });

  Color get color {
    switch (type) {
      case AppointmentStatus.pending:
        return const Color(0xFFE9C46A);
      case AppointmentStatus.approved:
        return const Color(0xFF2A9D8F);
      case AppointmentStatus.cancelled:
        return const Color(0xFFE76F51);
      case AppointmentStatus.done:
        return const Color(0xFF264653);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15.r),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 10.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12.sp,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _statusLabel(type),
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // actions
            Row(
              children: [
                if (onApprove != null)
                  IconButton(
                    icon: Icon(Icons.check, color: color, size: 20.sp),
                    onPressed: onApprove,
                    tooltip: 'منتهية',
                  ),
                if (onCancel != null)
                  IconButton(
                    icon: Icon(
                      Icons.block,
                      color: Colors.redAccent,
                      size: 20.sp,
                    ),
                    onPressed: onCancel,
                    tooltip: 'الغاء',
                  ),
                SizedBox(width: 6.w),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(AppointmentStatus status) {
  switch (status) {
    case AppointmentStatus.pending:
      return 'معلقة';
    case AppointmentStatus.approved:
      return 'م,كدة';
    case AppointmentStatus.cancelled:
      return 'ملغية';
    case AppointmentStatus.done:
      return 'تمت';
  }
}
