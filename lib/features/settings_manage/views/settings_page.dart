import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:dental_managment_system/services/database_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/colors.dart';
import '../../inventory_manage/views/FUNCTIONS/show_edit_dialog.dart';

class SettingsPage extends StatelessWidget {
  final SettingsController ctrl = Get.put(
    SettingsController(),
    permanent: false,
    tag: UniqueKey().toString(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            _tile(
              icon: Icons.lock_outline,
              title: 'كلمة مرور للتطبيق',
              subtitle: 'تفعيل / تغيير كلمة المرور',
              onTap: () => _showPasswordDialog(context),
            ),

            _tile(
              icon: Icons.upload_file,
              title: 'تصدير البيانات',
              subtitle: 'حفظ نسخة احتياطية من قاعدة البيانات',
              onTap: () async => await ctrl.exportDatabase(),
            ),

            _tile(
              icon: Icons.download,
              title: 'استيراد البيانات',
              subtitle: 'تحميل ملف خارجي واسترجاع البيانات',
              onTap: () async => await ctrl.importDatabase(),
            ),

            _tile(
              icon: Icons.delete_forever_outlined,
              title: 'مسح جميع البيانات',
              subtitle: 'حذف كل بيانات التطبيق نهائياً',
              color: AppColors.cancelledColor,
              onTap: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppColors.mainColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withOpacity(.3)),
          boxShadow: [
            BoxShadow(
              color: c.withOpacity(.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: c,
              child: Icon(icon, color: Colors.white),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تأكيد الحذف',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'هل أنت متأكد من حذف كل البيانات؟ لا يمكن التراجع عن هذه العملية.',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: Get.back, child: const Text('إلغاء')),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () async {
                      await DatabaseService.instance.deleteAllData();
                      Get.back();
                    },
                    child: const Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showPasswordDialog(BuildContext context) async {
  final TextEditingController currentPassController = TextEditingController();
  final TextEditingController newPassController = TextEditingController();
  final SettingsController controller = Get.find();

  // تحقق إذا فيه كلمة مرور موجودة
  final hasPassword = (controller.password)?.isNotEmpty ?? false;

  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2A9D8F).withOpacity(0.2),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPassword ? 'أدخل كلمة المرور الحالية' : 'تعيين كلمة مرور',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A9D8F),
                  ),
                ),
                const SizedBox(height: 16),
                if (hasPassword)
                  TextField(
                    controller: currentPassController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور الحالية',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (hasPassword) const SizedBox(height: 12),
                TextField(
                  controller: newPassController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: hasPassword
                        ? 'كلمة المرور الجديدة'
                        : 'كلمة المرور الجديدة',
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2A9D8F),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final newPass = newPassController.text.trim();
                          if (newPass.isEmpty) return;

                          if (hasPassword) {
                            final currentPass = currentPassController.text
                                .trim();
                            final storedPass = controller.password;
                            if (currentPass != storedPass) {
                              Get.snackbar(
                                'خطأ',
                                'كلمة المرور الحالية غير صحيحة',
                                backgroundColor: Colors.red.withOpacity(0.8),
                                colorText: Colors.white,
                              );
                              return;
                            }
                          }

                          await controller.setPassword(newPass);
                          Get.back();
                        },
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    barrierColor: Colors.black.withOpacity(0.3),
  );
}

class SettingsController extends GetxController {
  final storage = GetStorage();

  String? get password => storage.read('app_password');
  @override
  void onInit() {
    final storage = GetStorage();

    log('', name: '${storage.read('app_password')}');
    super.onInit();
  }

  Future<void> setPassword(String value) async {
    await storage.write('app_password', value);
  }

  Future<void> exportDatabase() async {
    final path = await DatabaseService.instance.exportDB();
    Get.snackbar('تم التصدير', path ?? 'حدث خطأ');
  }

  Future<void> importDatabase() async {
    final success = await DatabaseService.instance.importDB();
    if (success) {
      Get.snackbar('نجاح', 'تم استيراد البيانات بنجاح');
    }
  }
}
