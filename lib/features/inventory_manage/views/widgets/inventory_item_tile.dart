import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../models/inventory_item.dart';
import '../../models/inventory_stock_status.dart';
import 'inventory_status_badge.dart';

class InventoryItemTile extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InventoryItemTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = item.stockStatus.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: statusColor.withOpacity(.4)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor,
                  child: const Icon(Icons.medication, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              item.quantity.toString(),
              style: GoogleFonts.poppins(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              item.unit,
              style: GoogleFonts.poppins(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${item.lowStockThreshold} ${item.unit}',
              style: GoogleFonts.poppins(),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: InventoryStatusBadge(status: item.stockStatus),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.pendingColor),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: AppColors.cancelledColor,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
