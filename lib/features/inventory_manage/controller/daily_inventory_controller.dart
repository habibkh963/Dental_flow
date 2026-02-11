import 'dart:developer';

import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../services/database_service.dart';

class DailyInventoryController extends GetxController {
  final db = DatabaseService.instance;

  var isLoading = false.obs;
  var isIncomes = false.obs;
  var todaySummary = <String, dynamic>{}.obs;
  // Daily payments data
  var dailyPayments = <DateTime, double>{}.obs;
  var dailyPaymentsList = <Map<String, dynamic>>[].obs;
  var _allPaymentsList = <Map<String, dynamic>>[]; // Store original data

  // Invoice summary (legacy - keeping for compatibility)
  var totalInvoicesAmount = 0.0.obs;
  var totalPaidAmount = 0.0.obs;
  var totalUnpaidAmount = 0.0.obs;

  // Daily and Monthly Summary
  var dailyTotalInvoices = 0.0.obs;
  var monthlyTotalInvoices = 0.0.obs;
  var allTimeTotalInvoices = 0.0.obs;
  var dailyPaidAmount = 0.0.obs;
  var monthlyPaidAmount = 0.0.obs;
  var allTimePaidAmount = 0.0.obs;
  var dailyUnpaidAmount = 0.0.obs;
  var monthlyUnpaidAmount = 0.0.obs;
  var allTimeUnpaidAmount = 0.0.obs;
  var dailyExpenses = 0.0.obs;
  var monthlyExpenses = 0.0.obs;
  var allTimeExpenses = 0.0.obs;
  var dailyTotalPayments = 0.0.obs;
  var monthlyTotalPayments = 0.0.obs;
  var allTimeTotalPayments = 0.0.obs;

  // Inventory outputs (deliveries)
  var inventoryOutputs = <Map<String, dynamic>>[].obs;
  var filteredOutputs = <Map<String, dynamic>>[].obs;
  var _allInventoryOutputs = <Map<String, dynamic>>[]; // Store original data

  // Selected date range
  var selectedStartDate = DateTime.now().subtract(Duration(days: 30)).obs;
  var selectedEndDate = DateTime.now().obs;

  @override
  void onInit() async {
    super.onInit();
    await loadDailyData();
  }

  Future<void> loadDailyData() async {
    try {
      isLoading.value = true;

      // Load all invoices and payments
      final invoices = await db.getInvoices();

      final payments = await db.getAllPayments();

      await _calculateDailyPayments(payments);
      await _loadInventoryOutputs();
      await _calculateInvoiceSummary(invoices, payments);
    } catch (e) {
      print('Error loading daily data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  _calculateInvoiceSummary(
    List<Map<String, dynamic>> invoices,
    List<Map<String, dynamic>> payments,
  ) async {
    double totalAmount = 0;
    double paidAmount = 0;

    // Daily calculations
    DateTime today = DateTime.now();
    DateTime todayStart = DateTime(today.year, today.month, today.day);
    DateTime todayEnd = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
    );

    // Monthly calculations
    DateTime monthStart = DateTime(today.year, today.month, 1);
    DateTime monthEnd = today.month == 12
        ? DateTime(today.year + 1, 1, 1).subtract(const Duration(days: 1))
        : DateTime(
            today.year,
            today.month + 1,
            1,
          ).subtract(const Duration(days: 1));

    double dailyInvoices = 0;
    double monthlyInvoices = 0;
    double dailyPaid = 0;
    double monthlyPaid = 0;
    double dailyUnpaid = 0;
    double monthlyUnpaid = 0;

    for (var invoice in invoices) {
      final amount = (invoice['total'] as num?)?.toDouble() ?? 0.0;
      final issuedDate = _parseDate(invoice['issued_at']);

      totalAmount += amount;

      // Check if invoice is daily or monthly
      if (issuedDate != null) {
        if (issuedDate.isAfter(todayStart) && issuedDate.isBefore(todayEnd)) {
          dailyInvoices += amount;
        }
        if (!issuedDate.isBefore(monthStart) && !issuedDate.isAfter(monthEnd)) {
          monthlyInvoices += amount;
        }
      }
    }

    for (var payment in payments) {
      final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
      final paidDate = _parseDate(payment['paid_at'] ?? payment['date']);

      paidAmount += amount;

      // Check if payment is daily or monthly
      if (paidDate != null) {
        if (paidDate.isAfter(todayStart) && paidDate.isBefore(todayEnd)) {
          dailyPaid += amount;
        }
        if (!paidDate.isBefore(monthStart) && !paidDate.isAfter(monthEnd)) {
          monthlyPaid += amount;
        }
      }
    }

    dailyUnpaid = dailyInvoices - dailyPaid;
    monthlyUnpaid = monthlyInvoices - monthlyPaid;

    // Set all values
    totalInvoicesAmount.value = totalAmount;
    totalPaidAmount.value = paidAmount;
    totalUnpaidAmount.value = totalAmount - paidAmount;

    dailyTotalInvoices.value = dailyInvoices;
    monthlyTotalInvoices.value = monthlyInvoices;
    allTimeTotalInvoices.value = totalAmount;
    dailyPaidAmount.value = dailyPaid;
    monthlyPaidAmount.value = monthlyPaid;
    allTimePaidAmount.value = paidAmount;
    dailyUnpaidAmount.value = dailyUnpaid;
    monthlyUnpaidAmount.value = monthlyUnpaid;
    allTimeUnpaidAmount.value = totalAmount - paidAmount;

    // Calculate daily and monthly expenses
    _calculateDailyAndMonthlyExpenses();

    // Calculate daily and monthly total payments
    dailyTotalPayments.value = dailyPaymentsList.fold<double>(0, (
      sum,
      payment,
    ) {
      final paymentDate = payment['date'] as DateTime;
      if (paymentDate.isAfter(todayStart) && paymentDate.isBefore(todayEnd)) {
        return sum + (payment['amount'] as double? ?? 0.0);
      }
      return sum;
    });
    // dailyPaymentsList هون كل الدفعات اليومية، مش بس لليوم، عشان كده بنحسب منهم اللي يخص اليوم والشهر وكل الوقت
    monthlyTotalPayments.value = dailyPaymentsList.fold<double>(0, (
      sum,
      payment,
    ) {
      final paymentDate = payment['date'] as DateTime;
      if (!paymentDate.isBefore(monthStart) && !paymentDate.isAfter(monthEnd)) {
        return sum + (payment['amount'] as double? ?? 0.0);
      }
      return sum;
    });

    allTimeTotalPayments.value = dailyPaymentsList.fold<double>(0, (
      sum,
      payment,
    ) {
      return sum + (payment['amount'] as double? ?? 0.0);
    });

    log('Invoice Summary Calculated: Total=${monthlyTotalPayments.value}, ');
  }

  void _calculateDailyAndMonthlyExpenses() {
    DateTime today = DateTime.now();
    DateTime todayStart = DateTime(today.year, today.month, today.day);
    DateTime todayEnd = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
    );

    DateTime monthStart = DateTime(today.year, today.month, 1);
    DateTime monthEnd = today.month == 12
        ? DateTime(today.year + 1, 1, 1).subtract(const Duration(days: 1))
        : DateTime(
            today.year,
            today.month + 1,
            1,
          ).subtract(const Duration(days: 1));

    double daily = 0;
    double monthly = 0;
    double allTime = 0;

    for (var output in inventoryOutputs) {
      final price = (output['price'] as num?)?.toDouble() ?? 0.0;
      final outputDate = _parseDate(output['date'] ?? output['created_at']);

      allTime += price;

      if (outputDate != null) {
        if (outputDate.isAfter(todayStart) && outputDate.isBefore(todayEnd)) {
          daily += price;
        }
        if (!outputDate.isBefore(monthStart) && !outputDate.isAfter(monthEnd)) {
          monthly += price;
        }
      }
    }

    dailyExpenses.value = daily;
    monthlyExpenses.value = monthly;
    allTimeExpenses.value = allTime;
  }

  _calculateDailyPayments(List<Map<String, dynamic>> payments) async {
    Map<DateTime, double> dailyMap = {};
    List<Map<String, dynamic>> paymentList = [];

    for (var payment in payments) {
      final date = _parseDate(payment['paid_at'] ?? payment['date']);
      if (date != null) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;

        dailyMap[normalizedDate] = (dailyMap[normalizedDate] ?? 0.0) + amount;

        paymentList.add({
          'date': date,
          'amount': amount,
          'patient_id': payment['patient_id'],
          'invoice_id': payment['invoice_id'],
          'payment_method': payment['method'] ?? 'نقدي',
          'notes': payment['note'] ?? '',
        });
      }
    }

    // Sort by date descending
    paymentList.sort((a, b) => (b['date'] as DateTime).compareTo(a['date']));

    dailyPayments.assignAll(dailyMap);
    dailyPaymentsList.assignAll(paymentList);
    _allPaymentsList = List.from(paymentList); // Store original data
  }

  Future<void> _loadInventoryOutputs() async {
    try {
      // Get inventory items that have been used/delivered (outputs)
      final outputs = await db.getInventoryOutputs();
      inventoryOutputs.assignAll(outputs);
      filteredOutputs.assignAll(outputs);
      _allInventoryOutputs = List.from(outputs); // Store original data
    } catch (e) {
      print('Error loading inventory outputs: $e');
    }
  }

  void filterByDateRange(DateTime startDate, DateTime endDate) {
    selectedStartDate.value = startDate;
    selectedEndDate.value = endDate;

    // Filter daily payments by date range from original data
    final filtered = _allPaymentsList.where((payment) {
      final paymentDate = payment['date'] as DateTime;
      return !paymentDate.isBefore(startDate) && !paymentDate.isAfter(endDate);
    }).toList();

    dailyPaymentsList.assignAll(filtered);

    // Filter inventory outputs from original data
    final filteredInvOutputs = _allInventoryOutputs.where((output) {
      final outputDate = _parseDate(output['date'] ?? output['created_at']);
      if (outputDate == null) return false;
      return !outputDate.isBefore(startDate) && !outputDate.isAfter(endDate);
    }).toList();

    filteredOutputs.assignAll(filteredInvOutputs);
  }

  void filterOutputsByName(String query) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      filteredOutputs.assignAll(inventoryOutputs);
    } else {
      filteredOutputs.assignAll(
        inventoryOutputs.where((output) {
          final name = (output['item_name'] ?? '').toString().toLowerCase();
          return name.contains(q);
        }).toList(),
      );
    }
  }

  Future<void> finalizeInventory() async {
    try {
      isLoading.value = true;
      // Clear outputs after finalization
      await db.clearInventoryOutputs();
      inventoryOutputs.clear();
      filteredOutputs.clear();
    } catch (e) {
      print('Error finalizing inventory: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addInventoryOutput(Map<String, dynamic> data) async {
    try {
      await db.addInventoryOutput(data);
      await _loadInventoryOutputs();
      _calculateDailyAndMonthlyExpenses();
    } catch (e) {
      print('Error adding inventory output: $e');
    }
  }

  Future<void> removeInventoryOutput(String id) async {
    try {
      await db.deleteInventoryOutput(id);
      await _loadInventoryOutputs();
      _calculateDailyAndMonthlyExpenses();
    } catch (e) {
      print('Error removing inventory output: $e');
    }
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    if (dateValue is DateTime) return dateValue;

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // Public version for widgets
  DateTime? parseDate(dynamic dateValue) => _parseDate(dateValue);

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd', 'ar_SA').format(date);
  }

  String formatDateWithTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm', 'ar_SA').format(date);
  }

  double getDailyPaymentTotal(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return dailyPayments[normalizedDate] ?? 0.0;
  }

  int getTotalOutputCount() => inventoryOutputs.length;

  /// احصل على ملخص اليوم - الدخل والخرج
  /// Get today's summary - income and expenses
  Future getTodaySummary() async {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // احسب الدفعات لليوم
    double todayIncome = 0.0;
    int todayPaymentsCount = 0;

    for (var payment in dailyPaymentsList) {
      final paymentDate = payment['date'] as DateTime;
      final normalizedPaymentDate = DateTime(
        paymentDate.year,
        paymentDate.month,
        paymentDate.day,
      );
      if (normalizedPaymentDate == normalizedToday) {
        todayIncome += (payment['amount'] as double);
        todayPaymentsCount++;
      }
    }

    // احسب المخرجات لليوم
    double todayExpense = 0.0;
    int todayOutputsCount = 0;

    for (var output in inventoryOutputs) {
      final outputDate = parseDate(output['date'] ?? output['created_at']);
      if (outputDate != null) {
        final normalizedOutputDate = DateTime(
          outputDate.year,
          outputDate.month,
          outputDate.day,
        );
        if (normalizedOutputDate == normalizedToday) {
          // احسب قيمة المخرج بناءً على الكمية (إن وجدت سعر)
          final quantity = (output['quantity'] as num?)?.toDouble() ?? 0.0;
          todayExpense += quantity;
          todayOutputsCount++;
        }
      }
    }

    todaySummary.value = {
      'date': DateFormat('EEEE, d MMMM yyyy', 'ar_SA').format(today),
      'income': todayIncome,
      'expense': todayExpense,
      'balance': todayIncome - todayExpense,
      'paymentsCount': todayPaymentsCount,
      'outputsCount': todayOutputsCount,
    };
  }

  /// احصل على الدفعات لليوم فقط
  /// Get today's payments only
  List<Map<String, dynamic>> getTodayPayments() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    return dailyPaymentsList.where((payment) {
      final paymentDate = payment['date'] as DateTime;
      final normalizedPaymentDate = DateTime(
        paymentDate.year,
        paymentDate.month,
        paymentDate.day,
      );
      return normalizedPaymentDate == normalizedToday;
    }).toList();
  }

  /// احصل على المخرجات لليوم فقط
  /// Get today's outputs only
  List<Map<String, dynamic>> getTodayOutputs() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    return inventoryOutputs.where((output) {
      final outputDate = parseDate(output['date'] ?? output['created_at']);
      if (outputDate == null) return false;
      final normalizedOutputDate = DateTime(
        outputDate.year,
        outputDate.month,
        outputDate.day,
      );
      return normalizedOutputDate == normalizedToday;
    }).toList();
  }

  /// احصل على مجموع الدفعات لليوم
  /// Get total income for today
  double getTodayIncome() {
    return getTodayPayments().fold<double>(
      0.0,
      (sum, payment) => sum + (payment['amount'] as double),
    );
  }

  /// احصل على مجموع المخرجات لليوم (بالكمية)
  /// Get total outputs for today
  double getTodayExpense() {
    return getTodayOutputs().fold<double>(
      0.0,
      (sum, output) => sum + ((output['quantity'] as num?)?.toDouble() ?? 0.0),
    );
  }
}
