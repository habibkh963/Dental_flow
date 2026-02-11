import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/colors.dart';

void showEditDialog(Map<String, dynamic> item, controller) {
  final TextEditingController editQtyController = TextEditingController(
    text: item['qty'].toString(),
  );

  final TextEditingController editThresholdController = TextEditingController(
    text: item['threshold'].toString(),
  );

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
              'تعديل ${item['name']}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.mainColor,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: editQtyController,
              keyboardType: TextInputType.number,
              decoration: dec('كمية جديدة'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: editThresholdController,
              keyboardType: TextInputType.number,
              decoration: dec('تحذير النفاذ الجديد'),
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
                    await controller.updateItem(item['id'], {
                      'qty': int.parse(editQtyController.text),
                      'threshold': int.parse(editThresholdController.text),
                    });

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

InputDecoration dec(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(),
    filled: true,
    fillColor: Colors.grey.withOpacity(0.05),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.mainColor, width: 1.5),
    ),
  );
}
