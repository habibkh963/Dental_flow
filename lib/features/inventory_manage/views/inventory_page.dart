import 'package:dental_managment_system/features/inventory_manage/views/functions/show_edit_dialog.dart';
import 'package:flutter/material.dart';

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
                  "Inventory",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
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
                    backgroundColor: const Color(0xFF2A9D8F),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('New Inventory'),
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
                    color: const Color(0xFF2A9D8F).withOpacity(0.1),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Expanded(child: Text("name")),
                  Expanded(child: Text("QTY")),
                  Expanded(child: Text("MIN")),

                  Expanded(child: Text("Status")),
                  Expanded(child: Text("Actions")),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.items.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا يوجد عناصر في المخزون',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.items.length,
                  itemBuilder: (_, i) {
                    final item = controller.items[i];
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// Quantity
                          Expanded(child: Text(qty.toString())),

                          /// Threshold
                          Expanded(child: Text(threshold.toString())),

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
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          /// Actions
                          Expanded(
                            child: Row(
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
