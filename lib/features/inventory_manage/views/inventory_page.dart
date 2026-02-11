import 'package:dental_managment_system/features/inventory_manage/views/functions/show_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/colors.dart';
import '../controller/inventory_controller.dart';
import 'functions/show_add_dialog.dart';

class InventoryPage extends StatelessWidget {
  InventoryPage({super.key});

  final InventoryController controller = Get.put(
    InventoryController(),
    permanent: false,
    tag: UniqueKey().toString(),
  );

  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController thresholdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  "المخزون",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.poppins(
                        color: AppColors.mainColor,
                      ),

                      hintText: 'ابحث عن اسم المنتج...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.mainColor,
                      ),
                    ),
                    onChanged: (value) {
                      controller.filterInventory(value); // تابع الفلترة
                    },
                  ),
                ),
                const Spacer(),

                FilledButton.icon(
                  onPressed: () => showAddDialog(
                    controller: controller,
                    nameController: nameController,
                    qtyController: qtyController,
                    thresholdController: thresholdController,
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    backgroundColor: AppColors.mainColor,
                  ),
                  icon: const Icon(Icons.add),
                  label: Text('اضافة عنصر', style: GoogleFonts.poppins()),
                ),
              ],
            ),
            const SizedBox(height: 26),

            /// 🔹 Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mainColor.withOpacity(0.1),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "الاسم",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "الكمية",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "الحد الأدنى",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      "الحالة",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "الاجراءات",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.filteredInventory.isEmpty) {
                  return Center(
                    child: Text(
                      'لا يوجد عناصر في المخزون',
                      style: GoogleFonts.poppins(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.filteredInventory.length,
                  itemBuilder: (_, i) {
                    final item = controller.filteredInventory[i];
                    final int qty = item['qty'];
                    final int threshold = item['threshold'];

                    final Color statusColor = qty <= threshold
                        ? AppColors.cancelledColor
                        : AppColors.approvedColor;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        border: Border.all(color: statusColor.withOpacity(.4)),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(.15),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          /// Item name
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: statusColor,
                                  child: const Icon(
                                    Icons.medication,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item['name'].toString(),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// Quantity
                          Expanded(
                            child: Text(
                              qty.toString(),
                              style: GoogleFonts.poppins(),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          /// Threshold
                          Expanded(
                            child: Text(
                              threshold.toString(),
                              style: GoogleFonts.poppins(),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          /// Status
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                qty <= threshold ? 'منخفض' : 'جيد',
                                style: GoogleFonts.poppins(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          /// Actions
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: AppColors.pendingColor,
                                  ),
                                  onPressed: () {
                                    showEditDialog(item, controller);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: AppColors.cancelledColor,
                                  ),
                                  onPressed: () async {
                                    await controller.remove(item['id']);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
