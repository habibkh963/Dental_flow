import 'package:dental_managment_system/services/database/database_service_io.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../services/app_notification_service.dart';
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

  Future<void> loadStats() async {
    try {
      isLoading.value = true;

      numberOfPatients.value = await db.getPatientsCount();
      appointmentsToday.value = await db.countAppointmentsToday();
      lowStockCount.value = await db.countLowStock(threshold: 5);

      final todayAppts = await db.getTodayAppointments();
      final lowItems = await db.getLowStockItems(threshold: 3);

      todayAppointments.value = todayAppts;
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

      var totalPaid = 0.0;
      for (final payment in payments) {
        totalPaid += (payment['amount'] as num?)?.toDouble() ?? 0;
      }

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
          totalCosts += (output['price'] as num?)?.toDouble() ?? 0;
        }
      } catch (e) {
        debugPrint('Error calculating costs: $e');
      }

      monthlyPaid.value = totalPaid;
      monthlyNetProfit.value = totalPaid - totalCosts;
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
}
