import 'package:dental_managment_system/services/database/database_service_io.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dental_managment_system/features/home/controllers/navigation_controller.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class DashBoardController extends GetxController {
  final db = DatabaseService.instance;

  RxInt numberOfPatients = 0.obs;
  RxInt appointmentsToday = 0.obs;
  RxInt lowStockCount = 0.obs;
  RxBool isLoading = false.obs;

  // New: Lists for appointments and inventory with notifications
  RxList<Map<String, dynamic>> todayAppointments = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> lowStockItems = <Map<String, dynamic>>[].obs;

  // Notification state
  RxBool hasUrgentAppointments = false.obs;
  RxBool hasLowStock = false.obs;
  final showFinanceDetails = false.obs;

  // 💰 الأرباح والإيرادات الشهرية
  RxDouble monthlyNetProfit = 0.0.obs;
  RxDouble monthlyPaid = 0.0.obs;

  // track which appointments we've already notified about (by id)
  final Set<String> _notifiedAppointmentIds = <String>{};

  late Timer _refreshTimer;
  late Timer _notificationTimer;

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    // initialize local notifications (non-blocking)
    _initNotifications();
    loadStats();
    // Refresh every 30 seconds to check for upcoming appointments
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      loadStats();
    });

    // Background notification check: every 5 minutes, check for appointments
    // within the next 7 minutes and notify the user.
    _notificationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkForUpcomingAndNotify();
    });
    // also run the check immediately on init
    _checkForUpcomingAndNotify();
  }

  /// Parse a time string into a DateTime on the provided reference date (`today`).
  /// Supports formats like 'HH:mm', 'H:mm', 'h:mm a' (e.g. '5:50 PM'), and ISO datetimes.
  DateTime? _parseTimeToDate(String timeStr, DateTime today) {
    if (timeStr.isEmpty) return null;

    try {
      // 24-hour formats like '09:30' or '9:30' or with seconds '09:30:00'
      if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?\$').hasMatch(timeStr)) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(today.year, today.month, today.day, hour, minute);
      }

      // Try parsing locale-aware time like '5:50 PM'
      try {
        final parsed = DateFormat.jm().parse(timeStr);
        return DateTime(
          today.year,
          today.month,
          today.day,
          parsed.hour,
          parsed.minute,
        );
      } catch (_) {}

      // Try a generic DateTime parse (in case DB stores full datetime)
      try {
        final parsed = DateTime.parse(timeStr);
        return DateTime(
          today.year,
          today.month,
          today.day,
          parsed.hour,
          parsed.minute,
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('Error parsing time string "$timeStr": $e');
    }

    return null;
  }

  @override
  void onClose() {
    _refreshTimer.cancel();
    _notificationTimer.cancel();
    super.onClose();
  }

  void toggleFinanceDetails() =>
      showFinanceDetails.value = !showFinanceDetails.value;

  @override
  Future<void> refresh() => loadStats();

  Future<void> loadStats() async {
    try {
      isLoading.value = true;

      // Load counts
      final patients = await db.getPatientsCount();
      final appointments = await db.countAppointmentsToday();
      final lowStock = await db.countLowStock(threshold: 5);

      numberOfPatients.value = patients;
      appointmentsToday.value = appointments;
      lowStockCount.value = lowStock;

      // Load detailed lists
      final todayAppts = await db.getTodayAppointments();
      final lowItems = await db.getLowStockItems(threshold: 3);

      todayAppointments.value = todayAppts;
      lowStockItems.value = lowItems;

      // Check for urgent notifications
      hasUrgentAppointments.value = _hasUpcomingAppointments(todayAppts);
      hasLowStock.value = lowItems.isNotEmpty;

      // 💰 حساب الأرباح الشهرية
      await _calculateMonthlyStats();

      // cleanup and notify for upcoming appointments
      _cleanupNotified(todayAppts);
      _notifyUpcomingAppointments(todayAppts);
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 💰 حساب الإحصائيات المالية الشهرية
  Future<void> _calculateMonthlyStats() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // الحصول على جميع المدفوعات للشهر الحالي
      final payments = await db.db.query(
        'payments',
        where: 'strftime("%Y-%m", datetime(substr(paid_at, 1, 19))) = ?',
        whereArgs: [DateFormat('yyyy-MM').format(now)],
      );

      double totalPaid = 0;
      for (var payment in payments) {
        totalPaid += (payment['amount'] as num?)?.toDouble() ?? 0;
      }

      // حساب التكاليف من مخرجات المخزن للشهر الحالي
      double totalCosts = 0;
      try {
        final inventoryOutputs = await db.db.query(
          'inventory_outputs',
          where: 'date >= ? AND date <= ?',
          whereArgs: [
            startOfMonth.toIso8601String(),
            endOfMonth.toIso8601String(),
          ],
        );

        for (var output in inventoryOutputs) {
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

  bool _hasUpcomingAppointments(List<Map<String, dynamic>> appointments) {
    final now = DateTime.now();
    final threshold = now.add(const Duration(minutes: 30));
    for (var apt in appointments) {
      try {
        final timeStr = (apt['time'] as String?)?.trim() ?? '';
        final aptTime = _parseTimeToDate(timeStr, now);
        if (aptTime == null) continue;
        if (aptTime.isAfter(now) && aptTime.isBefore(threshold)) {
          return true;
        }
      } catch (e) {
        debugPrint('Error parsing appointment time: $e');
      }
    }
    return false;
  }

  void _cleanupNotified(List<Map<String, dynamic>> appointments) {
    final ids = appointments.map((a) => (a['id'] ?? '').toString()).toSet();
    _notifiedAppointmentIds.retainAll(ids);
  }

  void _notifyUpcomingAppointments(
    List<Map<String, dynamic>> appointments, {
    Duration threshold = const Duration(minutes: 30),
  }) {
    final now = DateTime.now();
    final deadline = now.add(threshold);

    for (var apt in appointments) {
      try {
        final id = (apt['id'] ?? '').toString();
        if (id.isEmpty) continue;

        if (_notifiedAppointmentIds.contains(id)) continue;

        final timeStr = (apt['time'] as String?)?.trim() ?? '';
        final aptTime = _parseTimeToDate(timeStr, now);
        if (aptTime == null) continue;
        if (aptTime.isAfter(now) && aptTime.isBefore(deadline)) {
          final name = '${apt['first_name'] ?? ''} ${apt['last_name'] ?? ''}'
              .trim();

          // show snack with an action to open appointments
          Get.snackbar(
            'Upcoming Appointment',
            '${name.isEmpty ? 'Patient' : name} at ${_formatTime(timeStr)}',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 8),
            mainButton: TextButton(
              onPressed: () {
                final nav = Get.isRegistered<NavigationController>()
                    ? Get.find<NavigationController>()
                    : null;
                if (nav != null) nav.select(2);
                // close the snackbar
                if (Get.isSnackbarOpen) Get.back();
              },
              child: const Text('Open'),
            ),
          );

          // also fire a local system notification
          _showLocalNotification(
            id.hashCode,
            'Upcoming Appointment',
            '${name.isEmpty ? 'Patient' : name} at ${_formatTime(timeStr)}',
          );

          _notifiedAppointmentIds.add(id);
        }
      } catch (e) {
        debugPrint('Error checking appointment for notification: $e');
      }
    }
  }

  // Fetch today's appointments and notify for those within the next 7 minutes.
  Future<void> _checkForUpcomingAndNotify() async {
    try {
      final appts = await db.getTodayAppointments();
      _cleanupNotified(appts);
      _notifyUpcomingAppointments(appts, threshold: const Duration(minutes: 7));
    } catch (e) {
      debugPrint('Error during background notify check: $e');
    }
  }

  // Initialize local notifications for supported platforms
  void _initNotifications() {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final darwinSettings = DarwinInitializationSettings();

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // If user taps the notification, open Appointments page
        final nav = Get.isRegistered<NavigationController>()
            ? Get.find<NavigationController>()
            : null;
        if (nav != null) nav.select(2);
      },
    );
  }

  Future<void> _showLocalNotification(int id, String title, String body) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'appointments_channel',
        'Appointments',
        channelDescription: 'Notifications for upcoming appointments',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      final darwinDetails = DarwinNotificationDetails();
      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        details,
        payload: id.toString(),
      );
    } catch (e) {
      // fallback to snackbar if notifications fail
      debugPrint('Local notification failed: $e');
    }
  }

  // Format a HH:mm time string into device-local display
  String _formatTime(String? timeStr) {
    if (timeStr == null) return '--:--';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(0, 0, 0, hour, minute);
      return TimeOfDay.fromDateTime(dt).format(Get.context!);
    } catch (_) {
      return timeStr;
    }
  }
}
