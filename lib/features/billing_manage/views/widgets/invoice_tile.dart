import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/invoice.dart';
import '../../models/invoice_status.dart';
import 'invoice_status_badge.dart';

class InvoiceTile extends StatelessWidget {
  const InvoiceTile({
    super.key,
    required this.invoice,
    required this.patientName,
    required this.onTap,
    required this.onDelete,
  });

  final Invoice invoice;
  final String patientName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = invoice.displayStatus;
    final color = status.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: color.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    child: const Icon(Icons.receipt_long, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      patientName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                '${invoice.total.toStringAsFixed(2)} ل.س',
                style: GoogleFonts.poppins(),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                '${invoice.remainingBalance.toStringAsFixed(2)} ل.س',
                style: GoogleFonts.poppins(
                  color: invoice.isFullyPaid ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: InvoiceStatusBadge(status: status),
            ),
            Expanded(
              child: Text(
                DateFormat('yyyy - MM - d\nhh:mm a', 'ar').format(
                  invoice.issuedAt,
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.payment, color: color),
                    onPressed: onTap,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
