import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';

class InvoiceListHeader extends StatelessWidget {
  const InvoiceListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          _headerCell('المريض', flex: 2),
          _headerCell('الإجمالي'),
          _headerCell('المتبقي'),
          _headerCell('الحالة'),
          _headerCell('تاريخ الإصدار'),
          _headerCell('الإجراءات'),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    );
  }
}
