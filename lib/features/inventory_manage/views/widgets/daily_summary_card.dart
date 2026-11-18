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
    this.dailyAmountText,
    this.monthlyAmountText,
    this.allTimeAmountText,
    this.highlightNegative = false,
    this.compact = true,
  });

  final String title;
  final double dailyAmount;
  final double monthlyAmount;
  final double allTimeAmount;
  final String? dailyAmountText;
  final String? monthlyAmountText;
  final String? allTimeAmountText;
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
          _amountText(
            monthlyAmountText ?? formatMoneyCompact(monthlyAmount),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'اليوم ',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              Expanded(
                child: _amountText(
                  dailyAmountText ?? formatMoneyCompact(dailyAmount),
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
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
          _metricRow(
            'يومي',
            dailyAmountText ?? formatMoney(dailyAmount),
          ),
          const SizedBox(height: 4),
          _metricRow(
            monthlyLabel,
            monthlyAmountText ?? formatMoney(monthlyAmount),
          ),
          const SizedBox(height: 4),
          _metricRow(
            'الكل',
            allTimeAmountText ?? formatMoney(allTimeAmount),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String amountText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
        ),
        Flexible(
          child: _amountText(
            amountText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _valueColor(_parseLeadingAmount(amountText)),
            alignEnd: true,
          ),
        ),
      ],
    );
  }

  double _parseLeadingAmount(String text) {
    final match = RegExp(r'[\d,]+\.?\d*').firstMatch(text);
    if (match == null) return 0;
    return double.tryParse(match.group(0)!.replaceAll(',', '')) ?? 0;
  }

  Widget _amountText(
    String text, {
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    bool alignEnd = false,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
    );
  }

  Color _valueColor(double value) {
    if (highlightNegative && value < 0) return Colors.red.shade700;
    return color;
  }
}
