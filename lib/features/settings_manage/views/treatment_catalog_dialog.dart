import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../../../core/models/treatment_catalog_item.dart';
import '../controllers/treatment_catalog_controller.dart';

Future<void> openTreatmentCatalogDialog() async {
  if (!Get.isRegistered<TreatmentCatalogController>()) {
    Get.put(TreatmentCatalogController(), permanent: true);
  }
  final catalog = Get.find<TreatmentCatalogController>();
  await catalog.reload();

  final nameController = TextEditingController();
  final priceController = TextEditingController();

  await Get.dialog(
    Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'خطط العلاج والأسعار',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'الأسعار تُدخل يدوياً هنا — تُستخدم في الفواتير واختيار خطة المريض. '
                'الحالات الطبية لا تُسجَّل في هذه القائمة.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'اسم خطة العلاج / التمثيل',
                        hintStyle: GoogleFonts.poppins(fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'السعر (ل.س)',
                        hintStyle: GoogleFonts.poppins(fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: Get.back,
                  child: Text('إغلاق', style: GoogleFonts.poppins()),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  nameController.dispose();
  priceController.dispose();
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

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item.name);
    _price = TextEditingController(
      text: widget.item.price > 0
          ? widget.item.price.toStringAsFixed(0)
          : '',
    );
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
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _name,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: '0',
                suffixText: 'ل.س',
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
          ),
          IconButton(
            tooltip: 'حفظ',
            icon: const Icon(Icons.check_circle_outline, color: AppColors.mainColor),
            onPressed: () async {
              final price = double.tryParse(_price.text.trim()) ?? 0;
              await widget.onSave(_name.text, price);
            },
          ),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline, color: AppColors.cancelledColor),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
