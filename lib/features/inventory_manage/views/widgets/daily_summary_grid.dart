import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controller/daily_inventory_controller.dart';
import '../../utils/clinic_expense_categories.dart';
import '../../utils/money_format.dart';
import 'daily_summary_card.dart';

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.daily,
    required this.monthly,
    required this.allTime,
    required this.dailyText,
    required this.monthlyText,
    required this.allTimeText,
    required this.icon,
    required this.color,
    this.highlightNegative = false,
  });

  final String title;
  final double daily;
  final double monthly;
  final double allTime;
  final String dailyText;
  final String monthlyText;
  final String allTimeText;
  final IconData icon;
  final Color color;
  final bool highlightNegative;
}

class DailySummaryGrid extends StatelessWidget {
  const DailySummaryGrid({super.key, required this.controller});

  final DailyInventoryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final report = controller.financialReport.value;
      if (report == null) return const SizedBox.shrink();

      final monthSummary = controller.displayedMonthSummary;
      final monthLabel = controller.displayedMonthLabel;
      final showDetails = controller.showSummaryDetails.value;

      final items = [
        _SummaryItem(
          title: 'فواتير',
          daily: report.daily.invoicesTotal,
          monthly: monthSummary.invoicesTotal,
          allTime: report.allTime.invoicesTotal,
          dailyText: controller.moneyLabelInvoices(InventoryMoneyScope.today),
          monthlyText: controller.moneyLabelInvoices(InventoryMoneyScope.month),
          allTimeText: controller.moneyLabelInvoices(
            InventoryMoneyScope.allTime,
          ),
          icon: Icons.receipt_long,
          color: Colors.blue,
        ),
        _SummaryItem(
          title: 'مدفوعات',
          daily: report.daily.paymentsReceived,
          monthly: monthSummary.paymentsReceived,
          allTime: report.allTime.paymentsReceived,
          dailyText: controller.moneyLabelPayments(InventoryMoneyScope.today),
          monthlyText: controller.moneyLabelPayments(InventoryMoneyScope.month),
          allTimeText: controller.moneyLabelPayments(
            InventoryMoneyScope.allTime,
          ),
          icon: Icons.payments,
          color: Colors.green,
        ),
        _SummaryItem(
          title: 'متبقي',
          daily: report.daily.outstanding,
          monthly: monthSummary.outstanding,
          allTime: report.allTime.outstanding,
          dailyText: controller.moneyLabelOutstanding(
            InventoryMoneyScope.today,
          ),
          monthlyText: controller.moneyLabelOutstanding(
            InventoryMoneyScope.month,
          ),
          allTimeText: controller.moneyLabelOutstanding(
            InventoryMoneyScope.allTime,
          ),
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _SummaryItem(
          title: 'نفقات',
          daily: report.daily.expenses,
          monthly: monthSummary.expenses,
          allTime: report.allTime.expenses,
          dailyText: controller.moneyLabelExpenses(InventoryMoneyScope.today),
          monthlyText: controller.moneyLabelExpenses(InventoryMoneyScope.month),
          allTimeText: controller.moneyLabelExpenses(
            InventoryMoneyScope.allTime,
          ),
          icon: Icons.shopping_cart_outlined,
          color: Colors.red,
        ),
        _SummaryItem(
          title: 'صافي النقد',
          daily: report.daily.netCashFlow,
          monthly: monthSummary.netCashFlow,
          allTime: report.allTime.netCashFlow,
          dailyText: controller.moneyLabelNetCash(InventoryMoneyScope.today),
          monthlyText: controller.moneyLabelNetCash(InventoryMoneyScope.month),
          allTimeText: controller.moneyLabelNetCash(
            InventoryMoneyScope.allTime,
          ),
          icon: Icons.account_balance_wallet,
          color: Colors.purple,
          highlightNegative: true,
        ),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'ملخص سريع · $monthLabel',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.toggleSummaryDetails,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  showDetails ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.mainColor,
                ),
                label: Text(
                  showDetails ? 'إخفاء' : 'تفاصيل',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.mainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final item = items[index];
                return DailySummaryCard(
                  title: item.title,
                  dailyAmount: item.daily,
                  monthlyAmount: item.monthly,
                  monthlyLabel: monthLabel,
                  allTimeAmount: item.allTime,
                  dailyAmountText: item.dailyText,
                  monthlyAmountText: item.monthlyText,
                  allTimeAmountText: item.allTimeText,
                  icon: item.icon,
                  color: item.color,
                  highlightNegative: item.highlightNegative,
                );
              },
            ),
          ),
          if (showDetails) ...[
            const SizedBox(height: 8),
            _ExpenseBreakdown(controller: controller, monthLabel: monthLabel),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return DailySummaryCard(
                      title: item.title,
                      dailyAmount: item.daily,
                      monthlyAmount: item.monthly,
                      monthlyLabel: monthLabel,
                      allTimeAmount: item.allTime,
                      dailyAmountText: item.dailyText,
                      monthlyAmountText: item.monthlyText,
                      allTimeAmountText: item.allTimeText,
                      icon: item.icon,
                      color: item.color,
                      highlightNegative: item.highlightNegative,
                      compact: false,
                    );
                  },
                );
              },
            ),
          ],
        ],
      );
    });
  }
}

class _ExpenseBreakdown extends StatelessWidget {
  const _ExpenseBreakdown({required this.controller, required this.monthLabel});

  final DailyInventoryController controller;
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final outputsByCur = controller.displayedMonthInventoryOutputByCurrency;
      final byCategoryCur = controller.displayedMonthExpenseBreakdownCurrency;
      if (outputsByCur.isEmpty && byCategoryCur.isEmpty) {
        return const SizedBox.shrink();
      }

      final chips = <Widget>[];

      if (outputsByCur.isNotEmpty) {
        chips.add(
          _breakdownChip(title: 'مخرجات المخزون', totals: outputsByCur),
        );
      }

      for (final cat in ClinicExpenseCategory.all) {
        final totals = byCategoryCur[cat.id];
        if (totals == null || totals.values.every((v) => v == 0)) continue;
        chips.add(_breakdownChip(title: cat.label, totals: totals));
      }

      if (chips.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفصيل النفقات · $monthLabel',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ),
      );
    });
  }

  Widget _breakdownChip({
    required String title,
    required Map<String, double> totals,
  }) {
    final parts = currencyAmountParts(totals);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text(
            '$title:',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          ...parts.map(
            (p) => Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                p,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
