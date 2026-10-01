import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/inventory_stock_status.dart';

class InventoryStatusBadge extends StatelessWidget {
  final InventoryStockStatus status;

  const InventoryStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.labelAr,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
