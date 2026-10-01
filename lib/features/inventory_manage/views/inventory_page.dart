import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../controller/inventory_controller.dart';
import 'widgets/inventory_item_tile.dart';
import 'widgets/inventory_list_header.dart';

class InventoryPage extends GetView<InventoryController> {
  InventoryPage({super.key}) : _tag = UniqueKey().toString() {
    Get.put(InventoryController(), permanent: false, tag: _tag);
  }

  final String _tag;

  @override
  String? get tag => _tag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 26),
            const InventoryListHeader(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'المخزون',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintStyle: GoogleFonts.poppins(color: AppColors.mainColor),
              hintText: 'ابحث عن اسم المنتج...',
              prefixIcon: const Icon(Icons.search, color: AppColors.mainColor),
            ),
            onChanged: controller.filterInventory,
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: controller.openAddDialog,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            backgroundColor: AppColors.mainColor,
          ),
          icon: const Icon(Icons.add),
          label: Text('اضافة عنصر', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }

  Widget _buildList() {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredItems.isEmpty) {
        final hasSearch = controller.searchQuery.value.trim().isNotEmpty;
        return Center(
          child: Text(
            hasSearch ? 'لا توجد نتائج للبحث' : 'لا يوجد عناصر في المخزون',
            style: GoogleFonts.poppins(fontSize: 18),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.filteredItems.length,
        itemBuilder: (_, index) {
          final item = controller.filteredItems[index];
          return InventoryItemTile(
            item: item,
            onEdit: () => controller.openEditDialog(item),
            onDelete: () => controller.confirmDelete(item),
          );
        },
      );
    });
  }
}
