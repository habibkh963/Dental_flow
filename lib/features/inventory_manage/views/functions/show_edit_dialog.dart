import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

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
              'Edit ${item['name']}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2A9D8F),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: editQtyController,
              keyboardType: TextInputType.number,
              decoration: dec('New quantity'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: editThresholdController,
              keyboardType: TextInputType.number,
              decoration: dec('New minimum alert'),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2A9D8F),
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
                  child: const Text('Save changes'),
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
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF2A9D8F), width: 1.5),
    ),
  );
}
