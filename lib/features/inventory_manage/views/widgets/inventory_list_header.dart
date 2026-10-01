import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';

class InventoryListHeader extends StatelessWidget {
  const InventoryListHeader({super.key});

  static const _columns = [
    'الاسم',
    'الكمية',
    'الوحدة',
    'الحد الأدنى',
    'الحالة',
    'الاجراءات',
  ];

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
        children: _columns
            .map(
              (label) => Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
