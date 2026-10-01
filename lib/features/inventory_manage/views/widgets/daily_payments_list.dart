import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/colors.dart';
import '../../controller/daily_inventory_controller.dart';
import '../../utils/money_format.dart';
import 'daily_empty_state.dart';

class DailyPaymentsList extends StatelessWidget {
  const DailyPaymentsList({super.key, required this.controller});

  final DailyInventoryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final payments = controller.dailyPaymentsList;

      if (payments.isEmpty) {
        return const DailyEmptyState(
          message: 'لا توجد دفعات في الفترة المحددة',
          icon: Icons.payments_outlined,
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: payments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final payment = payments[index];
          final date = payment['date'] as DateTime;
          final amount = payment['amount'] as double;
          final method = payment['payment_method'] ?? 'نقدي';
          final notes = (payment['notes'] as String?)?.trim() ?? '';

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.mainColor.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payment, color: Colors.green),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE، d MMMM yyyy', 'ar').format(date),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'طريقة الدفع: $method',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          notes,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  formatMoney(amount),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
