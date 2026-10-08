import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../../../services/database_service.dart';
import '../models/daily_financial_summary.dart';
import '../models/daily_inventory_tab.dart';
import '../utils/clinic_expense_categories.dart';
import '../utils/daily_inventory_calculations.dart';
import '../utils/daily_inventory_date.dart';
import '../views/widgets/clinic_expense_dialog.dart';
import '../views/widgets/inventory_output_dialog.dart';
import 'clinic_expense_dialog_controller.dart';
import 'inventory_output_dialog_controller.dart';

class DailyInventoryController extends GetxController {
  final db = DatabaseService.instance;

  final isLoading = false.obs;
  final selectedTab = DailyInventoryTab.outputs.obs;
  final isFilterActive = false.obs;
  final showSummaryDetails = false.obs;

  final dailyPaymentsList = <Map<String, dynamic>>[].obs;
  final filteredOutputs = <Map<String, dynamic>>[].obs;
  final inventoryOutputs = <Map<String, dynamic>>[].obs;
  final clinicExpenses = <Map<String, dynamic>>[].obs;
  final filteredClinicExpenses = <Map<String, dynamic>>[].obs;
  /// null = عرض الكل
  final clinicExpenseCategoryFilter = RxnString();

  final periodFilterSummary = DailyPeriodFilterSummary.empty.obs;
  final financialReport = Rxn<DailyFinancialReport>();
  final selectedHistoryMonth = Rxn<DateTime>();
  final historyMonths = <DateTime>[].obs;

  final selectedStartDate =
      DateTime.now().subtract(const Duration(days: 30)).obs;
  final selectedEndDate = DateTime.now().obs;

  List<Map<String, dynamic>> _allPaymentsList = [];
  List<Map<String, dynamic>> _allInventoryOutputs = [];
  List<Map<String, dynamic>> _allClinicExpenses = [];
  List<Map<String, dynamic>> _rawInvoices = [];
  List<Map<String, dynamic>> _rawPayments = [];

  DailyFinancialSummary get daily => financialReport.value?.daily ?? DailyFinancialSummary.zero;
  DailyFinancialSummary get monthly =>
      financialReport.value?.monthly ?? DailyFinancialSummary.zero;
  DailyFinancialSummary get allTime =>
      financialReport.value?.allTime ?? DailyFinancialSummary.zero;

  DailyFinancialSummary get displayedMonthSummary {
    final selected = selectedHistoryMonth.value;
    if (selected == null) return monthly;
    return computeSummaryForMonth(
      invoices: _rawInvoices,
      payments: _rawPayments,
      outputs: _allInventoryOutputs,
      clinicExpenses: _allClinicExpenses,
      month: selected,
    );
  }

  Map<String, double> get displayedMonthExpenseBreakdown {
    final selected = selectedHistoryMonth.value ?? DateTime.now();
    return sumClinicExpensesByCategory(
      _allClinicExpenses,
      whereDate: (date) => isSameMonth(date, startOfMonth(selected)),
    );
  }

  double get displayedMonthInventoryOutputExpenses {
    final selected = selectedHistoryMonth.value ?? DateTime.now();
    return sumOutputExpenses(
      _allInventoryOutputs,
      whereDate: (date) => isSameMonth(date, startOfMonth(selected)),
    );
  }

  String get displayedMonthLabel {
    final selected = selectedHistoryMonth.value;
    if (selected == null) return 'شهري';
    return formatMonthLabel(selected);
  }

  @override
  void onInit() {
    super.onInit();
    loadDailyData();
  }

  Future<void> loadDailyData() async {
    try {
      isLoading.value = true;
      _rawInvoices = await db.getInvoices();
      _rawPayments = await db.getAllPayments();
      _allPaymentsList = normalizePayments(_rawPayments);
      await Future.wait([_loadInventoryOutputs(), _loadClinicExpenses()]);
      _recalculateSummaries();
      _refreshHistoryMonths();
      _resetListsToAll();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() => loadDailyData();

  void _recalculateSummaries() {
    financialReport.value = computeFinancialReport(
      invoices: _rawInvoices,
      payments: _rawPayments,
      outputs: _allInventoryOutputs,
      clinicExpenses: _allClinicExpenses,
    );
  }

  Future<void> _loadInventoryOutputs() async {
    final outputs = await db.getInventoryOutputs();
    inventoryOutputs.assignAll(outputs);
    _allInventoryOutputs = List.from(outputs);
    filteredOutputs.assignAll(outputs);
  }

  Future<void> _loadClinicExpenses() async {
    final expenses = await db.getClinicExpenses();
    clinicExpenses.assignAll(expenses);
    _allClinicExpenses = List.from(expenses);
    filteredClinicExpenses.assignAll(expenses);
  }

  void _refreshHistoryMonths() {
    historyMonths.assignAll(
      collectAvailableHistoryMonths(
        invoices: _rawInvoices,
        payments: _rawPayments,
        outputs: _allInventoryOutputs,
        clinicExpenses: _allClinicExpenses,
      ),
    );
  }

  void selectHistoryMonth(DateTime month) {
    final monthStart = startOfMonth(month);
    selectedHistoryMonth.value = monthStart;
    selectedStartDate.value = monthStart;
    selectedEndDate.value = endOfMonth(monthStart);
    _applyCurrentFilter();
  }

  void toggleSummaryDetails() =>
      showSummaryDetails.value = !showSummaryDetails.value;

  void applyDateFilter() {
    final range = normalizeRange(
      selectedStartDate.value,
      selectedEndDate.value,
    );
    selectedStartDate.value = range.$1;
    selectedEndDate.value = range.$2;
    _syncSelectedHistoryMonth();
    _applyCurrentFilter();
  }

  void resetDateFilter() {
    selectedStartDate.value =
        DateTime.now().subtract(const Duration(days: 30));
    selectedEndDate.value = DateTime.now();
    selectedHistoryMonth.value = null;
    isFilterActive.value = false;
    _resetListsToAll();
  }

  void _syncSelectedHistoryMonth() {
    final range = normalizeRange(
      selectedStartDate.value,
      selectedEndDate.value,
    );
    final monthStart = startOfMonth(range.$1);
    final monthEnd = endOfMonth(monthStart);
    if (isSameDay(range.$1, monthStart) && isSameDay(range.$2, monthEnd)) {
      selectedHistoryMonth.value = monthStart;
    } else {
      selectedHistoryMonth.value = null;
    }
  }

  void _resetListsToAll() {
    dailyPaymentsList.assignAll(_allPaymentsList);
    filteredOutputs.assignAll(_allInventoryOutputs);
    filteredClinicExpenses.assignAll(_allClinicExpenses);
    periodFilterSummary.value = DailyPeriodFilterSummary.empty;
  }

  void _applyCurrentFilter({bool silent = false}) {
    if (!silent) {
      isFilterActive.value = true;
    }

    dailyPaymentsList.assignAll(
      filterByDateRange(
        items: _allPaymentsList,
        start: selectedStartDate.value,
        end: selectedEndDate.value,
        dateSelector: (item) => item['date'] as DateTime?,
      ),
    );

    filteredOutputs.assignAll(
      filterByDateRange(
        items: _allInventoryOutputs,
        start: selectedStartDate.value,
        end: selectedEndDate.value,
        dateSelector: (item) =>
            parseRecordDate(item['date'] ?? item['created_at']),
      ),
    );

    filteredClinicExpenses.assignAll(
      filterByDateRange(
        items: _allClinicExpenses,
        start: selectedStartDate.value,
        end: selectedEndDate.value,
        dateSelector: (item) =>
            parseRecordDate(item['expense_date'] ?? item['created_at']),
      ),
    );

    periodFilterSummary.value = computePeriodFilterSummary(
      payments: _allPaymentsList,
      outputs: _allInventoryOutputs,
      clinicExpenses: _allClinicExpenses,
      start: selectedStartDate.value,
      end: selectedEndDate.value,
    );
  }

  Future<void> finalizeInventory() async {
    try {
      isLoading.value = true;
      await db.clearInventoryOutputs();
      inventoryOutputs.clear();
      filteredOutputs.clear();
      _allInventoryOutputs = [];
      _recalculateSummaries();
      _refreshFilteredLists();
    } finally {
      isLoading.value = false;
    }
  }

  void _refreshFilteredLists() {
    if (isFilterActive.value) {
      _applyCurrentFilter();
    } else {
      _resetListsToAll();
    }
  }

  void showAddOutputDialog() {
    final tag = InventoryOutputDialogController.dialogTag;
    if (Get.isRegistered<InventoryOutputDialogController>(tag: tag)) {
      Get.delete<InventoryOutputDialogController>(tag: tag);
    }

    final dialogController = Get.put(
      InventoryOutputDialogController(this),
      tag: tag,
    );

    final context = Get.context;
    if (context == null) {
      Get.delete<InventoryOutputDialogController>(tag: tag);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InventoryOutputDialog(
        dialogController: dialogController,
      ),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<InventoryOutputDialogController>(tag: tag)) {
          Get.delete<InventoryOutputDialogController>(tag: tag);
        }
      });
    });
  }

  Future<void> showFinalizeDialog() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'الجرد النهائي',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'هل أنت متأكد؟ سيتم حذف جميع المخرجات المسجلة وإعادة حساب النفقات.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('إلغاء', style: GoogleFonts.poppins()),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('تأكيد', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await finalizeInventory();
    }
  }

  Future<void> confirmDeleteOutput(String id, String itemName) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('حذف المخرج؟', style: GoogleFonts.poppins()),
        content: Text(
          'هل تريد حذف "$itemName" من سجل المخرجات؟',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('إلغاء', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'حذف',
              style: GoogleFonts.poppins(color: AppColors.cancelledColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await removeInventoryOutput(id);
    }
  }

  Future<void> addInventoryOutput(Map<String, dynamic> data) async {
    await db.addInventoryOutput(data);
    await _loadInventoryOutputs();
    _recalculateSummaries();
    _refreshFilteredLists();
  }

  Future<void> removeInventoryOutput(String id) async {
    await db.deleteInventoryOutput(id);
    await _loadInventoryOutputs();
    _recalculateSummaries();
    _refreshFilteredLists();
  }

  void showAddClinicExpenseDialog() {
    final tag = ClinicExpenseDialogController.dialogTag;
    if (Get.isRegistered<ClinicExpenseDialogController>(tag: tag)) {
      Get.delete<ClinicExpenseDialogController>(tag: tag);
    }

    final dialogController = Get.put(
      ClinicExpenseDialogController(this),
      tag: tag,
    );

    final context = Get.context;
    if (context == null) {
      Get.delete<ClinicExpenseDialogController>(tag: tag);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ClinicExpenseDialog(dialogController: dialogController),
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<ClinicExpenseDialogController>(tag: tag)) {
          Get.delete<ClinicExpenseDialogController>(tag: tag);
        }
      });
    });
  }

  Future<void> addClinicExpense(Map<String, dynamic> data) async {
    await db.addClinicExpense(data);
    await _loadClinicExpenses();
    _recalculateSummaries();
    _refreshHistoryMonths();
    _refreshFilteredLists();
  }

  Future<void> confirmDeleteClinicExpense(String id, String description) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('حذف النفقة؟', style: GoogleFonts.poppins()),
        content: Text(
          'هل تريد حذف "$description"؟',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('إلغاء', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'حذف',
              style: GoogleFonts.poppins(color: AppColors.cancelledColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await removeClinicExpense(id);
    }
  }

  Future<void> removeClinicExpense(String id) async {
    await db.deleteClinicExpense(id);
    await _loadClinicExpenses();
    _recalculateSummaries();
    _refreshHistoryMonths();
    _refreshFilteredLists();
  }

  DateTime? parseDate(dynamic dateValue) => parseRecordDate(dateValue);

  List<Map<String, dynamic>> get visibleClinicExpenses {
    final filter = clinicExpenseCategoryFilter.value;
    if (filter == null) return filteredClinicExpenses;
    return filteredClinicExpenses
        .where(
          (e) =>
              ClinicExpenseCategory.byId(e['category']?.toString()).id ==
              filter,
        )
        .toList();
  }

  double categoryExpenseTotal(String categoryId) {
    var total = 0.0;
    for (final expense in filteredClinicExpenses) {
      if (ClinicExpenseCategory.byId(expense['category']?.toString()).id !=
          categoryId) {
        continue;
      }
      total += (expense['amount'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  void setClinicExpenseCategoryFilter(String? categoryId) {
    clinicExpenseCategoryFilter.value = categoryId;
  }
}
