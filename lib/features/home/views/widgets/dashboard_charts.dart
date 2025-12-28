import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/colors.dart';
import '../../../../services/database_service.dart';

class DashboardCharts extends StatefulWidget {
  const DashboardCharts({super.key});

  @override
  State<DashboardCharts> createState() => _DashboardChartsState();
}

class _DashboardChartsState extends State<DashboardCharts> {
  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _dashboardFuture = _loadAll();
    setState(() {});
  }

  Future<_DashboardData> _loadAll() async {
    final payments = await DatabaseService.instance.getAllPayments();
    final invoices = await DatabaseService.instance.getInvoices();
    final inventory = await DatabaseService.instance.getInventory();

    return _DashboardData(
      payments: payments,
      invoices: invoices,
      inventory: inventory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        final revenueMap = _groupPaymentsByDay(data.payments, 30);
        final stock = _topInventory(data.inventory, 6);
        final invoiceMap = _groupInvoicesByDay(data.invoices, 7);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            /// TOP ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Revenue chart
                Expanded(
                  flex: 2,
                  child: _card(
                    title: 'Revenue (Last 30 days)',
                    child: SizedBox(
                      height: 220,
                      child: revenueMap.isEmpty
                          ? _empty()
                          : LineChart(_buildLine(revenueMap)),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// Inventory chart
                Expanded(
                  child: _card(
                    title: 'Top Stock',
                    child: SizedBox(
                      height: 220,
                      child: stock.isEmpty
                          ? _empty()
                          : PieChart(_buildPie(stock)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// INVOICES
            _card(
              title: 'Invoices (Last 7 Days)',
              child: SizedBox(
                height: 200,
                child: invoiceMap.isEmpty
                    ? _empty()
                    : BarChart(_buildBar(invoiceMap)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Text('No data available', style: TextStyle(color: Colors.grey)),
    );
  }

  // ================= Helpers =================

  List<MapEntry<String, double>> _groupPaymentsByDay(
    List<Map<String, dynamic>> list,
    int days,
  ) {
    final now = DateTime.now();
    final formatter = DateFormat('MM-dd');

    final map = {
      for (int i = days - 1; i >= 0; i--)
        formatter.format(now.subtract(Duration(days: i))): 0.0,
    };

    for (final p in list) {
      final rawDate = p['paid_at'] ?? p['created_at'];
      final dt = DateTime.tryParse(rawDate.toString());

      if (dt == null) continue;

      final key = formatter.format(dt);
      if (!map.containsKey(key)) continue;

      map[key] = map[key]! + ((p['amount'] as num?)?.toDouble() ?? 0);
    }

    return map.entries.toList();
  }

  List<Map<String, dynamic>> _topInventory(
    List<Map<String, dynamic>> inv,
    int take,
  ) {
    final copy = [...inv];

    copy.sort(
      (a, b) => ((b['qty'] ?? 0) as int).compareTo(((a['qty'] ?? 0) as int)),
    );

    return copy.take(take).toList();
  }

  List<MapEntry<String, double>> _groupInvoicesByDay(
    List<Map<String, dynamic>> list,
    int days,
  ) {
    final now = DateTime.now();
    final formatter = DateFormat('MM-dd');

    final map = {
      for (int i = days - 1; i >= 0; i--)
        formatter.format(now.subtract(Duration(days: i))): 0.0,
    };

    for (final inv in list) {
      final dt = DateTime.tryParse(inv['issued_at'].toString());
      if (dt == null) continue;

      final key = formatter.format(dt);
      if (!map.containsKey(key)) continue;

      map[key] = map[key]! + 1;
    }

    return map.entries.toList();
  }

  LineChartData _buildLine(List<MapEntry<String, double>> data) {
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    return LineChartData(
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.mainColor,
          barWidth: 3,
          dotData: FlDotData(show: false),
        ),
      ],
    );
  }

  BarChartData _buildBar(List<MapEntry<String, double>> data) {
    return BarChartData(
      gridData: FlGridData(show: true),
      barGroups: data
          .asMap()
          .entries
          .map(
            (e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: AppColors.mainColor,
                  width: 14,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  PieChartData _buildPie(List<Map<String, dynamic>> items) {
    final total = items.fold<double>(
      0,
      (sum, e) => sum + ((e['qty'] as num?)?.toDouble() ?? 0),
    );

    return PieChartData(
      centerSpaceRadius: 25,
      sections: items.map((it) {
        final value = ((it['qty'] as num?)?.toDouble() ?? 0);
        final percent = total == 0 ? 0 : (value / total) * 100;

        return PieChartSectionData(
          value: value,
          color: AppColors.mainColor.withOpacity(.6),
          title: '${it['name']}\n${percent.toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 11),
        );
      }).toList(),
    );
  }
}

class _DashboardData {
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> invoices;
  final List<Map<String, dynamic>> inventory;

  _DashboardData({
    required this.payments,
    required this.invoices,
    required this.inventory,
  });
}
