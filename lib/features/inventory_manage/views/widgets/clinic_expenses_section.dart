import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/colors.dart';
import '../../controller/daily_inventory_controller.dart';
import '../../utils/clinic_expense_categories.dart';
import '../../utils/money_format.dart';
import 'daily_empty_state.dart';

class ClinicExpensesSection extends StatelessWidget {
  const ClinicExpensesSection({super.key, required this.controller});

  final DailyInventoryController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'نفقات التشغيل',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: controller.showAddClinicExpenseDialog,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text('إضافة نفقة', style: GoogleFonts.poppins()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'اختر النوع عند الإضافة — ثم فلتر حسب النوع من الشرائح أدناه (لا حاجة لتمييز يدوي).',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        _CategoryFilterStrip(controller: controller),
        const SizedBox(height: 16),
        Obx(() {
          final filter = controller.clinicExpenseCategoryFilter.value;
          final expenses = controller.filteredClinicExpenses;
          final visible = filter == null
              ? expenses
              : expenses
                  .where(
                    (e) =>
                        ClinicExpenseCategory.byId(
                          e['category']?.toString(),
                        ).id ==
                        filter,
                  )
                  .toList();

          if (visible.isEmpty) {
            return DailyEmptyState(
              message: filter == null
                  ? 'لا توجد نفقات في الفترة المحددة'
                  : 'لا توجد نفقات من هذا النوع في الفترة',
              icon: Icons.receipt_long_outlined,
            );
          }

          if (filter != null) {
            return _ExpenseList(
              controller: controller,
              expenses: visible,
            );
          }

          return _GroupedExpenseList(
            controller: controller,
            expenses: expenses,
          );
        }),
      ],
    );
  }
}

class _CategoryFilterStrip extends StatelessWidget {
  const _CategoryFilterStrip({required this.controller});

  final DailyInventoryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.clinicExpenseCategoryFilter.value;
      final expenses = controller.filteredClinicExpenses;
      final totalAll = expenses.fold<double>(
        0,
        (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0),
      );

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _filterChip(
            label: 'الكل',
            amount: totalAll,
            selected: selected == null,
            onTap: () => controller.setClinicExpenseCategoryFilter(null),
          ),
          ...ClinicExpenseCategory.all.map((cat) {
            final amount = controller.categoryExpenseTotal(cat.id);
            if (amount <= 0 && selected != cat.id) {
              return const SizedBox.shrink();
            }
            return _filterChip(
              label: cat.label,
              amount: amount,
              selected: selected == cat.id,
              icon: _categoryIcon(cat.id),
              onTap: () => controller.setClinicExpenseCategoryFilter(cat.id),
            );
          }),
        ],
      );
    });
  }

  Widget _filterChip({
    required String label,
    required double amount,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return FilterChip(
      avatar: icon != null
          ? Icon(icon, size: 16, color: selected ? Colors.white : AppColors.mainColor)
          : null,
      label: Text(
        amount > 0 ? '$label · ${formatMoneyCompact(amount)}' : label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? Colors.white : AppColors.mainColor,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.mainColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected
            ? AppColors.mainColor
            : AppColors.mainColor.withValues(alpha: 0.25),
      ),
    );
  }
}

class _GroupedExpenseList extends StatelessWidget {
  const _GroupedExpenseList({
    required this.controller,
    required this.expenses,
  });

  final DailyInventoryController controller;
  final List<Map<String, dynamic>> expenses;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final expense in expenses) {
      final catId =
          ClinicExpenseCategory.byId(expense['category']?.toString()).id;
      grouped.putIfAbsent(catId, () => []).add(expense);
    }

    final orderedIds = ClinicExpenseCategory.all
        .map((c) => c.id)
        .where(grouped.containsKey)
        .toList();

    return Column(
      children: orderedIds.map((catId) {
        final cat = ClinicExpenseCategory.byId(catId);
        final items = grouped[catId]!;
        final subtotal = items.fold<double>(
          0,
          (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8, top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(_categoryIcon(cat.id), size: 18, color: AppColors.mainColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cat.label,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ),
                  Text(
                    formatMoney(subtotal),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.mainColor,
                    ),
                  ),
                ],
              ),
            ),
            _ExpenseList(controller: controller, expenses: items),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({
    required this.controller,
    required this.expenses,
  });

  final DailyInventoryController controller;
  final List<Map<String, dynamic>> expenses;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final id = expense['id']?.toString() ?? '';
        final category = ClinicExpenseCategory.byId(
          expense['category']?.toString(),
        );
        final description = expense['description']?.toString() ?? 'غير محدد';
        final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
        final note = expense['note']?.toString() ?? '';
        final date = controller.parseDate(
          expense['expense_date'] ?? expense['created_at'],
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _categoryIcon(category.id),
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category.label,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date != null
                          ? DateFormat('dd/MM/yyyy', 'ar').format(date)
                          : 'تاريخ غير محدد',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(amount),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  IconButton(
                    tooltip: 'حذف',
                    onPressed: id.isEmpty
                        ? null
                        : () => controller.confirmDeleteClinicExpense(
                              id,
                              description,
                            ),
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.cancelledColor,
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

IconData _categoryIcon(String categoryId) {
  switch (ClinicExpenseCategory.byId(categoryId).id) {
    case 'laboratories':
      return Icons.biotech_outlined;
    case 'dental_materials':
      return Icons.medical_services_outlined;
    case 'consumables':
      return Icons.inventory_2_outlined;
    case 'worker_salaries':
      return Icons.payments_outlined;
    case 'cleaning':
      return Icons.cleaning_services_outlined;
    default:
      return Icons.receipt_long_outlined;
  }
}
