import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';
import '../../../inventory_manage/controller/daily_inventory_controller.dart';
import '../../../inventory_manage/utils/money_format.dart';
import '../../controllers/dash_board_controller.dart';
import 'dashboard_kpi_chip.dart';

class DashboardFinanceStrip extends StatelessWidget {
  const DashboardFinanceStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashBoardController>();
    final dailyInventory = Get.isRegistered<DailyInventoryController>()
        ? Get.find<DailyInventoryController>()
        : null;

    return Obx(() {
      final showDetails = dash.showFinanceDetails.value;
      final todayPayments = dailyInventory?.daily.paymentsReceived ?? 0;
      final todayLabel = formatMoneyCompact(todayPayments);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'الملخص المالي',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: dash.toggleFinanceDetails,
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
                    fontSize: 14,
                    color: AppColors.mainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                DashboardKpiChip(
                  title: 'دفعات اليوم',
                  value: todayLabel,
                  icon: Icons.payments_outlined,
                  color: AppColors.mainColor,
                ),
                const SizedBox(width: 8),
                DashboardKpiChip(
                  title: 'مدفوعات الشهر',
                  value: formatMoneyCompact(dash.monthlyPaid.value),
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                DashboardKpiChip(
                  title: 'صافي الشهر',
                  value: formatMoneyCompact(dash.monthlyNetProfit.value),
                  icon: Icons.trending_up,
                  color: dash.monthlyNetProfit.value >= 0
                      ? Colors.purple
                      : Colors.red,
                  subtitle: dash.monthlyNetProfit.value >= 0 ? 'ربح' : 'خسارة',
                ),
              ],
            ),
          ),
          if (showDetails) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _detailRow(
                    'إجمالي المدفوعات الشهرية',
                    formatMoney(dash.monthlyPaid.value),
                  ),
                  const SizedBox(height: 6),
                  _detailRow(
                    'صافي الربح الشهري',
                    formatMoney(dash.monthlyNetProfit.value),
                    valueColor: dash.monthlyNetProfit.value >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  if (dailyInventory != null) ...[
                    const SizedBox(height: 6),
                    _detailRow(
                      'دفعات اليوم',
                      dailyInventory.daily.paymentsLabel,
                    ),
                    const SizedBox(height: 6),
                    _detailRow(
                      'نفقات الشهر',
                      dailyInventory.monthly.expensesLabel,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
