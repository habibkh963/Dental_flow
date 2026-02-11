import 'package:dental_managment_system/features/inventory_manage/views/functions/show_edit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';

void showAddDialog({
  required nameController,
  required qtyController,
  required thresholdController,
  required controller,
}) {
  Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اضافة منتج جديد',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.mainColor,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nameController,
              decoration: dec('اسم المنتج'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: dec('الكمية'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: thresholdController,
              keyboardType: TextInputType.number,
              decoration: dec('الحد الادنى للتنبيه'),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('الغاء', style: GoogleFonts.poppins()),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () async {
                    await controller.add({
                      'id': UniqueKey().toString(),
                      'name': nameController.text,
                      'qty': int.parse(qtyController.text),
                      'threshold': int.parse(thresholdController.text),
                    });

                    nameController.clear();
                    qtyController.clear();
                    thresholdController.clear();

                    Get.back();
                  },
                  child: Text('حفظ', style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
