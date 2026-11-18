import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/colors.dart';
import '../../../../core/currency_utils.dart';
import '../../../inventory_manage/utils/money_format.dart';
import '../../controllers/dash_board_controller.dart';

class DashboardDayLedger extends GetView<DashBoardController> {
  const DashboardDayLedger({super.key});

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
                    _netSummaryLabel(controller),
                    textAlign: TextAlign.end,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.doneColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._currencySummaryLines(
              entries: controller.ledgerIncomes,
              label: 'وارد',
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 6),
            ..._currencySummaryLines(
              entries: controller.ledgerOutgoings,
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
    required List<Map<String, dynamic>> entries,
    required String label,
    required Color color,
  }) {
    final totals = <String, double>{};
    for (final e in entries) {
      final code = e['currency']?.toString();
      final c = (code != null && code.isNotEmpty) ? code : 'SYP';
      totals[c] = (totals[c] ?? 0) + ((e['amount'] as num?)?.toDouble() ?? 0);
    }
    if (totals.isEmpty) {
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

  String _netSummaryLabel(DashBoardController c) {
    final all = [...c.ledgerIncomes, ...c.ledgerOutgoings];
    final codes = <String>{
      for (final e in all)
        (e['currency']?.toString().isNotEmpty == true)
            ? e['currency'].toString()
            : 'SYP',
    };
    if (codes.length <= 1) {
      final code = codes.isEmpty ? 'SYP' : codes.first;
      final net = c.ledgerIncomeTotal - c.ledgerOutgoingTotal;
      return 'صافي ${formatMoneyCompact(net, currencyCode: code)}';
    }
    return 'صافي اليوم — عدة عملات';
  }

  Widget _entryTile(Map<String, dynamic> entry, {required bool isIncome}) {
    final title = entry['title']?.toString() ?? '';
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
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
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