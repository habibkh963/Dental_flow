import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/colors.dart';
import '../../controller/daily_inventory_controller.dart';
import '../../utils/money_format.dart';
import 'daily_empty_state.dart';

class DailyOutputsSection extends StatelessWidget {
  const DailyOutputsSection({super.key, required this.controller});

  final DailyInventoryController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'المخرجات (المواد المستخدمة)',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: controller.showAddOutputDialog,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text('إضافة مخرج', style: GoogleFonts.poppins()),
            ),
            const SizedBox(width: 8),
            Obx(() {
              if (controller.inventoryOutputs.isEmpty) {
                return const SizedBox.shrink();
              }
              return OutlinedButton.icon(
                onPressed: controller.showFinalizeDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade400),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('الجرد النهائي', style: GoogleFonts.poppins()),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          final outputs = controller.filteredOutputs;

          if (outputs.isEmpty) {
            return const DailyEmptyState(
              message: 'لا توجد مخرجات في الفترة المحددة',
              icon: Icons.inventory_2_outlined,
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: outputs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final output = outputs[index];
              final itemName = output['item_name']?.toString() ?? 'غير محدد';
              final quantity = (output['quantity'] as num?)?.toDouble() ?? 0;
              final unit = output['unit']?.toString() ?? 'وحدة';
              final price = (output['price'] as num?)?.toDouble() ?? 0;
              final id = output['id']?.toString() ?? '';
              final date = controller.parseDate(
                output['date'] ?? output['created_at'],
              );

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.inventory_2, color: Colors.red),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date != null
                                ? DateFormat('dd/MM/yyyy', 'ar').format(date)
                                : 'تاريخ غير محدد',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'الكمية: $quantity $unit',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatMoney(price),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: id.isEmpty
                              ? null
                              : () => controller.confirmDeleteOutput(
                                    id,
                                    itemName,
                                  ),
                          icon: const Icon(Icons.delete_outline),
                          color: AppColors.cancelledColor,
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }
}
