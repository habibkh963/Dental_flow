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
      final _ = dash.ledgerRevision.value;
      final showDetails = dash.showFinanceDetails.value;
      final todayPaymentsLabel = dailyInventory != null
          ? dailyInventory.moneyLabelPayments(InventoryMoneyScope.today)
          : formatAmountsByCurrency(const {});

      final monthlyPaidLabel = formatAmountsByCurrency(
        Map<String, double>.from(dash.monthlyPaidByCurrency),
      );
      final monthlyNetLabel = formatAmountsByCurrency(
        Map<String, double>.from(dash.monthlyNetByCurrency),
      );
      final netPositive =
          dash.monthlyNetByCurrency.values.every((v) => v >= 0) &&
          dash.monthlyNetByCurrency.isNotEmpty;

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
            height: 130,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                DashboardKpiChip(
                  title: 'وارد اليوم المختار',
                  value: dash.ledgerDayInflowLabel,
                  icon: Icons.south_west,
                  color: AppColors.mainColor,
                ),
                const SizedBox(width: 8),
                DashboardKpiChip(
                  title: 'دفعات اليوم',
                  value: todayPaymentsLabel,
                  icon: Icons.payments_outlined,
                  color: Colors.teal,
                ),
                const SizedBox(width: 8),
                DashboardKpiChip(
                  title: 'مدفوعات الشهر',
                  value: monthlyPaidLabel,
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                DashboardKpiChip(
                  title: 'صافي الشهر',
                  value: monthlyNetLabel,
                  icon: Icons.trending_up,
                  color: netPositive ? Colors.purple : Colors.red,
                  subtitle: netPositive ? 'ربح' : 'خسارة',
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
                  _detailRow('إجمالي المدفوعات الشهرية', monthlyPaidLabel),
                  const SizedBox(height: 6),
                  _detailRow(
                    'نفقات الشهر (عملات منفصلة)',
                    formatAmountsByCurrency(
                      Map<String, double>.from(dash.monthlyCostsByCurrency),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _detailRow(
                    'صافي الربح الشهري',
                    monthlyNetLabel,
                    valueColor: netPositive
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(height: 6),
                  _detailRow(
                    'وارد اليوم المختار (شامل اليدوي)',
                    dash.ledgerDayInflowLabel,
                  ),
                  const SizedBox(height: 6),
                  _detailRow('صادر اليوم المختار', dash.ledgerDayOutflowLabel),
                  const SizedBox(height: 6),
                  _detailRow('صافي اليوم المختار', dash.ledgerDayNetLabel),
                  if (dailyInventory != null) ...[
                    const SizedBox(height: 6),
                    _detailRow(
                      'دفعات اليوم',
                      dailyInventory.moneyLabelPayments(
                        InventoryMoneyScope.today,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _detailRow(
                      'نفقات العيادة اليوم',
                      formatAmountsByCurrency(
                        Map<String, double>.from(
                          dash.clinicExpensesTodayByCurrency,
                        ),
                      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700]),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
