import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../controller/daily_inventory_controller.dart';
import 'daily_summary_card.dart';

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.daily,
    required this.monthly,
    required this.allTime,
    required this.icon,
    required this.color,
    this.highlightNegative = false,
  });

  final String title;
  final double daily;
  final double monthly;
  final double allTime;
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
          icon: Icons.receipt_long,
          color: Colors.blue,
        ),
        _SummaryItem(
          title: 'مدفوعات',
          daily: report.daily.paymentsReceived,
          monthly: monthSummary.paymentsReceived,
          allTime: report.allTime.paymentsReceived,
          icon: Icons.payments,
          color: Colors.green,
        ),
        _SummaryItem(
          title: 'متبقي',
          daily: report.daily.outstanding,
          monthly: monthSummary.outstanding,
          allTime: report.allTime.outstanding,
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _SummaryItem(
          title: 'نفقات',
          daily: report.daily.expenses,
          monthly: monthSummary.expenses,
          allTime: report.allTime.expenses,
          icon: Icons.shopping_cart_outlined,
          color: Colors.red,
        ),
        _SummaryItem(
          title: 'صافي النقد',
          daily: report.daily.netCashFlow,
          monthly: monthSummary.netCashFlow,
          allTime: report.allTime.netCashFlow,
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
            height: 100,
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
                  icon: item.icon,
                  color: item.color,
                  highlightNegative: item.highlightNegative,
                );
              },
            ),
          ),
          if (showDetails) ...[
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
