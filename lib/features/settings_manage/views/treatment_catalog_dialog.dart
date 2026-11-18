import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../../../core/currency_utils.dart';
import '../../../core/models/treatment_catalog_item.dart';
import '../../shared/widgets/amount_with_currency_field.dart';
import '../../shared/widgets/app_dialog_shell.dart';
import '../controllers/app_currency_controller.dart';
import '../controllers/treatment_catalog_controller.dart';

Future<void> openTreatmentCatalogDialog() async {
  if (!Get.isRegistered<TreatmentCatalogController>()) {
    Get.put(TreatmentCatalogController(), permanent: true);
  }
  final catalog = Get.find<TreatmentCatalogController>();
  await catalog.reload();

  await Get.dialog(
    const _TreatmentCatalogDialogBody(),
    barrierColor: Colors.black.withValues(alpha: 0.35),
  );
}

class _TreatmentCatalogDialogBody extends StatefulWidget {
  const _TreatmentCatalogDialogBody();

  @override
  State<_TreatmentCatalogDialogBody> createState() =>
      _TreatmentCatalogDialogBodyState();
}

class _TreatmentCatalogDialogBodyState
    extends State<_TreatmentCatalogDialogBody> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  late String addCurrency;

  @override
  void initState() {
    super.initState();
    final code = Get.isRegistered<AppCurrencyController>()
        ? Get.find<AppCurrencyController>().code.value
        : 'SYP';
    addCurrency = kInputCurrencyCodes.contains(code) ? code : 'SYP';
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = Get.find<TreatmentCatalogController>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: AppDialogFrame(
        title: 'خطط العلاج والأسعار',
        subtitle:
            'أدخل الأسعار يدوياً — تُستخدم في الفواتير. الحالات الطبية منفصلة.',
        width: 560,
        maxHeight: 640,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'اسم خطة العلاج / التمثيل',
                hintStyle: GoogleFonts.poppins(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AmountWithCurrencyField(
              amountController: priceController,
              selectedCurrencyCode: addCurrency,
              onCurrencyChanged: (c) => setState(() => addCurrency = c),
              label: 'السعر',
              style: AmountFieldStyle.billing,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final price =
                      double.tryParse(priceController.text.trim()) ?? 0;
                  if (name.isEmpty) return;
                  await catalog.addItem(name: name, price: price);
                  nameController.clear();
                  priceController.clear();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                ),
                icon: const Icon(Icons.add),
                label: Text('إضافة خطة', style: GoogleFonts.poppins()),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 340,
              child: Obx(() {
                if (catalog.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (catalog.items.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد خطط — أضف الاسم والسعر أعلاه',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: catalog.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = catalog.items[index];
                    return _CatalogRow(
                      item: item,
                      onSave: (name, price) =>
                          catalog.updateItem(item.id, name: name, price: price),
                      onDelete: () => catalog.removeItem(item.id),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('إغلاق', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}

class _CatalogRow extends StatefulWidget {
  const _CatalogRow({
    required this.item,
    required this.onSave,
    required this.onDelete,
  });

  final TreatmentCatalogItem item;
  final Future<void> Function(String name, double price) onSave;
  final VoidCallback onDelete;

  @override
  State<_CatalogRow> createState() => _CatalogRowState();
}

class _CatalogRowState extends State<_CatalogRow> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _price = TextEditingController(
      text: widget.item.price > 0
          ? widget.item.price.toStringAsFixed(0)
          : '',
    );
    final code = Get.isRegistered<AppCurrencyController>()
        ? Get.find<AppCurrencyController>().code.value
        : 'SYP';
    _currency = kInputCurrencyCodes.contains(code) ? code : 'SYP';
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'اسم الخطة',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          AmountWithCurrencyField(
            amountController: _price,
            selectedCurrencyCode: _currency,
            onCurrencyChanged: (c) => setState(() => _currency = c),
            label: 'السعر',
            style: AmountFieldStyle.billing,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'حفظ',
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.mainColor,
                ),
                onPressed: () async {
                  final price = double.tryParse(_price.text.trim()) ?? 0;
                  await widget.onSave(_name.text, price);
                },
              ),
              IconButton(
                tooltip: 'حذف',
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.cancelledColor,
                ),
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}