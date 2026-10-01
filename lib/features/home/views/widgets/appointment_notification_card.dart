import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AppointmentNotificationCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final bool isUpcoming;
  final VoidCallback? onTap;

  const AppointmentNotificationCard({
    required this.appointment,
    required this.isUpcoming,
    this.onTap,
    super.key,
  }) : super();

  Duration? _getTimeUntilAppointment() {
    try {
      final now = DateTime.now();
      final timeStr = appointment['time'] as String? ?? '00:00';
      final aptTime = DateTime.parse('2000-01-01 $timeStr');

      // Create a DateTime with today's date and appointment time
      final today = DateTime.now();
      final appointmentDateTime = DateTime(
        today.year,
        today.month,
        today.day,
        aptTime.hour,
        aptTime.minute,
      );

      if (appointmentDateTime.isAfter(now)) {
        return appointmentDateTime.difference(now);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  String _formatTimeUntil(Duration? duration) {
    if (duration == null) return '';

    final minutes = duration.inMinutes;
    final hours = duration.inHours;

    if (minutes < 60) {
      return '$minutes min';
    } else if (hours < 2) {
      return '${hours}h ${minutes % 60}m';
    } else {
      return '${hours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeUntil = _getTimeUntilAppointment();
    final firstName = appointment['first_name'] ?? 'Unknown';
    final lastName = appointment['last_name'] ?? '';
    final phone = appointment['phone'] ?? '';
    final time = appointment['time'] ?? '--:--';
    final status = (appointment['status'] as String? ?? 'مجدولة').toLowerCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUpcoming ? Colors.orange : _getStatusColor(status),
              width: isUpcoming ? 2 : 1,
            ),
            color: isUpcoming
                ? Colors.orange.withOpacity(0.05)
                : Colors.grey[50],
            boxShadow: [
              if (isUpcoming)
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              _buildAppointmentHeaderRow(
                firstName,
                lastName,
                time,
                timeUntil,
                status,
              ),
              const SizedBox(height: 12),
              // Phone
              if (phone.isNotEmpty) _buildAppointmentPhoneRow(phone),
              // Notes if available
              if ((appointment['notes'] as String?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                _buildAppointmentsNote(),
              ],
              // Bottom Info Bar
              const SizedBox(height: 12),
              _buildAppointmentBottomInfo(status),
            ],
          ),
        ),
      ),
    );
  }

  Padding _buildAppointmentPhoneRow(phone) {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Row(
        children: [
          Icon(Icons.phone, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            phone,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Container _buildAppointmentBottomInfo(status) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withAlpha(150),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 12, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              DateFormat('MMM d, yyyy').format(DateTime.now()),
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isUpcoming ? Colors.orange : _getStatusColor(status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isUpcoming ? 'عاجلة' : 'مجدولة',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Padding _buildAppointmentsNote() {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Text(
        'ملاحظات: ${appointment['notes']}',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Row _buildAppointmentHeaderRow(
    firstName,
    lastName,
    time,
    Duration? timeUntil,
    String status,
  ) {
    return Row(
      children: [
        // Alert Indicator
        if (isUpcoming) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.access_time, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.event, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
        ],
        // Patient Name and Time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$firstName $lastName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Time Until & Status
        if (isUpcoming)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatTimeUntil(timeUntil),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
        else
          Chip(
            label: Text(status),
            backgroundColor: _getStatusColor(status),
            shadowColor: _getStatusColor(status).withAlpha(150),
            labelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'done':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.blue;
      default:
        return Colors.amber.shade600;
    }
  }
}
