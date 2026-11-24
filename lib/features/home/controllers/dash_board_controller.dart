import 'package:dental_managment_system/services/database/database_service_io.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../services/app_notification_service.dart';
import '../../inventory_manage/utils/money_format.dart';
import 'dart:async';

class DashBoardController extends GetxController {
  final db = DatabaseService.instance;

  RxInt numberOfPatients = 0.obs;
  RxInt appointmentsToday = 0.obs;
  RxInt lowStockCount = 0.obs;
  RxBool isLoading = false.obs;

  RxList<Map<String, dynamic>> todayAppointments = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> lowStockItems = <Map<String, dynamic>>[].obs;

  RxBool hasUrgentAppointments = false.obs;
  RxBool hasLowStock = false.obs;
  final showFinanceDetails = false.obs;

  RxDouble monthlyNetProfit = 0.0.obs;
  RxDouble monthlyPaid = 0.0.obs;
  final monthlyPaidByCurrency = <String, double>{}.obs;
  final monthlyCostsByCurrency = <String, double>{}.obs;
  final monthlyNetByCurrency = <String, double>{}.obs;
  final clinicExpensesTodayByCurrency = <String, double>{}.obs;

  final selectedLedgerDay = Rx<DateTime>(DateTime.now());
  final ledgerIncomes = <Map<String, dynamic>>[].obs;
  final ledgerOutgoings = <Map<String, dynamic>>[].obs;
  final ledgerIncomeTotalsByCurrency = <String, double>{}.obs;
  final ledgerOutgoingTotalsByCurrency = <String, double>{}.obs;
  final ledgerRevision = 0.obs;
  final ledgerLoading = false.obs;

  late Timer _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    loadStats();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      loadStats();
    });
  }

  @override
  void onClose() {
    _refreshTimer.cancel();
    super.onClose();
  }

  void toggleFinanceDetails() =>
      showFinanceDetails.value = !showFinanceDetails.value;

  @override
  Future<void> refresh() => loadStats();

  /// بعد إضافة إيراد/مصروف يدوي — إعادة تحميل اليوم والملخص المالي دون إعادة تحميل كامل ثقيل.
  Future<void> reloadLedgerAndFinance() async {
    final day = DateTime(
      selectedLedgerDay.value.year,
      selectedLedgerDay.value.month,
      selectedLedgerDay.value.day,
    );
    await loadDayLedger(day);
    await _calculateMonthlyStats();
  }

  Future<void> loadStats() async {
    try {
      isLoading.value = true;

      numberOfPatients.value = await db.getPatientsCount();
      appointmentsToday.value = await db.countAppointmentsToday();
      lowStockCount.value = await db.countLowStock(threshold: 5);

      final todayAppts = await db.getTodayAppointments();
      final lowItems = await db.getLowStockItems(threshold: 3);

      todayAppointments.value = todayAppts.where((a) {
        final status = (a['status'] as String? ?? '').toLowerCase();
        return status != 'done' && status != 'completed';
      }).toList();
      lowStockItems.value = lowItems;

      hasUrgentAppointments.value =
          _hasUpcomingAppointmentsWithin(todayAppts, const Duration(minutes: 30));
      hasLowStock.value = lowItems.isNotEmpty;

      await _calculateMonthlyStats();

      AppNotificationService.instance.pruneAppointmentKeys(
        todayAppts.map((a) => (a['id'] ?? '').toString()),
      );
      await AppNotificationService.instance.evaluateAlerts(
        todayAppointments: todayAppts,
        lowStockItems: lowItems,
      );

      await loadDayLedger(selectedLedgerDay.value);
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _calculateMonthlyStats() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final payments = await db.db.query(
        'payments',
        where: 'strftime("%Y-%m", datetime(substr(paid_at, 1, 19))) = ?',
        whereArgs: [DateFormat('yyyy-MM').format(now)],
      );

      final paidByCurrency = <String, double>{};
      var totalPaid = 0.0;
      for (final payment in payments) {
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
        final code = payment['currency']?.toString().trim();
        final currency =
            (code != null && code.isNotEmpty) ? code : 'SYP';
        paidByCurrency[currency] = (paidByCurrency[currency] ?? 0) + amount;
        totalPaid += amount;
      }

      final costsByCurrency = <String, double>{};
      var totalCosts = 0.0;
      try {
        final inventoryOutputs = await db.db.query(
          'inventory_outputs',
          where: 'date >= ? AND date <= ?',
          whereArgs: [
            startOfMonth.toIso8601String(),
            endOfMonth.toIso8601String(),
          ],
        );

        for (final output in inventoryOutputs) {
          final amount = (output['price'] as num?)?.toDouble() ?? 0;
          final code = output['currency']?.toString().trim();
          final currency =
              (code != null && code.isNotEmpty) ? code : 'SYP';
          costsByCurrency[currency] =
              (costsByCurrency[currency] ?? 0) + amount;
          totalCosts += amount;
        }

        final clinicExpenses = await db.db.query(
          'clinic_expenses',
          where: 'expense_date >= ? AND expense_date <= ?',
          whereArgs: [
            startOfMonth.toIso8601String(),
            endOfMonth.toIso8601String(),
          ],
        );

        for (final expense in clinicExpenses) {
          final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
          final code = expense['currency']?.toString().trim();
          final currency =
              (code != null && code.isNotEmpty) ? code : 'SYP';
          costsByCurrency[currency] =
              (costsByCurrency[currency] ?? 0) + amount;
          totalCosts += amount;
        }

        final manualIncome = await db.db.query(
          'daily_ledger_entries',
          where:
              "entry_type = 'income' AND strftime('%Y-%m', datetime(substr(entry_date, 1, 19))) = ?",
          whereArgs: [DateFormat('yyyy-MM').format(now)],
        );
        for (final row in manualIncome) {
          final amount = (row['amount'] as num?)?.toDouble() ?? 0;
          final code = row['currency']?.toString().trim();
          final currency =
              (code != null && code.isNotEmpty) ? code : 'SYP';
          paidByCurrency[currency] = (paidByCurrency[currency] ?? 0) + amount;
          totalPaid += amount;
        }

        final manualExpense = await db.db.query(
          'daily_ledger_entries',
          where:
              "entry_type = 'expense' AND strftime('%Y-%m', datetime(substr(entry_date, 1, 19))) = ?",
          whereArgs: [DateFormat('yyyy-MM').format(now)],
        );
        for (final row in manualExpense) {
          final amount = (row['amount'] as num?)?.toDouble() ?? 0;
          final code = row['currency']?.toString().trim();
          final currency =
              (code != null && code.isNotEmpty) ? code : 'SYP';
          costsByCurrency[currency] =
              (costsByCurrency[currency] ?? 0) + amount;
          totalCosts += amount;
        }
      } catch (e) {
        debugPrint('Error calculating costs: $e');
      }

      final netByCurrency = <String, double>{};
      for (final code in {...paidByCurrency.keys, ...costsByCurrency.keys}) {
        netByCurrency[code] =
            (paidByCurrency[code] ?? 0) - (costsByCurrency[code] ?? 0);
      }

      monthlyPaid.value = totalPaid;
      monthlyNetProfit.value = totalPaid - totalCosts;
      monthlyPaidByCurrency.assignAll(paidByCurrency);
      monthlyCostsByCurrency.assignAll(costsByCurrency);
      monthlyNetByCurrency.assignAll(netByCurrency);

      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final todayClinic = await db.db.query(
        'clinic_expenses',
        where:
            "date(substr(COALESCE(expense_date, created_at), 1, 10)) = ?",
        whereArgs: [todayStr],
      );
      clinicExpensesTodayByCurrency.assignAll(
        sumAmountsByCurrency(todayClinic, 'amount'),
      );
    } catch (e) {
      debugPrint('Error calculating monthly stats: $e');
    }
  }

  bool _hasUpcomingAppointmentsWithin(
    List<Map<String, dynamic>> appointments,
    Duration window,
  ) {
    final now = DateTime.now();
    final deadline = now.add(window);

    for (final apt in appointments) {
      final status = (apt['status'] as String? ?? '').toLowerCase();
      if (status == 'cancelled' || status == 'done' || status == 'completed') {
        continue;
      }

      final timeStr = (apt['time'] as String?)?.trim() ?? '';
      final parsed = _parseAppointmentTime(timeStr, now);
      if (parsed != null && parsed.isAfter(now) && parsed.isBefore(deadline)) {
        return true;
      }
    }
    return false;
  }

  DateTime? _parseAppointmentTime(String timeStr, DateTime today) {
    if (timeStr.isEmpty) return null;
    try {
      if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(timeStr)) {
        final parts = timeStr.split(':');
        return DateTime(
          today.year,
          today.month,
          today.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> setLedgerDay(DateTime day) async {
    selectedLedgerDay.value = DateTime(day.year, day.month, day.day);
    await loadDayLedger(selectedLedgerDay.value);
  }

  Future<void> loadDayLedger(DateTime day) async {
    final normalized = DateTime(day.year, day.month, day.day);
    try {
      ledgerLoading.value = true;
      final bundle = await db.getFinancialMovementsForDate(normalized);
      ledgerIncomes.assignAll(bundle['incomes'] ?? const []);
      ledgerOutgoings.assignAll(bundle['outgoings'] ?? const []);
      _syncLedgerSummaryTotals();
      ledgerRevision.value++;
    } catch (e) {
      debugPrint('Error loading day ledger: $e');
      ledgerIncomes.clear();
      ledgerOutgoings.clear();
      _syncLedgerSummaryTotals();
      ledgerRevision.value++;
    } finally {
      ledgerLoading.value = false;
    }
  }

  void _syncLedgerSummaryTotals() {
    ledgerIncomeTotalsByCurrency.assignAll(
      sumAmountsByCurrency(ledgerIncomes, 'amount'),
    );
    ledgerOutgoingTotalsByCurrency.assignAll(
      sumAmountsByCurrency(ledgerOutgoings, 'amount'),
    );
  }

  String get ledgerDayInflowLabel =>
      formatAmountsByCurrency(Map<String, double>.from(ledgerIncomeTotalsByCurrency));

  String get ledgerDayOutflowLabel =>
      formatAmountsByCurrency(Map<String, double>.from(ledgerOutgoingTotalsByCurrency));

  String get ledgerDayNetLabel {
    final codes = {
      ...ledgerIncomeTotalsByCurrency.keys,
      ...ledgerOutgoingTotalsByCurrency.keys,
    };
    if (codes.isEmpty) return formatMoneyCompact(0, currencyCode: 'SYP');
    if (codes.length > 1) return 'صافي اليوم — عدة عملات';
    final code = codes.first;
    final net = (ledgerIncomeTotalsByCurrency[code] ?? 0) -
        (ledgerOutgoingTotalsByCurrency[code] ?? 0);
    return 'صافي ${formatMoneyCompact(net, currencyCode: code)}';
  }
}
