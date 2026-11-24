import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/app_date_picker.dart';
import '../../../../core/colors.dart';
import '../../../../core/currency_utils.dart';
import '../../../inventory_manage/utils/money_format.dart';
import '../../../inventory_manage/controller/daily_inventory_controller.dart';
import '../../../inventory_manage/utils/clinic_expense_categories.dart';
import '../../controllers/dash_board_controller.dart';
import 'quick_daily_entry_dialog.dart';

class DashboardDayLedger extends GetView<DashBoardController> {
  const DashboardDayLedger({super.key});

  Future<void> _pickLedgerDate(BuildContext context) async {
    final picked = await showAppDatePicker(
      context,
      initialDate: controller.selectedLedgerDay.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'تاريخ الحركة المالية',
    );
    if (picked != null) {
      await controller.setLedgerDay(picked);
    }
  }

  void _addClinicExpense() {
    if (Get.isRegistered<DailyInventoryController>()) {
      Get.find<DailyInventoryController>().showAddClinicExpenseDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.ledgerLoading.value && controller.ledgerIncomes.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final dayLabel = DateFormat('dd/MM/yyyy', 'ar')
          .format(controller.selectedLedgerDay.value);
      // Tracks list + summary totals after manual entries.
      final _ = controller.ledgerRevision.value;
      final incomeTotals =
          Map<String, double>.from(controller.ledgerIncomeTotalsByCurrency);
      final outgoingTotals =
          Map<String, double>.from(controller.ledgerOutgoingTotalsByCurrency);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.mainColor.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.mainColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'حركة مالية — $dayLabel',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    controller.ledgerDayNetLabel,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.doneColor,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'تاريخ الحركة',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _pickLedgerDate(context),
                  icon: const Icon(Icons.calendar_month_outlined, size: 20),
                  color: AppColors.mainColor,
                ),
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => showQuickDailyEntryDialog(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('إيراد/مصروف', style: GoogleFonts.poppins(fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: _addClinicExpense,
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: Text('نفقة عيادة', style: GoogleFonts.poppins(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._currencySummaryLines(
              totals: incomeTotals,
              hasEntries: controller.ledgerIncomes.isNotEmpty,
              label: 'وارد',
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 6),
            ..._currencySummaryLines(
              totals: outgoingTotals,
              hasEntries: controller.ledgerOutgoings.isNotEmpty,
              label: 'صادر',
              color: AppColors.cancelledColor,
            ),
            const SizedBox(height: 14),
            if (controller.ledgerIncomes.isEmpty &&
                controller.ledgerOutgoings.isEmpty)
              Text(
                'لا توجد حركات في هذا التاريخ',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              )
            else ...[
              ...controller.ledgerIncomes
                  .map((e) => _entryTile(e, isIncome: true)),
              ...controller.ledgerOutgoings
                  .map((e) => _entryTile(e, isIncome: false)),
            ],
          ],
        ),
      );
    });
  }

  List<Widget> _currencySummaryLines({
    required Map<String, double> totals,
    required bool hasEntries,
    required String label,
    required Color color,
  }) {
  if (!hasEntries || totals.isEmpty) {
      return [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 13)),
            const Spacer(),
            Text(
              formatMoney(0, currencyCode: 'SYP'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ];
    }
  return totals.entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              totals.length > 1 ? '$label (${currencySuffixFor(e.key)})' : label,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const Spacer(),
            Text(
              formatMoney(e.value, currencyCode: e.key),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _typeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _entryTile(Map<String, dynamic> entry, {required bool isIncome}) {
    final title = entry['title']?.toString() ?? '';
    final kind = entry['kind']?.toString() ?? '';
    final rawType = entry['typeLabel']?.toString() ?? '';
    final typeLabel = kind == 'clinic_expense'
        ? ClinicExpenseCategory.byId(rawType).label
        : rawType;
    final note = entry['note']?.toString() ?? '';
    final subtitle = entry['subtitle']?.toString() ?? '';
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
    final currency = entry['currency']?.toString();
    final currencyCode =
        (currency != null && currency.isNotEmpty) ? currency : 'SYP';
    final color = isIncome ? Colors.green.shade700 : AppColors.cancelledColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.isNotEmpty ? title : '—',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (typeLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _typeChip(typeLabel, color),
                    ],
                  ],
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                if (note.isNotEmpty)
                  Text(
                    note,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade800,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${formatMoney(amount, currencyCode: currencyCode)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}