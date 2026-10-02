import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/colors.dart';
import '../features/home/controllers/navigation_controller.dart';

/// System + in-app notification hub for clinic alerts.
///
/// Windows uses in-app banners (no native toast) to avoid ATL build deps.
class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _useNativeNotifications = false;
  final Set<String> _sentKeys = <String>{};

  static const _appointmentsChannelId = 'appointments';
  static const _inventoryChannelId = 'inventory';
  static const _billingChannelId = 'billing';

  Future<void> initialize() async {
    if (_initialized) return;

    // Native plugin is skipped on Windows — see pubspec comment.
    if (Platform.isWindows) {
      _initialized = true;
      _useNativeNotifications = false;
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
    _useNativeNotifications = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    _navigateForPayload(response.payload);
  }

  void _navigateForPayload(String? payload) {
    if (payload == null || !Get.isRegistered<NavigationController>()) return;

    final nav = Get.find<NavigationController>();
    switch (payload) {
      case 'appointments':
        nav.select(2);
        break;
      case 'inventory':
        nav.select(4);
        break;
      case 'billing':
        nav.select(3);
        break;
      case 'notifications':
        nav.openNotificationsPanel();
        break;
    }
  }

  Future<void> evaluateAlerts({
    required List<Map<String, dynamic>> todayAppointments,
    required List<Map<String, dynamic>> lowStockItems,
  }) async {
    await _checkUpcomingAppointments(todayAppointments);
    await _checkInventoryAlerts(lowStockItems);
  }

  Future<void> _checkUpcomingAppointments(
    List<Map<String, dynamic>> appointments,
  ) async {
    final now = DateTime.now();

    for (final apt in appointments) {
      if (!_isActiveAppointment(apt)) continue;

      final id = (apt['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final timeStr = (apt['time'] as String?)?.trim() ?? '';
      final aptTime = _parseTimeToDate(timeStr, now);
      if (aptTime == null || !aptTime.isAfter(now)) continue;

      final minutesUntil = aptTime.difference(now).inMinutes;
      final name = _patientName(apt);
      final timeLabel = _formatTimeLabel(timeStr);

      if (minutesUntil <= 30 && minutesUntil > 10) {
        await _notifyOnce(
          key: 'apt:$id:30m',
          notificationId: id.hashCode,
          title: 'معاينة قادمة',
          body: '$name خلال $minutesUntil دقيقة ($timeLabel)',
          payload: 'appointments',
          channelId: _appointmentsChannelId,
          channelName: 'المعاينات',
          channelDescription: 'تذكير بالمعاينات القادمة',
          importance: Importance.high,
          priority: Priority.high,
          urgent: true,
        );
      } else if (minutesUntil <= 10) {
        await _notifyOnce(
          key: 'apt:$id:10m',
          notificationId: id.hashCode + 1,
          title: 'معاينة عاجلة',
          body: '$name خلال $minutesUntil دقيقة ($timeLabel)',
          payload: 'appointments',
          channelId: _appointmentsChannelId,
          channelName: 'المعاينات',
          channelDescription: 'تذكير بالمعاينات القادمة',
          importance: Importance.max,
          priority: Priority.max,
          urgent: true,
        );
      }
    }
  }

  Future<void> _checkInventoryAlerts(
    List<Map<String, dynamic>> items,
  ) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (final item in items) {
      final id = (item['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final name = item['name']?.toString() ?? 'مادة';
      final qty = (item['qty'] as num?)?.toInt() ?? 0;
      final threshold = (item['threshold'] as num?)?.toInt() ?? 3;
      final unit = item['unit']?.toString() ?? 'وحدة';

      if (qty <= 0) {
        await _notifyOnce(
          key: 'inv:$id:out:$today',
          notificationId: id.hashCode + 10000,
          title: 'نفاد مخزون',
          body: '$name — الكمية 0 $unit',
          payload: 'inventory',
          channelId: _inventoryChannelId,
          channelName: 'المخزون',
          channelDescription: 'تنبيهات انخفاض ونفاد المخزون',
          importance: Importance.max,
          priority: Priority.max,
          urgent: true,
        );
      } else if (qty <= threshold) {
        await _notifyOnce(
          key: 'inv:$id:low:$today',
          notificationId: id.hashCode + 20000,
          title: 'مخزون منخفض',
          body: '$name — متبقي $qty $unit',
          payload: 'inventory',
          channelId: _inventoryChannelId,
          channelName: 'المخزون',
          channelDescription: 'تنبيهات انخفاض ونفاد المخزون',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
      }
    }
  }

  Future<void> notifyInventoryItem({
    required String itemId,
    required String name,
    required int qty,
    required int threshold,
    required String unit,
  }) async {
    if (qty <= 0) {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _notifyOnce(
        key: 'inv:$itemId:out:$today',
        notificationId: itemId.hashCode + 10000,
        title: 'نفاد مخزون',
        body: '$name — الكمية 0 $unit',
        payload: 'inventory',
        channelId: _inventoryChannelId,
        channelName: 'المخزون',
        channelDescription: 'تنبيهات انخفاض ونفاد المخزون',
        importance: Importance.max,
        priority: Priority.max,
        urgent: true,
      );
    } else if (qty <= threshold) {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _notifyOnce(
        key: 'inv:$itemId:low:$today',
        notificationId: itemId.hashCode + 20000,
        title: 'مخزون منخفض',
        body: '$name — متبقي $qty $unit',
        payload: 'inventory',
        channelId: _inventoryChannelId,
        channelName: 'المخزون',
        channelDescription: 'تنبيهات انخفاض ونفاد المخزون',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
    }
  }

  Future<void> notifyPaymentReceived({
    required double amount,
    required String patientLabel,
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'pay:$today:${amount.toStringAsFixed(0)}:$patientLabel';
    await _notifyOnce(
      key: key,
      notificationId: key.hashCode,
      title: 'دفعة مستلمة',
      body: '${amount.toStringAsFixed(0)} ل.س — $patientLabel',
      payload: 'billing',
      channelId: _billingChannelId,
      channelName: 'الفواتير',
      channelDescription: 'إشعارات المدفوعات والفواتير',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
  }

  Future<void> _notifyOnce({
    required String key,
    required int notificationId,
    required String title,
    required String body,
    required String payload,
    required String channelId,
    required String channelName,
    required String channelDescription,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
    bool urgent = false,
  }) async {
    if (!_initialized || _sentKeys.contains(key)) return;

    var delivered = false;

    if (_useNativeNotifications) {
      try {
        await _plugin.show(
          notificationId,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: channelDescription,
              importance: importance,
              priority: priority,
            ),
            iOS: const DarwinNotificationDetails(),
            macOS: const DarwinNotificationDetails(),
          ),
          payload: payload,
        );
        delivered = true;
      } catch (e) {
        debugPrint('Native notification failed ($title): $e');
      }
    }

    if (!delivered) {
      _showInAppBanner(
        title: title,
        body: body,
        payload: payload,
        urgent: urgent,
      );
      delivered = true;
    }

    if (delivered) {
      _sentKeys.add(key);
      if (urgent && Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().openNotificationsPanel();
      }
    }
  }

  void _showInAppBanner({
    required String title,
    required String body,
    required String payload,
    required bool urgent,
  }) {
    if (Get.context == null) return;

    final color = urgent ? Colors.orange.shade800 : AppColors.mainColor;

    Get.rawSnackbar(
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      messageText: Text(
        body,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      duration: urgent ? const Duration(seconds: 10) : const Duration(seconds: 6),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      mainButton: TextButton(
        onPressed: () {
          if (Get.isSnackbarOpen) Get.back();
          _navigateForPayload(payload);
        },
        child: Text(
          'عرض',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  void pruneAppointmentKeys(Iterable<String> activeAppointmentIds) {
    final active = activeAppointmentIds.toSet();
    _sentKeys.removeWhere((key) {
      if (!key.startsWith('apt:')) return false;
      final id = key.split(':').elementAtOrNull(1);
      return id != null && !active.contains(id);
    });
  }

  bool _isActiveAppointment(Map<String, dynamic> apt) {
    final status = (apt['status'] as String? ?? '').toLowerCase();
    return status != 'cancelled' &&
        status != 'done' &&
        status != 'completed';
  }

  String _patientName(Map<String, dynamic> apt) {
    final name = '${apt['first_name'] ?? ''} ${apt['last_name'] ?? ''}'.trim();
    return name.isEmpty ? 'مريض' : name;
  }

  DateTime? _parseTimeToDate(String timeStr, DateTime today) {
    if (timeStr.isEmpty) return null;

    try {
      if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(timeStr)) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(today.year, today.month, today.day, hour, minute);
      }

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
      debugPrint('Error parsing time "$timeStr": $e');
    }

    return null;
  }

  String _formatTimeLabel(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (Get.context != null) {
          return TimeOfDay(hour: hour, minute: minute).format(Get.context!);
        }
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return timeStr;
  }
}
