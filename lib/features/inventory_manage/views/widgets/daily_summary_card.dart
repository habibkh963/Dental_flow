import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/money_format.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({
    super.key,
    required this.title,
    required this.dailyAmount,
    required this.monthlyAmount,
    required this.allTimeAmount,
    required this.icon,
    required this.color,
    this.monthlyLabel = 'شهري',
    this.highlightNegative = false,
    this.compact = true,
  });

  final String title;
  final double dailyAmount;
  final double monthlyAmount;
  final double allTimeAmount;
  final String monthlyLabel;
  final IconData icon;
  final Color color;
  final bool highlightNegative;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return _buildDetailed();
  }

  Widget _buildCompact() {
    final primaryColor = _valueColor(monthlyAmount);

    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatMoneyCompact(monthlyAmount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'اليوم ${formatMoneyCompact(dailyAmount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailed() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _metricRow('يومي', dailyAmount),
          const SizedBox(height: 4),
          _metricRow(monthlyLabel, monthlyAmount),
          const SizedBox(height: 4),
          _metricRow('الكل', allTimeAmount),
        ],
      ),
    );
  }

  Widget _metricRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
        ),
        Flexible(
          child: Text(
            formatMoney(amount),
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _valueColor(amount),
            ),
          ),
        ),
      ],
    );
  }

  Color _valueColor(double value) {
    if (highlightNegative && value < 0) return Colors.red.shade700;
    return color;
  }
}
