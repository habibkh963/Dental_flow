import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/colors.dart';
import '../controller/daily_inventory_controller.dart';

class DailyInventoryPage extends StatelessWidget {
  DailyInventoryPage({super.key});

  final DailyInventoryController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    controller.loadDailyData();
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.mainColor),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              _buildSummaryCards(),
              const SizedBox(height: 30),

              // Date Range Selector
              _buildDateRangeSelector(context),
              const SizedBox(height: 30),

              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      controller.isIncomes.value = false;
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(5),
                      ),
                      backgroundColor: !controller.isIncomes.value
                          ? AppColors.mainColor
                          : Colors.white,
                    ),
                    child: Text(
                      ' المخرجات ',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: !controller.isIncomes.value
                            ? Colors.white
                            : AppColors.approvedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 20.h),
                  ElevatedButton(
                    onPressed: () {
                      controller.isIncomes.value = true;
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(5),
                      ),
                      backgroundColor: controller.isIncomes.value
                          ? AppColors.mainColor
                          : Colors.white,
                    ),
                    child: Text(
                      'المدفوعات',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: controller.isIncomes.value
                            ? Colors.white
                            : AppColors.approvedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Obx(
                () => controller.isIncomes.value
                    ? _buildDailyPaymentsSection()
                    : _buildInventoryOutputsSection(context),
              ),

              // Daily Payments Section

              // Inventory Outputs Section
              const SizedBox(height: 30),

              // Profit Summary Section
              // _buildProfitSummary(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        // Total Invoices
        Obx(
          () => _SummaryCard(
            title: 'إجمالي الفواتير للمرضى',
            dailyValue:
                '${controller.dailyTotalInvoices.value.toStringAsFixed(2)} ل.س',
            monthlyValue:
                '${controller.monthlyTotalInvoices.value.toStringAsFixed(2)} ل.س',
            allTimeValue:
                '${controller.allTimeTotalInvoices.value.toStringAsFixed(2)} ل.س',
            icon: Icons.receipt,
            color: Colors.blue,
            subtitle: 'يومي / شهري / الكل',
          ),
        ),
        // Paid Amounts
        Obx(
          () => _SummaryCard(
            title: 'المبالغ المدفوعة',
            dailyValue:
                '${controller.dailyPaidAmount.value.toStringAsFixed(2)} ل.س',
            monthlyValue:
                '${controller.monthlyPaidAmount.value.toStringAsFixed(2)} ل.س',
            allTimeValue:
                '${controller.allTimePaidAmount.value.toStringAsFixed(2)} ل.س',
            icon: Icons.check_circle,
            color: Colors.green,
            subtitle: 'يومي / شهري / الكل',
          ),
        ),
        // Unpaid Amounts
        Obx(
          () => _SummaryCard(
            title: 'المبالغ المتبقية',
            dailyValue:
                '${controller.dailyUnpaidAmount.value.toStringAsFixed(2)} ل.س',
            monthlyValue:
                '${controller.monthlyUnpaidAmount.value.toStringAsFixed(2)} ل.س',
            allTimeValue:
                '${controller.allTimeUnpaidAmount.value.toStringAsFixed(2)} ل.س',
            icon: Icons.pending,
            color: Colors.orange,
            subtitle: 'يومي / شهري / الكل',
          ),
        ),
        // Clinic Expenses
        Obx(
          () => _SummaryCard(
            title: 'نفقات العيادة',
            dailyValue:
                '${controller.dailyExpenses.value.toStringAsFixed(2)} ل.س',
            monthlyValue:
                '${controller.monthlyExpenses.value.toStringAsFixed(2)} ل.س',
            allTimeValue:
                '${controller.allTimeExpenses.value.toStringAsFixed(2)} ل.س',
            icon: Icons.shopping_cart,
            color: Colors.red,
            subtitle: 'يومي / شهري / الكل',
          ),
        ),
        // Daily Payments Summary
        Obx(
          () => _SummaryCard(
            title: 'إجمالي المدفوعات',
            dailyValue:
                '${controller.dailyTotalPayments.value.toStringAsFixed(2)} ل.س',
            monthlyValue:
                '${controller.monthlyTotalPayments.value.toStringAsFixed(2)} ل.س',
            allTimeValue:
                '${controller.allTimeTotalPayments.value.toStringAsFixed(2)} ل.س',
            icon: Icons.wallet,
            color: Colors.purple,
            subtitle: 'يومي / شهري / الكل',
          ),
        ),
        // Net Profit
        Obx(() {
          final dailyProfit =
              (controller.dailyTotalPayments.value -
              controller.dailyExpenses.value);
          final monthlyProfit =
              (controller.monthlyTotalPayments.value -
              controller.monthlyExpenses.value);
          final allTimeProfit =
              (controller.allTimeTotalPayments.value -
              controller.allTimeExpenses.value);
          return _SummaryCard(
            title: 'صافي الربح',
            dailyValue: '${dailyProfit.toStringAsFixed(2)} ل.س',
            monthlyValue: '${monthlyProfit.toStringAsFixed(2)} ل.س',
            allTimeValue: '${allTimeProfit.toStringAsFixed(2)} ل.س',
            icon: Icons.trending_up,
            color: dailyProfit >= 0 ? Colors.teal : Colors.red,
            subtitle: 'يومي / شهري / الكل',
          );
        }),
      ],
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _DateButton(
              label: 'من التاريخ',
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: controller.selectedStartDate.value,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  controller.selectedStartDate.value = date;
                }
              },
              date: controller.selectedStartDate.value,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _DateButton(
              label: 'إلى التاريخ',
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: controller.selectedEndDate.value,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  controller.selectedEndDate.value = date;
                }
              },
              date: controller.selectedEndDate.value,
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () {
              controller.filterByDateRange(
                controller.selectedStartDate.value,
                controller.selectedEndDate.value,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.filter_list),
            label: Text('تصفية', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPaymentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Obx(() {
          if (controller.dailyPaymentsList.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  'لا توجد دفعات في الفترة المحددة',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.dailyPaymentsList.length,
            itemBuilder: (context, index) {
              final payment = controller.dailyPaymentsList[index];
              final date = payment['date'] as DateTime;
              final amount = payment['amount'] as double;
              final method = payment['payment_method'] ?? 'نقدي';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.mainColor.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.payment, color: AppColors.mainColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'EEEE, d MMMM yyyy',
                              'ar_SA',
                            ).format(date),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'طريقة الدفع: $method',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${amount.toStringAsFixed(2)} ل.س',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildInventoryOutputsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'المخرجات (المواد المستخدمة)',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showAddOutputDialog(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mainColor,
              ),
              icon: const Icon(Icons.add),
              label: Text(
                'إضافة مخرج',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              if (controller.inventoryOutputs.isNotEmpty) {
                return FilledButton.icon(
                  onPressed: () => _showFinalizeDialog(context),
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                  icon: const Icon(Icons.check),
                  label: Text(
                    'الجرد النهائي',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.filteredOutputs.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  'لا توجد مخرجات في الفترة المحددة',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.filteredOutputs.length,
            itemBuilder: (context, index) {
              final output = controller.filteredOutputs[index];
              final itemName = output['item_name'] ?? 'غير محدد';
              final quantity = (output['quantity'] as num?)?.toDouble() ?? 0.0;
              final unit = output['unit'] ?? 'وحدة';
              final price = (output['price'] as num?)?.toDouble() ?? 0.0;
              final date = controller.parseDate(
                output['date'] ?? output['created_at'],
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory, color: Colors.red),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date != null
                                ? DateFormat('dd/MM/yyyy', 'ar_SA').format(date)
                                : 'تاريخ غير محدد',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'الكمية: $quantity $unit',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'السعر: ${price.toStringAsFixed(2)} ل.س',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${price.toStringAsFixed(2)} ل.س',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            controller.removeInventoryOutput(output['id']);
                          },
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  // Widget _buildProfitSummary() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'ملخص الأرباح والنفقات',
  //         style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
  //       ),
  //       const SizedBox(height: 16),
  //       Container(
  //         padding: const EdgeInsets.all(20),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(12),
  //           boxShadow: [
  //             BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8),
  //           ],
  //         ),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Obx(() {
  //               final totalInvoices = controller.totalInvoicesAmount.value;
  //               final totalExpenses = controller.inventoryOutputs.fold<double>(
  //                 0,
  //                 (sum, output) {
  //                   final price = (output['price'] as num?)?.toDouble() ?? 0.0;
  //                   return sum + price;
  //                 },
  //               );
  //               final profit = totalInvoices - totalExpenses;

  //               return Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         'إجمالي الفواتير (الدخل)',
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 14,
  //                           color: Colors.grey[600],
  //                         ),
  //                       ),
  //                       Text(
  //                         '${totalInvoices.toStringAsFixed(2)} ل.س',
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.green,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 12),
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         'إجمالي النفقات (المخرجات)',
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 14,
  //                           color: Colors.grey[600],
  //                         ),
  //                       ),
  //                       Text(
  //                         '${totalExpenses.toStringAsFixed(2)} ل.س',
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.red,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const Divider(height: 20),
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         'صافي الربح',
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.w700,
  //                         ),
  //                       ),
  //                       Text(
  //                         '${profit.toStringAsFixed(2)} ل.س',
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.w700,
  //                           color: profit >= 0 ? Colors.green : Colors.red,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               );
  //             }),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  void _showFinalizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'الجرد النهائي',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في تنفيذ الجرد النهائي؟ سيتم حذف جميع المخرجات المسجلة.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          FilledButton(
            onPressed: () {
              controller.finalizeInventory();
              Navigator.pop(context);
              Get.snackbar(
                'نجح',
                'تم تنفيذ الجرد النهائي بنجاح',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('تأكيد', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showAddOutputDialog(BuildContext context) {
    final TextEditingController itemNameController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController unitController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'إضافة مخرج جديد',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 700.w),
              TextField(
                controller: itemNameController,
                decoration: InputDecoration(
                  labelText: 'اسم المادة / الفاتورة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'الكمية',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: InputDecoration(
                  labelText: 'الوحدة (مثل: كيس، علبة، إلخ)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'السعر (ل.س)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'إلغاء',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          FilledButton(
            onPressed: () {
              final itemName = itemNameController.text.trim();
              final quantity = double.tryParse(quantityController.text) ?? 0;
              final unit = unitController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0;

              if (itemName.isEmpty ||
                  quantity <= 0 ||
                  unit.isEmpty ||
                  price <= 0) {
                Get.snackbar(
                  'خطأ',
                  'يرجى ملء جميع الحقول بشكل صحيح',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              controller.addInventoryOutput({
                'item_name': itemName,
                'quantity': quantity,
                'unit': unit,
                'price': price,
                'date': DateTime.now().toString(),
              });

              Navigator.pop(context);
              Get.snackbar(
                'نجح',
                'تم إضافة المخرج بنجاح',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.mainColor),
            child: Text('إضافة', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String? value;
  final String? dailyValue;
  final String? monthlyValue;
  final String? allTimeValue;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _SummaryCard({
    required this.title,
    this.value,
    this.dailyValue,
    this.monthlyValue,
    this.allTimeValue,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (value != null)
            Text(
              value!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          if (dailyValue != null && monthlyValue != null && allTimeValue != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'يومي:',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      dailyValue!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'شهري:',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      monthlyValue!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الكل:',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      allTimeValue!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final DateTime date;

  const _DateButton({
    required this.label,
    required this.onPressed,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
          ),
          Text(
            DateFormat('dd/MM/yyyy', 'ar_SA').format(date),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
